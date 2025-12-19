/**
 * Centralized Error Handler
 * Provides unified error handling, classification, logging, and response formatting
 * Integrates with logger for structured error tracking
 */

import { NextRequest, NextResponse } from 'next/server';
import { ZodError } from 'zod';
import { logger } from './logger';

/**
 * Error types for classification and handling
 */
export enum ErrorType {
  VALIDATION_ERROR = 'VALIDATION_ERROR',
  AUTHENTICATION_ERROR = 'AUTHENTICATION_ERROR',
  AUTHORIZATION_ERROR = 'AUTHORIZATION_ERROR',
  NOT_FOUND_ERROR = 'NOT_FOUND_ERROR',
  CONFLICT_ERROR = 'CONFLICT_ERROR',
  DATABASE_ERROR = 'DATABASE_ERROR',
  EXTERNAL_API_ERROR = 'EXTERNAL_API_ERROR',
  INTERNAL_SERVER_ERROR = 'INTERNAL_SERVER_ERROR',
}

/**
 * Custom error class for typed error handling
 */
export class AppError extends Error {
  constructor(
    public type: ErrorType,
    public statusCode: number,
    message: string,
    public context?: Record<string, any>
  ) {
    super(message);
    this.name = 'AppError';
  }
}

/**
 * Error status code mappings
 */
const ERROR_STATUS_CODES: Record<ErrorType, number> = {
  [ErrorType.VALIDATION_ERROR]: 400,
  [ErrorType.AUTHENTICATION_ERROR]: 401,
  [ErrorType.AUTHORIZATION_ERROR]: 403,
  [ErrorType.NOT_FOUND_ERROR]: 404,
  [ErrorType.CONFLICT_ERROR]: 409,
  [ErrorType.DATABASE_ERROR]: 500,
  [ErrorType.EXTERNAL_API_ERROR]: 502,
  [ErrorType.INTERNAL_SERVER_ERROR]: 500,
};

/**
 * User-safe error messages for production
 */
const USER_SAFE_MESSAGES: Record<ErrorType, string> = {
  [ErrorType.VALIDATION_ERROR]: 'Invalid input provided. Please check your data and try again.',
  [ErrorType.AUTHENTICATION_ERROR]: 'Authentication failed. Please log in and try again.',
  [ErrorType.AUTHORIZATION_ERROR]: 'You do not have permission to perform this action.',
  [ErrorType.NOT_FOUND_ERROR]: 'The requested resource was not found.',
  [ErrorType.CONFLICT_ERROR]: 'This action conflicts with existing data. Please verify and try again.',
  [ErrorType.DATABASE_ERROR]: 'A database error occurred. Please try again later.',
  [ErrorType.EXTERNAL_API_ERROR]: 'An external service error occurred. Please try again later.',
  [ErrorType.INTERNAL_SERVER_ERROR]: 'An unexpected error occurred. Our team has been notified.',
};

/**
 * Classify error type automatically
 */
function classifyError(error: any): ErrorType {
  // Zod validation errors
  if (error instanceof ZodError) {
    return ErrorType.VALIDATION_ERROR;
  }

  // Custom app errors
  if (error instanceof AppError) {
    return error.type;
  }

  // Prisma errors
  if (error?.name === 'PrismaClientKnownRequestError') {
    if (error.code === 'P2025') {
      return ErrorType.NOT_FOUND_ERROR;
    }
    if (error.code === 'P2002') {
      return ErrorType.CONFLICT_ERROR;
    }
    return ErrorType.DATABASE_ERROR;
  }

  // JWT errors
  if (
    error?.name === 'JsonWebTokenError' ||
    error?.name === 'TokenExpiredError'
  ) {
    return ErrorType.AUTHENTICATION_ERROR;
  }

  // Default to internal server error
  return ErrorType.INTERNAL_SERVER_ERROR;
}

/**
 * Extract validation errors from Zod error
 */
function extractZodErrors(error: ZodError): Array<{ field: string; message: string }> {
  return error.errors.map((err) => ({
    field: err.path.join('.'),
    message: err.message,
  }));
}

/**
 * Centralized error handler
 * Classifies, logs, and formats error responses
 */
export function handleError(
  error: any,
  context: string = 'Unknown',
  requestId?: string
): NextResponse {
  const isDevelopment = process.env.NODE_ENV === 'development';
  const errorType = classifyError(error);
  const statusCode = ERROR_STATUS_CODES[errorType];
  const userMessage = USER_SAFE_MESSAGES[errorType];

  // Log error
  logger.error(`${errorType} in ${context}`, {
    type: errorType,
    context,
    requestId,
    originalMessage: error?.message,
    ...(error?.context && { appContext: error.context }),
  }, isDevelopment ? error?.stack : undefined);

  // Build response
  const response: any = {
    success: false,
    message: isDevelopment ? error?.message || userMessage : userMessage,
    type: errorType,
    ...(isDevelopment && { context }),
  };

  // Add validation errors details
  if (errorType === ErrorType.VALIDATION_ERROR) {
    if (error instanceof ZodError) {
      response.errors = extractZodErrors(error);
    } else if (error?.errors) {
      response.errors = error.errors;
    }
  }

  // Add stack trace in development only
  if (isDevelopment && error?.stack) {
    response.stack = error.stack;
  }

  // Sanitize for production
  if (!isDevelopment && response.stack) {
    response.stack = '[REDACTED_IN_PRODUCTION]';
  }

  return NextResponse.json(response, { status: statusCode });
}

/**
 * Async handler wrapper for automatic error catching
 * Optional: Use if you want automatic try/catch in route handlers
 */
export function asyncHandler(
  handler: (req: NextRequest) => Promise<NextResponse>
) {
  return async (req: NextRequest) => {
    try {
      return await handler(req);
    } catch (error) {
      return handleError(error, `${req.method} ${req.nextUrl.pathname}`);
    }
  };
}
