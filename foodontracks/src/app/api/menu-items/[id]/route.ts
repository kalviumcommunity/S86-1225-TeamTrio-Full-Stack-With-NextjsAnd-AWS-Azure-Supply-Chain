import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { updateMenuItemSchema } from "@/lib/schemas/menuItemSchema";
import { validateData } from "@/lib/validationUtils";

// GET /api/menu-items/[id]
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const menuItemId = parseInt(id);

    if (isNaN(menuItemId)) {
      return NextResponse.json(
        { error: "Invalid menu item ID" },
        { status: 400 }
      );
    }

    const menuItem = await prisma.menuItem.findUnique({
      where: { id: menuItemId },
      include: {
        restaurant: true,
      },
    });

    if (!menuItem) {
      return NextResponse.json(
        { error: "Menu item not found" },
        { status: 404 }
      );
    }

    return NextResponse.json({ data: menuItem });
  } catch (error) {
    console.error("Error fetching menu item:", error);
    return NextResponse.json(
      { error: "Failed to fetch menu item" },
      { status: 500 }
    );
  }
}

// PUT /api/menu-items/[id]
export async function PUT(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const menuItemId = parseInt(id);

    if (isNaN(menuItemId)) {
      return NextResponse.json(
        { error: "Invalid menu item ID" },
        { status: 400 }
      );
    }

    const body = await req.json();

    // Validate input using Zod schema
    const validationResult = validateData(updateMenuItemSchema, body);
    if (!validationResult.success) {
      return NextResponse.json(validationResult, { status: 400 });
    }

    // Check if menu item exists
    const existingMenuItem = await prisma.menuItem.findUnique({
      where: { id: menuItemId },
    });

    if (!existingMenuItem) {
      return NextResponse.json(
        { error: "Menu item not found" },
        { status: 404 }
      );
    }

    // Update menu item
    const menuItem = await prisma.menuItem.update({
      where: { id: menuItemId },
      data: validationResult.data,
    });

    return NextResponse.json({
      message: "Menu item updated successfully",
      data: menuItem,
    });
  } catch (error) {
    console.error("Error updating menu item:", error);
    return NextResponse.json(
      { error: "Failed to update menu item" },
      { status: 500 }
    );
  }
}

// DELETE /api/menu-items/[id]
export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const menuItemId = parseInt(id);

    if (isNaN(menuItemId)) {
      return NextResponse.json(
        { error: "Invalid menu item ID" },
        { status: 400 }
      );
    }

    // Check if menu item exists
    const existingMenuItem = await prisma.menuItem.findUnique({
      where: { id: menuItemId },
    });

    if (!existingMenuItem) {
      return NextResponse.json(
        { error: "Menu item not found" },
        { status: 404 }
      );
    }

    // Delete menu item
    await prisma.menuItem.delete({
      where: { id: menuItemId },
    });

    return NextResponse.json({
      message: "Menu item deleted successfully",
    });
  } catch (error) {
    console.error("Error deleting menu item:", error);
    return NextResponse.json(
      { error: "Failed to delete menu item" },
      { status: 500 }
    );
  }
}
