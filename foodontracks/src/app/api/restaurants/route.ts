import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// GET /api/restaurants - Get all restaurants with pagination
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const page = Number(searchParams.get("page")) || 1;
    const limit = Number(searchParams.get("limit")) || 10;
    const city = searchParams.get("city");
    const isActive = searchParams.get("isActive");
    const minRating = searchParams.get("minRating");

    const skip = (page - 1) * limit;

    const where: {
      city?: { contains: string; mode: "insensitive" };
      isActive?: boolean;
      rating?: { gte: number };
    } = {};
    if (city) where.city = { contains: city, mode: "insensitive" };
    if (isActive) where.isActive = isActive === "true";
    if (minRating) where.rating = { gte: parseFloat(minRating) };

    const [restaurants, total] = await Promise.all([
      prisma.restaurant.findMany({
        where,
        skip,
        take: limit,
        select: {
          id: true,
          name: true,
          email: true,
          phoneNumber: true,
          description: true,
          address: true,
          city: true,
          state: true,
          zipCode: true,
          rating: true,
          isActive: true,
          createdAt: true,
          _count: {
            select: {
              menuItems: true,
              orders: true,
              reviews: true,
            },
          },
        },
        orderBy: { rating: "desc" },
      }),
      prisma.restaurant.count({ where }),
    ]);

    return NextResponse.json({
      data: restaurants,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error("Error fetching restaurants:", error);
    return NextResponse.json(
      { error: "Failed to fetch restaurants" },
      { status: 500 }
    );
  }
}

// POST /api/restaurants - Create a new restaurant
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      name,
      email,
      phoneNumber,
      description,
      address,
      city,
      state,
      zipCode,
    } = body;

    // Validation
    if (
      !name ||
      !email ||
      !phoneNumber ||
      !address ||
      !city ||
      !state ||
      !zipCode
    ) {
      return NextResponse.json(
        { error: "All required fields must be provided" },
        { status: 400 }
      );
    }

    // Check if restaurant already exists
    const existingRestaurant = await prisma.restaurant.findFirst({
      where: {
        OR: [{ email }, { phoneNumber }],
      },
    });

    if (existingRestaurant) {
      return NextResponse.json(
        { error: "Restaurant with this email or phone number already exists" },
        { status: 409 }
      );
    }

    // Create restaurant
    const restaurant = await prisma.restaurant.create({
      data: {
        name,
        email,
        phoneNumber,
        description,
        address,
        city,
        state,
        zipCode,
      },
    });

    return NextResponse.json(
      { message: "Restaurant created successfully", data: restaurant },
      { status: 201 }
    );
  } catch (error) {
    console.error("Error creating restaurant:", error);
    return NextResponse.json(
      { error: "Failed to create restaurant" },
      { status: 500 }
    );
  }
}
