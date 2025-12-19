/**
 * Centralized Error Handler
 * Manages error classification, logging, and response formatting
 * 
 * Usage:
 *   try { ... } catch (error) {
 *     return handleError(error, 'POST /api/users');
 *   }
 */

import { NextResponse } from 'next/server';
import { logger } from './logger';

/**
 * Error types for classification
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
 * Structured error class for typed errors
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
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

/**
 * Default error status codes by type
 */
const errorStatusCodes: Record<ErrorType, number> = {
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
 * User-safe error messages by type (for production)
 */
const userSafeMessages: Record<ErrorType, string> = {
  [ErrorType.VALIDATION_ERROR]: 'Invalid request. Please check your input and try again.',
  [ErrorType.AUTHENTICATION_ERROR]: 'Authentication required. Please log in.',
  [ErrorType.AUTHORIZATION_ERROR]: 'You do not have permission to access this resource.',
  [ErrorType.NOT_FOUND_ERROR]: 'The requested resource was not found.',
  [ErrorType.CONFLICT_ERROR]: 'This resource already exists or conflicts with another resource.',
  [ErrorType.DATABASE_ERROR]: 'A database error occurred. Please try again later.',
  [ErrorType.EXTERNAL_API_ERROR]: 'An external service error occurred. Please try again later.',
  [ErrorType.INTERNAL_SERVER_ERROR]: 'An unexpected error occurred. Please try again later.',
};

/**
 * Interface for error response
 */
interface ErrorResponse {
  success: false;
  message: string;
  code?: string;
  details?: Record<string, any>;
  stack?: string;
  timestamp: string;
}

/**
 * Classify error and determine error type
 */
function classifyError(error: any): ErrorType {
  if (error instanceof AppError) {
    return error.type;
  }

  if (error.name === 'PrismaClientKnownRequestError') {
    return ErrorType.DATABASE_ERROR;
  }

  if (error.name === 'ZodError') {
    return ErrorType.VALIDATION_ERROR;
  }

  if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
    return ErrorType.AUTHENTICATION_ERROR;
  }

  return ErrorType.INTERNAL_SERVER_ERROR;
}

/**
 * Central error handler - processes all errors uniformly
 * 
 * @param error - The error object
 * @param context - Context string (e.g., 'POST /api/users')
 * @param requestId - Optional request ID for tracking
 * @returns NextResponse with error details
 */
export function handleError(
  error: any,
  context: string,
  requestId?: string
): NextResponse {
  const isProd = process.env.NODE_ENV === 'production';
  const isDev = process.env.NODE_ENV === 'development';
  const errorType = classifyError(error);
  const statusCode = error.statusCode || errorStatusCodes[errorType];
  const userMessage = isProd
    ? userSafeMessages[errorType]
    : error.message || 'An unexpected error occurred';

  // Build detailed logging data
  const logData = {
    errorType,
    message: error.message,
    stack: isProd ? '[REDACTED_IN_PRODUCTION]' : error.stack,
    context,
    requestId,
    ...(error.context && { context: error.context }),
    timestamp: new Date().toISOString(),
  };

  // Log the error
  if (errorType === ErrorType.INTERNAL_SERVER_ERROR || isProd) {
    logger.error(`Error in ${context}`, logData);
  } else {
    logger.warn(`${errorType} in ${context}`, logData);
  }

  // Build response object
  const response: ErrorResponse = {
    success: false,
    message: userMessage,
    code: errorType,
    timestamp: new Date().toISOString(),
    ...(isDev && { stack: error.stack }),
    ...(isDev && error.context && { details: error.context }),
  };

  return NextResponse.json(response, { status: statusCode });
}

/**
 * Error wrapper for async route handlers
 * Automatically catches and handles errors
 * 
 * Usage:
 *   export const GET = asyncHandler(async (req) => {
 *     const user = await prisma.user.findUnique(...);
 *     return NextResponse.json(user);
 *   });
 */
export function asyncHandler(
  handler: (req: Request, context?: any) => Promise<NextResponse>
) {
  return async (req: Request, context?: any) => {
    try {
      return await handler(req, context);
    } catch (error) {
      const url = new URL(req.url);
      const context_str = `${req.method} ${url.pathname}`;
      return handleError(error, context_str);
    }
  };
}
