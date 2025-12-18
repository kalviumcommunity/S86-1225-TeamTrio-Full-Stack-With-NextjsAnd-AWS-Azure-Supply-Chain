# Input Validation Implementation Guide

## Overview

This document outlines the comprehensive input validation system implemented using **Zod**, a TypeScript-first schema validation library. All POST and PUT API endpoints are protected with strict schema validation to ensure data integrity and security.

---

## Why Input Validation Matters

Every API needs to:
- **Verify data structure** before processing
- **Protect the database** from invalid or malicious inputs
- **Provide clear error messages** to clients
- **Ensure type safety** across the full stack

### Example Problem (Without Validation)

```json
{
  "name": "",
  "email": "not-an-email",
  "phoneNumber": "invalid"
}
```

Without validation, this would:
- Create empty user records
- Store invalid email addresses
- Cause silent failures downstream
- Make debugging difficult

### Solution: Zod-Based Validation

All requests are validated **before** they reach your business logic.

---

## Installation

Zod has been added to `package.json`:

```bash
npm install zod
```

---

## Schema Structure

### 1. **User Schema**

**File:** `src/lib/schemas/userSchema.ts`

```typescript
import { z } from "zod";

export const createUserSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters long").max(100),
  email: z.string().email("Invalid email address"),
  phoneNumber: z.string().optional().nullable(),
  password: z.string().min(6, "Password must be at least 6 characters").max(100),
  role: z.enum(["CUSTOMER", "ADMIN", "RESTAURANT_OWNER"]).optional().default("CUSTOMER"),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
```

**Validation Rules:**
- `name`: 2-100 characters
- `email`: Valid email format
- `phoneNumber`: Optional, nullable string
- `password`: 6-100 characters
- `role`: One of predefined roles (defaults to CUSTOMER)

---

### 2. **Restaurant Schema**

**File:** `src/lib/schemas/restaurantSchema.ts`

```typescript
export const createRestaurantSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  phoneNumber: z.string().regex(/^[0-9\-\+\(\)]+$/, "Invalid phone number"),
  address: z.string().min(5).max(200),
  city: z.string().min(2).max(50),
  state: z.string().min(2).max(50),
  zipCode: z.string().regex(/^[0-9\-]+$/, "Invalid zip code").max(10),
});
```

**Validation Rules:**
- `name`: 2-100 characters
- `email`: Valid email
- `phoneNumber`: Phone number regex pattern
- `address`: 5-200 characters
- Geographic fields: Required, properly formatted

---

### 3. **Menu Item Schema**

**File:** `src/lib/schemas/menuItemSchema.ts`

```typescript
export const createMenuItemSchema = z.object({
  restaurantId: z.number().int().positive(),
  name: z.string().min(2).max(100),
  price: z.number().positive().max(9999.99),
  category: z.string().min(1).max(50),
  preparationTime: z.number().int().positive().max(999),
  stock: z.number().int().nonnegative().default(100),
});
```

**Validation Rules:**
- `restaurantId`: Positive integer
- `price`: Positive number, max $9999.99
- `stock`: Non-negative integer (defaults to 100)
- `preparationTime`: Positive minutes

---

### 4. **Order Schema**

**File:** `src/lib/schemas/orderSchema.ts`

```typescript
export const orderItemSchema = z.object({
  menuItemId: z.number().int().positive(),
  quantity: z.number().int().positive().max(999),
  priceAtTime: z.number().positive().max(9999.99),
});

export const createOrderSchema = z.object({
  userId: z.number().int().positive(),
  restaurantId: z.number().int().positive(),
  addressId: z.number().int().positive(),
  orderItems: z.array(orderItemSchema).min(1, "Must have at least one item"),
  deliveryFee: z.number().nonnegative().default(0),
  tax: z.number().nonnegative().default(0),
  discount: z.number().nonnegative().default(0),
  specialInstructions: z.string().optional().nullable().max(500),
});
```

**Validation Rules:**
- `orderItems`: Array with minimum 1 item
- `quantity`: 1-999 items
- Fees: Non-negative, reasonable limits

---

### 5. **Address Schema**

**File:** `src/lib/schemas/addressSchema.ts`

```typescript
export const createAddressSchema = z.object({
  userId: z.number().int().positive(),
  addressLine1: z.string().min(5).max(200),
  addressLine2: z.string().optional().nullable().max(200),
  city: z.string().min(2).max(50),
  state: z.string().min(2).max(50),
  zipCode: z.string().regex(/^[0-9\-]+$/).max(10),
  isDefault: z.boolean().optional().default(false),
});
```

---

### 6. **Delivery Person Schema**

**File:** `src/lib/schemas/deliveryPersonSchema.ts`

```typescript
export const createDeliveryPersonSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  phoneNumber: z.string().regex(/^[0-9\-\+\(\)]+$/),
  vehicleType: z.string().min(1).max(50),
  vehicleNumber: z.string().min(1).max(20),
  isAvailable: z.boolean().optional().default(true),
});
```

---

### 7. **Review Schema**

**File:** `src/lib/schemas/reviewSchema.ts`

```typescript
export const createReviewSchema = z.object({
  userId: z.number().int().positive(),
  restaurantId: z.number().int().positive(),
  orderId: z.number().int().positive(),
  rating: z.number().int().min(1).max(5),
  comment: z.string().optional().nullable().max(500),
});
```

**Validation Rules:**
- `rating`: 1-5 stars only
- `comment`: Optional, max 500 characters

---

### 8. **Payment Schema**

**File:** `src/lib/schemas/paymentSchema.ts`

```typescript
export const createPaymentSchema = z.object({
  orderId: z.number().int().positive(),
  amount: z.number().positive().max(999999.99),
  paymentMethod: z.enum(["CREDIT_CARD", "DEBIT_CARD", "UPI", "CASH_ON_DELIVERY", "WALLET"]),
  transactionId: z.string().min(1).max(100),
});
```

---

## Validation Utility

### **File:** `src/lib/validationUtils.ts`

This utility provides reusable functions for validation:

```typescript
import { validateData } from "@/lib/validationUtils";
import { createUserSchema } from "@/lib/schemas/userSchema";

// Validate and get structured response
const validationResult = validateData(createUserSchema, requestBody);

if (!validationResult.success) {
  // Handle validation errors
  return NextResponse.json(validationResult, { status: 400 });
}

const validatedData = validationResult.data;
// Use validatedData safely
```

---

## API Implementation Pattern

### **Before Validation:**

```typescript
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { name, email, password } = body;

    // Manual validation (error-prone)
    if (!name || !email || !password) {
      return sendError("Missing fields", "MISSING_FIELD", 400);
    }
    // ... rest of logic
  }
}
```

### **After Validation (Recommended):**

```typescript
import { createUserSchema } from "@/lib/schemas/userSchema";
import { validateData } from "@/lib/validationUtils";

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();

    // Zod validation with automatic type inference
    const validationResult = validateData(createUserSchema, body);
    if (!validationResult.success) {
      return NextResponse.json(validationResult, { status: 400 });
    }

    const { name, email, password } = validationResult.data;
    // ... rest of logic with full type safety
  } catch (error) {
    // ... error handling
  }
}
```

---

## Error Handling

### **Validation Error Response Format:**

```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email address"
    },
    {
      "field": "password",
      "message": "String must contain at least 6 character(s)"
    }
  ]
}
```

### **Status Codes:**
- `400`: Validation error (bad request)
- `409`: Conflict (duplicate entry)
- `404`: Resource not found
- `500`: Server error

---

## Testing Validation

### **✅ Valid Request (Passing Example)**

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "password": "SecurePass123",
    "role": "CUSTOMER"
  }'
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "id": 1,
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "role": "CUSTOMER",
    "createdAt": "2025-12-18T10:00:00Z"
  }
}
```

---

### **❌ Invalid Request (Failing Example)**

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "A",
    "email": "not-an-email",
    "password": "123"
  }'
```

**Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "name",
      "message": "String must contain at least 2 character(s)"
    },
    {
      "field": "email",
      "message": "Invalid email address"
    },
    {
      "field": "password",
      "message": "String must contain at least 6 character(s)"
    }
  ]
}
```

---

### **❌ Menu Item Invalid Price**

```bash
curl -X POST http://localhost:3000/api/menu-items \
  -H "Content-Type: application/json" \
  -d '{
    "restaurantId": 1,
    "name": "Biryani",
    "price": -50,
    "category": "Rice",
    "preparationTime": 15
  }'
```

**Response (400 Bad Request):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "price",
      "message": "Number must be greater than 0"
    }
  ]
}
```

---

### **✅ Order Creation with Multiple Items**

```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "restaurantId": 2,
    "addressId": 3,
    "orderItems": [
      {
        "menuItemId": 5,
        "quantity": 2,
        "priceAtTime": 250.00
      },
      {
        "menuItemId": 8,
        "quantity": 1,
        "priceAtTime": 150.00
      }
    ],
    "deliveryFee": 40,
    "tax": 50,
    "discount": 0
  }'
```

**Response (201 Created):**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "id": 42,
    "orderNumber": "ORD-ABC123XY",
    "status": "PENDING",
    "totalAmount": 490,
    "createdAt": "2025-12-18T10:15:00Z"
  }
}
```

---

## Schema Reuse Between Client and Server

### **Shared Validation Across Stack:**

```typescript
// lib/schemas/userSchema.ts
export const createUserSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
  password: z.string().min(6).max(100),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
```

**Client-side (React):**
```typescript
import { CreateUserInput } from "@/lib/schemas/userSchema";

const handleSubmit = (formData: CreateUserInput) => {
  // TypeScript validates at compile time
  api.post("/api/users", formData);
};
```

**Server-side (API Route):**
```typescript
import { validateData } from "@/lib/validationUtils";
import { createUserSchema } from "@/lib/schemas/userSchema";

const validationResult = validateData(createUserSchema, body);
// Same schema enforced at runtime
```

**Benefits:**
- ✅ Single source of truth
- ✅ Type safety end-to-end
- ✅ Consistency across layers
- ✅ Reduced bugs and manual validation

---

## Validated API Endpoints

### **POST Endpoints (All Validated)**

| Endpoint | Schema | Validation Focus |
|----------|--------|------------------|
| `POST /api/users` | `createUserSchema` | Email, password strength, role |
| `POST /api/restaurants` | `createRestaurantSchema` | Contact info, address format |
| `POST /api/menu-items` | `createMenuItemSchema` | Price, stock, timing |
| `POST /api/orders` | `createOrderSchema` | Multiple items, fees calculation |
| `POST /api/addresses` | `createAddressSchema` | ZIP code, geography |
| `POST /api/delivery-persons` | `createDeliveryPersonSchema` | Vehicle info, contact |
| `POST /api/reviews` | `createReviewSchema` | Rating range (1-5), length |

### **PUT Endpoints (All Validated)**

| Endpoint | Schema | Notes |
|----------|--------|-------|
| `PUT /api/users/[id]` | `updateUserSchema` | All fields optional |
| `PUT /api/restaurants/[id]` | `updateRestaurantSchema` | Partial updates allowed |
| `PUT /api/menu-items/[id]` | `updateMenuItemSchema` | Stock, price updates |
| `PUT /api/orders/[id]` | `updateOrderSchema` | Status, delivery person, instructions |
| `PUT /api/addresses/[id]` | `updateAddressSchema` | Address modifications |
| `PUT /api/delivery-persons/[id]` | `updateDeliveryPersonSchema` | Availability, vehicle updates |

---

## Key Validation Features

### **1. Type Safety**
```typescript
const data = validationResult.data; // Fully typed!
// IDE knows about all properties
```

### **2. Descriptive Error Messages**
```json
"Name must be at least 2 characters long"
"Invalid email address"
"String must contain at least 6 character(s)"
```

### **3. Consistent Response Format**
All validation errors follow the same structure:
```typescript
{
  success: false,
  message: "Validation Error",
  errors: Array<{ field, message }>
}
```

### **4. Optional Field Handling**
```typescript
phoneNumber: z.string().optional().nullable()
// Handles both null and undefined
```

### **5. Default Values**
```typescript
role: z.enum([...]).default("CUSTOMER")
// Defaults to CUSTOMER if not provided
```

---

## Reflection: Why Schema Validation Matters for Teams

### **Problem Without Validation:**
- Team member A makes an API call with invalid data
- Bug appears in production, hard to trace
- Database now has corrupted records
- Multiple team members waste time debugging

### **Solution With Schema Validation:**
- ✅ Invalid request rejected immediately with clear error
- ✅ Team member sees exact problem: "Email must be valid"
- ✅ Database protected from bad data
- ✅ API documentation becomes self-enforcing (schema is docs)
- ✅ New team members understand data requirements instantly

### **Team Collaboration Benefits:**
1. **Shared Contract:** Schemas define exact API expectations
2. **Type Safety:** Less runtime surprises
3. **Clear Error Messages:** Dev doesn't guess what went wrong
4. **Reusability:** Client and server use same validation rules
5. **Maintainability:** Change validation in one place, everywhere updates

---

## Best Practices

### ✅ DO:
- Use schemas for ALL POST/PUT operations
- Return consistent error responses
- Validate at API boundary
- Share schemas between client and server
- Use descriptive error messages
- Test both passing and failing cases

### ❌ DON'T:
- Trust user input without validation
- Have different validation on client vs server
- Return raw database errors to clients
- Skip validation "just this once"
- Ignore field length limits
- Allow invalid enum values

---

## File Structure

```
src/
├── lib/
│   ├── schemas/
│   │   ├── userSchema.ts
│   │   ├── restaurantSchema.ts
│   │   ├── menuItemSchema.ts
│   │   ├── orderSchema.ts
│   │   ├── addressSchema.ts
│   │   ├── deliveryPersonSchema.ts
│   │   ├── reviewSchema.ts
│   │   ├── paymentSchema.ts
│   │   └── trackingSchema.ts
│   └── validationUtils.ts
└── app/
    └── api/
        ├── users/
        ├── restaurants/
        ├── menu-items/
        ├── orders/
        ├── addresses/
        ├── delivery-persons/
        ├── reviews/
        └── transactions/
```

---

## Conclusion

Input validation is critical infrastructure for reliable, maintainable APIs. By using Zod schemas:

- 🛡️ **Protect** your database from bad data
- 📝 **Document** API requirements clearly
- 🤝 **Enable** team collaboration safely
- 🐛 **Reduce** debugging time dramatically
- ✨ **Improve** user experience with clear errors

All FoodONtracks APIs now implement this validation pattern, ensuring safe, predictable behavior across the platform.
