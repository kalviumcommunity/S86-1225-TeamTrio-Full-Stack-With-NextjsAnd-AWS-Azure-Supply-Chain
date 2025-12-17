import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// GET /api/reviews - Get all reviews with pagination
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const page = Number(searchParams.get("page")) || 1;
    const limit = Number(searchParams.get("limit")) || 10;
    const restaurantId = searchParams.get("restaurantId");
    const userId = searchParams.get("userId");
    const minRating = searchParams.get("minRating");

    const skip = (page - 1) * limit;

    const where: {
      restaurantId?: number;
      userId?: number;
      rating?: { gte: number };
    } = {};
    if (restaurantId) where.restaurantId = parseInt(restaurantId);
    if (userId) where.userId = parseInt(userId);
    if (minRating) where.rating = { gte: parseInt(minRating) };

    const [reviews, total] = await Promise.all([
      prisma.review.findMany({
        where,
        skip,
        take: limit,
        include: {
          user: {
            select: {
              id: true,
              name: true,
            },
          },
          restaurant: {
            select: {
              id: true,
              name: true,
            },
          },
          order: {
            select: {
              id: true,
              orderNumber: true,
            },
          },
        },
        orderBy: { createdAt: "desc" },
      }),
      prisma.review.count({ where }),
    ]);

    return NextResponse.json({
      data: reviews,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (error) {
    console.error("Error fetching reviews:", error);
    return NextResponse.json(
      { error: "Failed to fetch reviews" },
      { status: 500 }
    );
  }
}

// POST /api/reviews - Create a review
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { userId, restaurantId, orderId, rating, comment } = body;

    if (!userId || !restaurantId || !orderId || !rating) {
      return NextResponse.json(
        { error: "Required fields: userId, restaurantId, orderId, rating" },
        { status: 400 }
      );
    }

    if (rating < 1 || rating > 5) {
      return NextResponse.json(
        { error: "Rating must be between 1 and 5" },
        { status: 400 }
      );
    }

    // Check if order exists and is delivered
    const order = await prisma.order.findUnique({
      where: { id: parseInt(orderId) },
    });

    if (!order) {
      return NextResponse.json({ error: "Order not found" }, { status: 404 });
    }

    if (order.status !== "DELIVERED") {
      return NextResponse.json(
        { error: "Can only review delivered orders" },
        { status: 400 }
      );
    }

    // Check if review already exists
    const existingReview = await prisma.review.findUnique({
      where: { orderId: parseInt(orderId) },
    });

    if (existingReview) {
      return NextResponse.json(
        { error: "Review already exists for this order" },
        { status: 409 }
      );
    }

    // Create review and update restaurant rating
    const review = await prisma.$transaction(async (tx) => {
      const newReview = await tx.review.create({
        data: {
          userId: parseInt(userId),
          restaurantId: parseInt(restaurantId),
          orderId: parseInt(orderId),
          rating: parseInt(rating),
          comment,
        },
      });

      // Update restaurant average rating
      const avgRating = await tx.review.aggregate({
        where: { restaurantId: parseInt(restaurantId) },
        _avg: { rating: true },
      });

      await tx.restaurant.update({
        where: { id: parseInt(restaurantId) },
        data: { rating: avgRating._avg.rating || 0 },
      });

      return newReview;
    });

    return NextResponse.json(
      { message: "Review created successfully", data: review },
      { status: 201 }
    );
  } catch (error) {
    console.error("Error creating review:", error);
    return NextResponse.json(
      { error: "Failed to create review" },
      { status: 500 }
    );
  }
}
