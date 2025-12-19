import { NextResponse, NextRequest } from 'next/server';
import { prisma } from '@/lib/prisma';
import { handleError, AppError, ErrorType } from '@/lib/errorHandler';
import { logger } from '@/lib/logger';
import { createUserSchema } from '@/lib/schemas/userSchema';

export async function GET(req: NextRequest) {
  try {
    const users = await prisma.user.findMany({
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    logger.info('Users retrieved', { count: users.length });

    return NextResponse.json({
      success: true,
      data: users,
      count: users.length,
    });
  } catch (error) {
    return handleError(error, 'GET /api/users');
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    // Validate input with Zod
    const validatedData = createUserSchema.parse(body);

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email: validatedData.email },
    });

    if (existingUser) {
      throw new AppError(
        ErrorType.CONFLICT_ERROR,
        409,
        'Email already registered',
        { email: validatedData.email }
      );
    }

    // Create user
    const user = await prisma.user.create({
      data: validatedData,
      select: {
        id: true,
        name: true,
        email: true,
        role: true,
        createdAt: true,
      },
    });

    logger.info('User created successfully', {
      userId: user.id,
      email: user.email,
      role: user.role,
    });

    return NextResponse.json(
      { success: true, data: user },
      { status: 201 }
    );
  } catch (error) {
    return handleError(error, 'POST /api/users');
  }
}