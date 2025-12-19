# Error Handling Integration Guide

## Overview

This guide shows how to integrate the centralized error handling middleware into existing API routes. All routes should follow this pattern for consistency.

---

## Implementation Pattern

### Basic Pattern for All Routes

```typescript
import { NextRequest, NextResponse } from 'next/server';
import { handleError, AppError, ErrorType } from '@/lib/errorHandler';
import { logger } from '@/lib/logger';
import { prisma } from '@/lib/prisma';
import { createXxxSchema } from '@/lib/schemas/xxxSchema';

export async function GET(req: NextRequest) {
  try {
    // 1. Query/validate input
    const data = await prisma.xxx.findMany();
    
    // 2. Log success
    logger.info('XXX retrieved', { count: data.length });
    
    // 3. Return success response
    return NextResponse.json({
      success: true,
      data,
      count: data.length,
    });
  } catch (error) {
    // 4. Handle all errors uniformly
    return handleError(error, 'GET /api/xxx');
  }
}

export async function POST(req: NextRequest) {
  try {
    // 1. Parse request
    const body = await req.json();
    
    // 2. Validate with Zod (automatically caught as VALIDATION_ERROR)
    const validated = createXxxSchema.parse(body);
    
    // 3. Check business rules
    const existing = await prisma.xxx.findUnique({
      where: { uniqueField: validated.uniqueField },
    });
    
    if (existing) {
      throw new AppError(
        ErrorType.CONFLICT_ERROR,
        409,
        'Record already exists',
        { field: 'uniqueField' }
      );
    }
    
    // 4. Create resource
    const result = await prisma.xxx.create({ data: validated });
    
    // 5. Log success
    logger.info('XXX created', { id: result.id });
    
    // 6. Return success
    return NextResponse.json(
      { success: true, data: result },
      { status: 201 }
    );
  } catch (error) {
    return handleError(error, 'POST /api/xxx');
  }
}
```

---

## Route-Specific Patterns

### GET Single Resource by ID

```typescript
export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const numId = parseInt(id);
    
    // Validate ID format
    if (isNaN(numId)) {
      throw new AppError(
        ErrorType.VALIDATION_ERROR,
        400,
        'Invalid ID format',
        { providedId: id }
      );
    }
    
    // Query
    const item = await prisma.xxx.findUnique({
      where: { id: numId },
    });
    
    // Check existence
    if (!item) {
      throw new AppError(
        ErrorType.NOT_FOUND_ERROR,
        404,
        'Resource not found',
        { id: numId }
      );
    }
    
    logger.info('Resource retrieved', { id: numId });
    
    return NextResponse.json({ success: true, data: item });
  } catch (error) {
    return handleError(error, 'GET /api/xxx/[id]');
  }
}
```

### PUT Update Resource

```typescript
export async function PUT(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const numId = parseInt(id);
    
    if (isNaN(numId)) {
      throw new AppError(
        ErrorType.VALIDATION_ERROR,
        400,
        'Invalid ID format',
        { providedId: id }
      );
    }
    
    const body = await req.json();
    const validated = updateXxxSchema.parse(body);
    
    // Check existence first
    const existing = await prisma.xxx.findUnique({
      where: { id: numId },
    });
    
    if (!existing) {
      throw new AppError(
        ErrorType.NOT_FOUND_ERROR,
        404,
        'Resource not found',
        { id: numId }
      );
    }
    
    // Update
    const updated = await prisma.xxx.update({
      where: { id: numId },
      data: validated,
    });
    
    logger.info('Resource updated', {
      id: numId,
      updatedFields: Object.keys(validated),
    });
    
    return NextResponse.json({
      success: true,
      data: updated,
    });
  } catch (error) {
    return handleError(error, `PUT /api/xxx/[id]`);
  }
}
```

### DELETE Resource

```typescript
export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const numId = parseInt(id);
    
    if (isNaN(numId)) {
      throw new AppError(
        ErrorType.VALIDATION_ERROR,
        400,
        'Invalid ID format',
        { providedId: id }
      );
    }
    
    // Verify exists
    const existing = await prisma.xxx.findUnique({
      where: { id: numId },
    });
    
    if (!existing) {
      throw new AppError(
        ErrorType.NOT_FOUND_ERROR,
        404,
        'Resource not found',
        { id: numId }
      );
    }
    
    // Delete
    await prisma.xxx.delete({
      where: { id: numId },
    });
    
    logger.info('Resource deleted', { id: numId });
    
    return NextResponse.json({
      success: true,
      message: 'Resource deleted successfully',
    });
  } catch (error) {
    return handleError(error, `DELETE /api/xxx/[id]`);
  }
}
```

---

## Error Handling Scenarios

### Scenario 1: Zod Validation Error

Automatically handled - no manual classification needed:

```typescript
try {
  const validated = createUserSchema.parse(body);
  // ...
} catch (error) {
  return handleError(error, 'POST /api/users');
  // Automatically: ErrorType.VALIDATION_ERROR, status 400
}
```

**Response:**
```json
{
  "success": false,
  "message": "Invalid input provided. Please check your data and try again.",
  "type": "VALIDATION_ERROR",
  "errors": [
    { "field": "email", "message": "Invalid email" }
  ]
}
```

### Scenario 2: Prisma Unique Constraint (Duplicate)

Automatically classified as CONFLICT_ERROR:

```typescript
try {
  const user = await prisma.user.create({
    data: { email, password },
  });
  // Prisma P2002 error automatically caught
} catch (error) {
  return handleError(error, 'POST /api/users');
  // Automatically: ErrorType.CONFLICT_ERROR, status 409
}
```

**Response:**
```json
{
  "success": false,
  "message": "This action conflicts with existing data. Please verify and try again.",
  "type": "CONFLICT_ERROR"
}
```

### Scenario 3: Resource Not Found

Automatically classified (Prisma P2025) or manually thrown:

```typescript
// Option 1: Using Prisma findUnique + manual check
const user = await prisma.user.findUnique({ where: { id } });
if (!user) {
  throw new AppError(
    ErrorType.NOT_FOUND_ERROR,
    404,
    'User not found',
    { userId: id }
  );
}

// Option 2: Using findUniqueOrThrow (Prisma throws P2025)
try {
  const user = await prisma.user.findUniqueOrThrow({
    where: { id },
  });
} catch (error) {
  return handleError(error, 'GET /api/users/[id]');
  // Automatically: ErrorType.NOT_FOUND_ERROR, status 404
}
```

**Response:**
```json
{
  "success": false,
  "message": "The requested resource was not found.",
  "type": "NOT_FOUND_ERROR"
}
```

### Scenario 4: Authentication Error

Automatically detected for JWT errors:

```typescript
try {
  const decoded = jwt.verify(token, process.env.JWT_SECRET!);
} catch (error) {
  return handleError(error, 'Authentication check');
  // Automatically: ErrorType.AUTHENTICATION_ERROR, status 401
}
```

**Response:**
```json
{
  "success": false,
  "message": "Authentication failed. Please log in and try again.",
  "type": "AUTHENTICATION_ERROR"
}
```

### Scenario 5: Custom Business Logic Error

Manually throw AppError:

```typescript
if (order.status !== 'PENDING') {
  throw new AppError(
    ErrorType.CONFLICT_ERROR,
    409,
    'Order cannot be cancelled - already in progress',
    { orderId: order.id, status: order.status }
  );
}
```

**Response:**
```json
{
  "success": false,
  "message": "This action conflicts with existing data. Please verify and try again.",
  "type": "CONFLICT_ERROR"
}
```

### Scenario 6: Authorization Error

Check permissions before executing:

```typescript
const userRole = req.headers.get('x-user-role');

if (userRole !== 'ADMIN') {
  throw new AppError(
    ErrorType.AUTHORIZATION_ERROR,
    403,
    'Only admins can access this endpoint',
    { attemptedBy: req.headers.get('x-user-id') }
  );
}
```

**Response:**
```json
{
  "success": false,
  "message": "You do not have permission to perform this action.",
  "type": "AUTHORIZATION_ERROR"
}
```

### Scenario 7: Database Error (Non-Specific)

Automatically classified for other Prisma errors:

```typescript
try {
  const results = await prisma.xxx.findMany({
    // Complex query
  });
} catch (error) {
  return handleError(error, 'GET /api/xxx');
  // Automatically: ErrorType.DATABASE_ERROR, status 500
}
```

**Response (Production):**
```json
{
  "success": false,
  "message": "A database error occurred. Please try again later.",
  "type": "DATABASE_ERROR"
}
```

**Response (Development):**
```json
{
  "success": false,
  "message": "Connection timeout",
  "type": "DATABASE_ERROR",
  "context": "GET /api/xxx",
  "stack": "Error: Connection timeout\n    at..."
}
```

---

## Logging Best Practices

### Success Logging

```typescript
// ✅ Log important operations
logger.info('User created', { userId: user.id, email: user.email });
logger.info('Order processed', { orderId: order.id, total: order.total });
logger.info('Payment received', { transactionId, amount });

// ✅ Log data retrieval with counts
logger.info('Users retrieved', { count: users.length, page: 1 });

// ❌ Don't log every operation
// logger.info('Parsing request body'); // Too verbose

// ❌ Don't log sensitive data
// logger.info('User created', { password: 'secret123' }); // Security risk
```

### Error Logging

Error logging is handled automatically by `handleError()`, but you can add context:

```typescript
throw new AppError(
  ErrorType.DATABASE_ERROR,
  500,
  'Failed to save order',
  {
    orderId: 123,
    attemptedAt: new Date(),
    retryCount: 3,
  }
);
```

This context is included in logs for debugging.

---

## Testing Error Handlers

### Development Mode

```bash
# Terminal 1: Start dev server
npm run dev

# Terminal 2: Test validation error
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John"}' # Missing email and password

# Response (with full stack trace):
{
  "success": false,
  "message": "Validation failed",
  "type": "VALIDATION_ERROR",
  "context": "POST /api/users",
  "errors": [...],
  "stack": "..."
}

# Test not found error
curl -X GET http://localhost:3000/api/users/99999

# Response (with context):
{
  "success": false,
  "message": "User not found",
  "type": "NOT_FOUND_ERROR",
  "context": "GET /api/users/[id]"
}
```

### Production Mode

```bash
# Set env
NODE_ENV=production npm run dev

# Test same request
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "John"}'

# Response (sanitized):
{
  "success": false,
  "message": "Invalid input provided. Please check your data and try again.",
  "type": "VALIDATION_ERROR"
  # No context, no stack trace, no sensitive data
}
```

---

## Checklist for Each Route

When converting existing routes, ensure:

- [ ] Import `handleError`, `AppError`, `ErrorType` from `@/lib/errorHandler`
- [ ] Import `logger` from `@/lib/logger`
- [ ] Wrap all business logic in try/catch
- [ ] Call `handleError(error, 'METHOD /path')` in catch block
- [ ] Replace manual validation with schema.parse()
- [ ] Replace manual error returns with AppError throws
- [ ] Add logger.info() for successful operations
- [ ] Validate ID parameters early
- [ ] Check resource existence before updating/deleting
- [ ] Test in both development and production modes

---

## Common Migration Examples

### Before (Manual Error Handling)

```typescript
export async function GET(req: Request) {
  try {
    const users = await prisma.user.findMany();
    return NextResponse.json({ data: users });
  } catch (err: any) {
    console.error('Error:', err.message);
    return NextResponse.json(
      { error: err.message },
      { status: 500 }
    );
  }
}
```

### After (Centralized Error Handling)

```typescript
export async function GET(req: NextRequest) {
  try {
    const users = await prisma.user.findMany();
    logger.info('Users retrieved', { count: users.length });
    return NextResponse.json({ success: true, data: users });
  } catch (error) {
    return handleError(error, 'GET /api/users');
  }
}
```

---

## Key Benefits

1. **Consistency** - All errors handled the same way
2. **Security** - Stack traces hidden in production
3. **Debugging** - Full details available in development
4. **Maintainability** - Single place to update behavior
5. **Monitoring** - Structured logs for external services
6. **Type Safety** - ErrorType enum prevents typos

---

## Need Help?

- See [ERROR_HANDLING_GUIDE.md](ERROR_HANDLING_GUIDE.md) for complete reference
- Check existing routes in `src/app/api/users/` for examples
- Review error classification logic in `src/lib/errorHandler.ts`
