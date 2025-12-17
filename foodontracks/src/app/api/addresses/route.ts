import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// GET /api/addresses
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const userId = searchParams.get("userId");

    if (!userId) {
      return NextResponse.json(
        { error: "userId query parameter is required" },
        { status: 400 }
      );
    }

    const addresses = await prisma.address.findMany({
      where: { userId: parseInt(userId) },
      orderBy: { isDefault: "desc" },
    });

    return NextResponse.json({ data: addresses });
  } catch (error) {
    console.error("Error fetching addresses:", error);
    return NextResponse.json(
      { error: "Failed to fetch addresses" },
      { status: 500 }
    );
  }
}

// POST /api/addresses
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      userId,
      addressLine1,
      addressLine2,
      city,
      state,
      zipCode,
      country,
      isDefault,
    } = body;

    if (!userId || !addressLine1 || !city || !state || !zipCode) {
      return NextResponse.json(
        {
          error: "Required fields: userId, addressLine1, city, state, zipCode",
        },
        { status: 400 }
      );
    }

    // If setting as default, unset other defaults
    if (isDefault) {
      await prisma.address.updateMany({
        where: { userId: parseInt(userId), isDefault: true },
        data: { isDefault: false },
      });
    }

    const address = await prisma.address.create({
      data: {
        userId: parseInt(userId),
        addressLine1,
        addressLine2,
        city,
        state,
        zipCode,
        country: country || "USA",
        isDefault: isDefault || false,
      },
    });

    return NextResponse.json(
      { message: "Address created successfully", data: address },
      { status: 201 }
    );
  } catch (error) {
    console.error("Error creating address:", error);
    return NextResponse.json(
      { error: "Failed to create address" },
      { status: 500 }
    );
  }
}
