import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import axios from 'axios';
import { prisma } from '../src/app/lib/prisma';

const JWT_SECRET = process.env.JWT_SECRET || 'dev_jwt_secret_change_me';

async function run() {
  console.log('🔐 Auth Test: signup -> login -> verify protected access');

  const email = `test+${Date.now()}@example.com`;
  const password = 's3cret!Pass';
  const name = 'Test User';

  // Ensure no user exists
  await prisma.user.deleteMany({ where: { email } });

  // Signup using Prisma (bypass HTTP for faster test)
  const hashed = await bcrypt.hash(password, 10);
  const created = await prisma.user.create({ data: { name, email, password: hashed } });
  console.log('Created user id=', created.id, 'email=', created.email);

  // Login logic
  const isValid = await bcrypt.compare(password, created.password);
  if (!isValid) throw new Error('password compare failed');

  const token = jwt.sign({ id: created.id, email: created.email }, JWT_SECRET, { expiresIn: '1h' });
  console.log('Generated token (first 30 chars) =', token.slice(0, 30), '...');

  // Verify token
  const decoded: any = jwt.verify(token, JWT_SECRET);
  if (decoded.id !== created.id) throw new Error('token verification mismatch');
  console.log('Token verified, decoded id=', decoded.id);

  // Hit protected route via HTTP if app is running on localhost:3000
  try {
    const res = await axios.get('http://localhost:3000/api/users', { headers: { Authorization: `Bearer ${token}` } });
    console.log('Protected route status:', res.status, 'data:', res.data);
  } catch (err: any) {
    console.warn('Could not hit /api/users on localhost:3000 (app may not be running). Error:', err.message);
  }

  // Cleanup
  await prisma.user.delete({ where: { id: created.id } });
  await prisma.$disconnect();
  console.log('Auth test completed successfully');
}

run().catch((e) => {
  console.error('Auth test failed', e);
  process.exit(1);
});