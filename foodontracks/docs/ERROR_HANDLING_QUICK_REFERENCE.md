# Error Handling Quick Reference

## One-Minute Setup

### Import in Route Handler
```typescript
import { handleError, AppError, ErrorType } from '@/lib/errorHandler';
import { logger } from '@/lib/logger';
```

### Basic Pattern
```typescript
export async function METHOD(req: NextRequest) {
  try {
    // Your code
    logger.info('Success', { data });
    return NextResponse.json({ success: true, data });
  } catch (error) {
    return handleError(error, 'METHOD /path');
  }
}
```

---

## Error Types Quick Reference

```typescript
ErrorType.VALIDATION_ERROR       // 400 - Invalid input
ErrorType.AUTHENTICATION_ERROR   // 401 - Invalid JWT
ErrorType.AUTHORIZATION_ERROR    // 403 - No permission
ErrorType.NOT_FOUND_ERROR        // 404 - Resource missing
ErrorType.CONFLICT_ERROR         // 409 - Data conflict
ErrorType.DATABASE_ERROR         // 500 - DB failure
ErrorType.EXTERNAL_API_ERROR     // 502 - 3rd party fail
ErrorType.INTERNAL_SERVER_ERROR  // 500 - Unexpected error
```

---

## Common Patterns

### Validate with Zod
```typescript
const validated = createUserSchema.parse(body);
// ✅ Automatically: VALIDATION_ERROR if invalid
```

### Check Existence
```typescript
if (!item) {
  throw new AppError(ErrorType.NOT_FOUND_ERROR, 404, 'Not found', { id });
}
```

### Check Conflict
```typescript
if (exists) {
  throw new AppError(ErrorType.CONFLICT_ERROR, 409, 'Already exists');
}
```

### Check Permission
```typescript
if (userRole !== 'ADMIN') {
  throw new AppError(ErrorType.AUTHORIZATION_ERROR, 403, 'Admin only');
}
```

### Log Success
```typescript
logger.info('Operation done', { userId: 123, action: 'created' });
```

---

## Response Examples

### Success
```json
{ "success": true, "data": {...} }
```

### Validation Error
```json
{
  "success": false,
  "message": "Invalid input...",
  "type": "VALIDATION_ERROR",
  "errors": [{"field": "email", "message": "..."}]
}
```

### Not Found
```json
{
  "success": false,
  "message": "The requested resource was not found.",
  "type": "NOT_FOUND_ERROR"
}
```

---

## Key Points

✅ All errors handled with `handleError(error, 'context')`  
✅ Zod errors auto-classified  
✅ Prisma errors auto-classified  
✅ JWT errors auto-classified  
✅ Custom errors use `throw new AppError(...)`  
✅ Log successes with `logger.info(...)`  
✅ Stack traces hidden in production  
✅ User-friendly messages in production  

---

## Files

- **Implementation:** `src/lib/logger.ts`, `src/lib/errorHandler.ts`
- **Full Guide:** `docs/ERROR_HANDLING_GUIDE.md`
- **Integration:** `docs/ERROR_HANDLING_INTEGRATION.md`
- **Examples:** `src/app/api/users/route.ts`, `src/app/api/users/[id]/route.ts`

---

**See ERROR_HANDLING_GUIDE.md for complete documentation**
