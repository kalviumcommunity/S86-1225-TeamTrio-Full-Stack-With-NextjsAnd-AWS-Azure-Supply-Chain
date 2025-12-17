import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// GET /api/menu-items - Get all menu items with pagination
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const page = Number(searchParams.get("page")) || 1;
    const limit = Number(searchParams.get("limit")) || 10;
    const restaurantId = searchParams.get("restaurantId");
    const category = searchParams.get("category");
    const isAvailable = searchParams.get("isAvailable");
    const maxPrice = searchParams.get("maxPrice");

    const skip = (page - 1) * limit;

    const where: {
      restaurantId?: number;
      category?: { contains: string; mode: "insensitive" };
      isAvailable?: boolean;
      price?: { lte: number };
    } = {};
    if (restaurantId) where.restaurantId = parseInt(restaurantId);
    if (category) where.category = { contains: category, mode: "insensitive" };
    if (isAvailable) where.isAvailable = isAvailable === "true";
    if (maxPrice) where.price = { lte: parseFloat(maxPrice) };

    const [menuItems, total] = await Promise.all([
      prisma.menuItem.findMany({
        where,
        skip,
        take: limit,
        include: {
          restaurant: {
            select: {
              id: true,
              name: true,
              city: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
      }),
      prisma.menuItem.count({ where }),
    ]);

    return NextResponse.json({
      data: menuItems,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error("Error fetching menu items:", error);
    return NextResponse.json(
      { error: "Failed to fetch menu items" },
      { status: 500 }
    );
  }
}

// POST /api/menu-items - Create a new menu item
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      restaurantId,
      name,
      description,
      price,
      category,
      imageUrl,
      preparationTime,
    } = body;

    // Validation
    if (!restaurantId || !name || !price || !category || !preparationTime) {
      return NextResponse.json(
        {
          error:
            "Required fields: restaurantId, name, price, category, preparationTime",
        },
        { status: 400 }
      );
    }

    // Verify restaurant exists
    const restaurant = await prisma.restaurant.findUnique({
      where: { id: parseInt(restaurantId) },
    });

    if (!restaurant) {
      return NextResponse.json(
        { error: "Restaurant not found" },
        { status: 404 }
      );
    }

    // Create menu item
    const menuItem = await prisma.menuItem.create({
      data: {
        restaurantId: parseInt(restaurantId),
        name,
        description,
        price: parseFloat(price),
        category,
        imageUrl,
        preparationTime: parseInt(preparationTime),
      },
    });

    return NextResponse.json(
      { message: "Menu item created successfully", data: menuItem },
      { status: 201 }
    );
  } catch (error) {
    console.error("Error creating menu item:", error);
    return NextResponse.json(
      { error: "Failed to create menu item" },
      { status: 500 }
    );
  }
}
