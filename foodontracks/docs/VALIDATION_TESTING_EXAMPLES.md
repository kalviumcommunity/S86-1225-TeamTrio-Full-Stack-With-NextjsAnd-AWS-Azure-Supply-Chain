# Validation Testing Examples

This document provides real-world examples for testing all validated endpoints with both passing and failing requests.

---

## 1. Users API

### ✅ Create User (Valid)

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "phoneNumber": "+1-555-123-4567",
    "password": "SecurePassword123",
    "role": "CUSTOMER"
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "id": 1,
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "phoneNumber": "+1-555-123-4567",
    "role": "CUSTOMER",
    "createdAt": "2025-12-18T10:00:00Z"
  }
}
```

### ❌ Create User (Invalid Email)

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Bob Smith",
    "email": "not-an-email",
    "password": "Pass123"
  }'
```

**Expected Response (400):**
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

### ❌ Create User (Short Name)

```bash
curl -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "A",
    "email": "alice@example.com",
    "password": "SecurePass"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "name",
      "message": "Name must be at least 2 characters long"
    }
  ]
}
```

### ✅ Update User (Valid)

```bash
curl -X PUT http://localhost:3000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Alice Updated",
    "email": "alice.updated@example.com"
  }'
```

---

## 2. Restaurants API

### ✅ Create Restaurant (Valid)

```bash
curl -X POST http://localhost:3000/api/restaurants \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Taj Mahal Palace",
    "email": "contact@tajmahal.com",
    "phoneNumber": "+1-555-987-6543",
    "description": "Authentic Indian cuisine since 1990",
    "address": "123 Curry Lane",
    "city": "Mumbai",
    "state": "Maharashtra",
    "zipCode": "400001"
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Restaurant created successfully",
  "data": {
    "id": 1,
    "name": "Taj Mahal Palace",
    "email": "contact@tajmahal.com",
    "phoneNumber": "+1-555-987-6543",
    "city": "Mumbai",
    "rating": 0,
    "isActive": true,
    "createdAt": "2025-12-18T10:05:00Z"
  }
}
```

### ❌ Create Restaurant (Invalid Phone Number)

```bash
curl -X POST http://localhost:3000/api/restaurants \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Restaurant",
    "email": "rest@example.com",
    "phoneNumber": "not-a-phone",
    "address": "123 Street",
    "city": "Mumbai",
    "state": "MH",
    "zipCode": "400001"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "phoneNumber",
      "message": "Invalid phone number format"
    }
  ]
}
```

### ❌ Create Restaurant (Missing Required Fields)

```bash
curl -X POST http://localhost:3000/api/restaurants \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Restaurant",
    "email": "rest@example.com"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "phoneNumber",
      "message": "Required"
    },
    {
      "field": "address",
      "message": "Required"
    },
    {
      "field": "city",
      "message": "Required"
    },
    {
      "field": "state",
      "message": "Required"
    },
    {
      "field": "zipCode",
      "message": "Required"
    }
  ]
}
```

---

## 3. Menu Items API

### ✅ Create Menu Item (Valid)

```bash
curl -X POST http://localhost:3000/api/menu-items \
  -H "Content-Type: application/json" \
  -d '{
    "restaurantId": 1,
    "name": "Butter Chicken",
    "description": "Creamy butter sauce with tender chicken",
    "price": 350.50,
    "category": "Curries",
    "preparationTime": 20,
    "stock": 50,
    "isAvailable": true
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Menu item created successfully",
  "data": {
    "id": 1,
    "restaurantId": 1,
    "name": "Butter Chicken",
    "price": 350.50,
    "category": "Curries",
    "preparationTime": 20,
    "stock": 50,
    "isAvailable": true,
    "createdAt": "2025-12-18T10:10:00Z"
  }
}
```

### ❌ Create Menu Item (Negative Price)

```bash
curl -X POST http://localhost:3000/api/menu-items \
  -H "Content-Type: application/json" \
  -d '{
    "restaurantId": 1,
    "name": "Biryani",
    "price": -250,
    "category": "Rice",
    "preparationTime": 30
  }'
```

**Expected Response (400):**
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

### ❌ Create Menu Item (Invalid Preparation Time)

```bash
curl -X POST http://localhost:3000/api/menu-items \
  -H "Content-Type: application/json" \
  -d '{
    "restaurantId": 1,
    "name": "Biryani",
    "price": 300,
    "category": "Rice",
    "preparationTime": -10
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "preparationTime",
      "message": "Number must be greater than 0"
    }
  ]
}
```

### ✅ Update Menu Item (Partial Update)

```bash
curl -X PUT http://localhost:3000/api/menu-items/1 \
  -H "Content-Type: application/json" \
  -d '{
    "price": 375.50,
    "stock": 35
  }'
```

---

## 4. Orders API

### ✅ Create Order (Valid)

```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "restaurantId": 1,
    "addressId": 1,
    "orderItems": [
      {
        "menuItemId": 1,
        "quantity": 2,
        "priceAtTime": 350.50
      },
      {
        "menuItemId": 2,
        "quantity": 1,
        "priceAtTime": 250.00
      }
    ],
    "deliveryFee": 40.00,
    "tax": 80.50,
    "discount": 0.00,
    "specialInstructions": "No onions, extra chili"
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "id": 1,
    "orderNumber": "ORD-ABC123DEF",
    "userId": 1,
    "restaurantId": 1,
    "status": "PENDING",
    "totalAmount": 1071.00,
    "deliveryFee": 40.00,
    "tax": 80.50,
    "discount": 0.00,
    "createdAt": "2025-12-18T10:15:00Z"
  }
}
```

### ❌ Create Order (Empty Order Items)

```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "restaurantId": 1,
    "addressId": 1,
    "orderItems": []
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "orderItems",
      "message": "Array must contain at least 1 element(s)"
    }
  ]
}
```

### ❌ Create Order (Negative Delivery Fee)

```bash
curl -X POST http://localhost:3000/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "restaurantId": 1,
    "addressId": 1,
    "orderItems": [
      {
        "menuItemId": 1,
        "quantity": 1,
        "priceAtTime": 300
      }
    ],
    "deliveryFee": -50
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "deliveryFee",
      "message": "Number must be greater than or equal to 0"
    }
  ]
}
```

### ✅ Update Order Status

```bash
curl -X PUT http://localhost:3000/api/orders/1 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "CONFIRMED",
    "deliveryPersonId": 5
  }'
```

### ❌ Update Order (Invalid Status)

```bash
curl -X PUT http://localhost:3000/api/orders/1 \
  -H "Content-Type: application/json" \
  -d '{
    "status": "INVALID_STATUS"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "status",
      "message": "Invalid enum value"
    }
  ]
}
```

---

## 5. Addresses API

### ✅ Create Address (Valid)

```bash
curl -X POST http://localhost:3000/api/addresses \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "addressLine1": "123 Main Street, Apt 4B",
    "addressLine2": "Near Central Park",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "country": "USA",
    "isDefault": true
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Address created successfully",
  "data": {
    "id": 1,
    "userId": 1,
    "addressLine1": "123 Main Street, Apt 4B",
    "city": "New York",
    "state": "NY",
    "zipCode": "10001",
    "isDefault": true,
    "createdAt": "2025-12-18T10:20:00Z"
  }
}
```

### ❌ Create Address (Invalid ZIP Code)

```bash
curl -X POST http://localhost:3000/api/addresses \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "addressLine1": "123 Main Street",
    "city": "New York",
    "state": "NY",
    "zipCode": "INVALID_ZIP"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "zipCode",
      "message": "Invalid zip code format"
    }
  ]
}
```

### ❌ Create Address (Short Address)

```bash
curl -X POST http://localhost:3000/api/addresses \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "addressLine1": "123",
    "city": "NY",
    "state": "NY",
    "zipCode": "10001"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "addressLine1",
      "message": "String must contain at least 5 character(s)"
    }
  ]
}
```

---

## 6. Reviews API

### ✅ Create Review (Valid)

```bash
curl -X POST http://localhost:3000/api/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "restaurantId": 1,
    "orderId": 1,
    "rating": 5,
    "comment": "Excellent food quality and very fast delivery. Highly recommended!"
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Review created successfully",
  "data": {
    "id": 1,
    "userId": 1,
    "restaurantId": 1,
    "orderId": 1,
    "rating": 5,
    "comment": "Excellent food quality and very fast delivery. Highly recommended!",
    "createdAt": "2025-12-18T10:25:00Z"
  }
}
```

### ❌ Create Review (Rating Out of Range)

```bash
curl -X POST http://localhost:3000/api/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "restaurantId": 1,
    "orderId": 1,
    "rating": 10,
    "comment": "Great!"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "rating",
      "message": "Number must be less than or equal to 5"
    }
  ]
}
```

### ❌ Create Review (Rating Too Low)

```bash
curl -X POST http://localhost:3000/api/reviews \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "restaurantId": 1,
    "orderId": 1,
    "rating": 0,
    "comment": "Bad"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "rating",
      "message": "Number must be greater than or equal to 1"
    }
  ]
}
```

---

## 7. Delivery Persons API

### ✅ Create Delivery Person (Valid)

```bash
curl -X POST http://localhost:3000/api/delivery-persons \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Rajesh Kumar",
    "email": "rajesh@deliveryflex.com",
    "phoneNumber": "+91-999-123-4567",
    "vehicleType": "Motorcycle",
    "vehicleNumber": "MH-01-AB-1234",
    "isAvailable": true
  }'
```

**Expected Response (201):**
```json
{
  "success": true,
  "message": "Delivery person created successfully",
  "data": {
    "id": 1,
    "name": "Rajesh Kumar",
    "email": "rajesh@deliveryflex.com",
    "phoneNumber": "+91-999-123-4567",
    "vehicleType": "Motorcycle",
    "vehicleNumber": "MH-01-AB-1234",
    "isAvailable": true,
    "rating": 0,
    "createdAt": "2025-12-18T10:30:00Z"
  }
}
```

### ❌ Create Delivery Person (Invalid Phone)

```bash
curl -X POST http://localhost:3000/api/delivery-persons \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Priya Singh",
    "email": "priya@deliveryflex.com",
    "phoneNumber": "INVALID",
    "vehicleType": "Scooter",
    "vehicleNumber": "MH-02-CD-5678"
  }'
```

**Expected Response (400):**
```json
{
  "success": false,
  "message": "Validation Error",
  "errors": [
    {
      "field": "phoneNumber",
      "message": "Invalid phone number format"
    }
  ]
}
```

---

## Testing Checklist

- ✅ Valid requests return 201/200 with data
- ✅ Invalid emails rejected with clear error
- ✅ Short names/fields rejected
- ✅ Out-of-range numbers rejected
- ✅ Invalid enums rejected
- ✅ Empty arrays rejected
- ✅ Missing required fields rejected
- ✅ All errors have "field" and "message"
- ✅ Error status code is 400
- ✅ Success status codes are 200/201

---

## Using Bruno for Testing

1. Open `testing/test.bru` in Bruno
2. Import all test cases from Bruno UI
3. Run requests and verify validation
4. Check both success and error cases

---

**All validation tests are ready to run!**
