import { prisma } from '../src/app/lib/prisma';

async function run() {
  console.log('🔁 Demo: transactions (success + forced failure)');

  // Pick a menu item and a user + address from the DB
  const menuItem = await prisma.menuItem.findFirst();
  const user = await prisma.user.findFirst();
  const address = await prisma.address.findFirst({ where: { userId: user?.id } });

  if (!menuItem) {
    console.error('No MenuItem found to test transactions. Run the seed first.');
    process.exit(1);
  }
  if (!user || !address) {
    console.error('No user/address found to test transactions. Run the seed first.');
    process.exit(1);
  }

  console.log('MenuItem selected:', { id: menuItem.id, name: menuItem.name, stock: menuItem.stock });
  console.log('Using user/address:', { userId: user.id, addressId: address.id });

  // Successful transaction: buy 1
  try {
    const result = await prisma.$transaction(async (tx) => {
      const order = await tx.order.create({
        data: {
          userId: user.id,
          restaurantId: menuItem.restaurantId,
          addressId: address.id,
          orderNumber: `ORD-${Math.random().toString(36).slice(2, 9).toUpperCase()}`,
          status: 'PENDING',
          totalAmount: menuItem.price,
        },
      });

      await tx.menuItem.update({ where: { id: menuItem.id }, data: { stock: { decrement: 1 } } });

      await tx.orderItem.create({
        data: { orderId: order.id, menuItemId: menuItem.id, quantity: 1, priceAtTime: menuItem.price },
      });

      await tx.payment.create({
        data: {
          orderId: order.id,
          amount: order.totalAmount,
          paymentMethod: 'CREDIT_CARD',
          transactionId: 'TXN-' + Math.random().toString(36).substring(7).toUpperCase(),
          status: 'COMPLETED',
        },
      });

      await tx.order.update({ where: { id: order.id }, data: { status: 'CONFIRMED' } });

      return { orderId: order.id };
    });

    const after = await prisma.menuItem.findUnique({ where: { id: menuItem.id } });
    console.log('Success transaction result:', result, 'stock after:', after?.stock);
  } catch (err: any) {
    console.error('Unexpected error during successful transaction demo:', err.message || err);
  }

  // Forced failure transaction: throw inside transaction and ensure rollback
  // We'll attempt to decrement more than available to force an error
  try {
    await prisma.$transaction(async (tx) => {
      // purposely set quantity larger than available
      const toBuy = (menuItem.stock ?? 0) + 9999;

      const order = await tx.order.create({
        data: {
          userId: user.id,
          restaurantId: menuItem.restaurantId,
          addressId: address.id,
          orderNumber: `ORD-${Math.random().toString(36).slice(2, 9).toUpperCase()}`,
          status: 'PENDING',
          totalAmount: (menuItem.price ?? 0) * toBuy,
        },
      });

      const cur = await tx.menuItem.findUnique({ where: { id: menuItem.id } });
      if (!cur) throw new Error('Menu item disappeared');
      if ((cur.stock ?? 0) < toBuy) throw new Error('Insufficient stock (expected failure)');

      // These lines should not run because of the throw above
      await tx.menuItem.update({ where: { id: menuItem.id }, data: { stock: { decrement: toBuy } } });
    });
  } catch (err: any) {
    console.log('Expected forced failure caught:', err.message || err);
  }

  const final = await prisma.menuItem.findUnique({ where: { id: menuItem.id } });
  console.log('Final menu item stock (should match after-success state):', final?.stock);

  await prisma.$disconnect();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});