# Database Schema Documentation - FoodONtracks

## Entity-Relationship Model

### Core Entities

This document describes the normalized relational database schema for the FoodONtracks application, designed following database normalization principles (1NF, 2NF, 3NF).

---

## 📋 Table of Contents
1. [Entity Descriptions](#entity-descriptions)
2. [Entity Relationships](#entity-relationships)
3. [ER Diagram](#er-diagram)
4. [Normalization Principles](#normalization-principles)
5. [Keys and Constraints](#keys-and-constraints)
6. [Indexes for Performance](#indexes-for-performance)
7. [Common Queries](#common-queries)

---

## Entity Descriptions

### 1. **User**
Represents registered users of the system (customers, admins, restaurant owners).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique user identifier |
| name | VARCHAR | NOT NULL | User's full name |
| email | VARCHAR | UNIQUE, NOT NULL | User's email address |
| phoneNumber | VARCHAR | UNIQUE | User's phone number |
| password | VARCHAR | NOT NULL | Hashed password |
| role | ENUM | DEFAULT 'CUSTOMER' | User role (CUSTOMER, ADMIN, RESTAURANT_OWNER) |
| createdAt | TIMESTAMP | DEFAULT NOW() | Account creation timestamp |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update timestamp |

**Relations:**
- One user → Many orders
- One user → Many addresses
- One user → Many reviews

---

### 2. **Address**
Stores user delivery addresses (normalized to 3NF - no repeating groups).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique address identifier |
| userId | INT | FOREIGN KEY → User(id) | Reference to user |
| addressLine1 | VARCHAR | NOT NULL | Primary address line |
| addressLine2 | VARCHAR | NULLABLE | Secondary address line |
| city | VARCHAR | NOT NULL | City name |
| state | VARCHAR | NOT NULL | State/Province |
| zipCode | VARCHAR | NOT NULL | Postal code |
| country | VARCHAR | DEFAULT 'USA' | Country |
| isDefault | BOOLEAN | DEFAULT FALSE | Default address flag |
| createdAt | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update timestamp |

**Relations:**
- Many addresses → One user
- One address → Many orders

**Constraints:**
- `ON DELETE CASCADE` - Deleting a user deletes their addresses

---

### 3. **Restaurant**
Represents food vendor establishments.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique restaurant identifier |
| name | VARCHAR | NOT NULL | Restaurant name |
| email | VARCHAR | UNIQUE, NOT NULL | Contact email |
| phoneNumber | VARCHAR | UNIQUE, NOT NULL | Contact phone |
| description | TEXT | NULLABLE | Restaurant description |
| address | VARCHAR | NOT NULL | Physical address |
| city | VARCHAR | NOT NULL | City |
| state | VARCHAR | NOT NULL | State |
| zipCode | VARCHAR | NOT NULL | Postal code |
| rating | FLOAT | DEFAULT 0 | Average rating |
| isActive | BOOLEAN | DEFAULT TRUE | Active status |
| createdAt | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update timestamp |

**Relations:**
- One restaurant → Many menu items
- One restaurant → Many orders
- One restaurant → Many reviews

---

### 4. **MenuItem**
Represents food items offered by restaurants.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique item identifier |
| restaurantId | INT | FOREIGN KEY → Restaurant(id) | Parent restaurant |
| name | VARCHAR | NOT NULL | Item name |
| description | TEXT | NULLABLE | Item description |
| price | DECIMAL | NOT NULL | Item price |
| category | VARCHAR | NOT NULL | Food category |
| imageUrl | VARCHAR | NULLABLE | Image URL |
| isAvailable | BOOLEAN | DEFAULT TRUE | Availability status |
| preparationTime | INT | NOT NULL | Prep time in minutes |
| createdAt | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update timestamp |

**Relations:**
- Many menu items → One restaurant
- One menu item → Many order items

**Constraints:**
- `ON DELETE CASCADE` - Deleting a restaurant deletes its menu items

---

### 5. **Order**
Represents customer orders.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique order identifier |
| orderNumber | VARCHAR | UNIQUE, DEFAULT UUID() | Human-readable order number |
| userId | INT | FOREIGN KEY → User(id) | Customer reference |
| restaurantId | INT | FOREIGN KEY → Restaurant(id) | Restaurant reference |
| addressId | INT | FOREIGN KEY → Address(id) | Delivery address |
| deliveryPersonId | INT | FOREIGN KEY → DeliveryPerson(id) | Assigned delivery person |
| status | ENUM | DEFAULT 'PENDING' | Order status |
| totalAmount | DECIMAL | NOT NULL | Total order amount |
| deliveryFee | DECIMAL | DEFAULT 0 | Delivery charge |
| tax | DECIMAL | DEFAULT 0 | Tax amount |
| discount | DECIMAL | DEFAULT 0 | Discount amount |
| specialInstructions | TEXT | NULLABLE | Customer notes |
| estimatedDeliveryTime | TIMESTAMP | NULLABLE | Estimated delivery |
| actualDeliveryTime | TIMESTAMP | NULLABLE | Actual delivery time |
| createdAt | TIMESTAMP | DEFAULT NOW() | Order creation time |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update |

**Relations:**
- Many orders → One user
- Many orders → One restaurant
- Many orders → One address
- Many orders → One delivery person (optional)
- One order → Many order items
- One order → Many tracking events
- One order → One payment
- One order → One review (optional)

**Status Enum Values:**
- PENDING
- CONFIRMED
- PREPARING
- READY_FOR_PICKUP
- OUT_FOR_DELIVERY
- DELIVERED
- CANCELLED

---

### 6. **OrderItem**
Junction table linking orders and menu items (normalized to avoid redundancy).

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier |
| orderId | INT | FOREIGN KEY → Order(id) | Order reference |
| menuItemId | INT | FOREIGN KEY → MenuItem(id) | Menu item reference |
| quantity | INT | NOT NULL | Item quantity |
| priceAtTime | DECIMAL | NOT NULL | Price when ordered |

**Relations:**
- Many order items → One order
- Many order items → One menu item

**Constraints:**
- `ON DELETE CASCADE` - Deleting an order deletes its items
- `UNIQUE(orderId, menuItemId)` - Prevents duplicate items in same order
- `priceAtTime` preserves historical pricing data

---

### 7. **DeliveryPerson**
Represents delivery personnel.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier |
| name | VARCHAR | NOT NULL | Delivery person name |
| email | VARCHAR | UNIQUE, NOT NULL | Contact email |
| phoneNumber | VARCHAR | UNIQUE, NOT NULL | Contact phone |
| vehicleType | VARCHAR | NOT NULL | Vehicle type |
| vehicleNumber | VARCHAR | UNIQUE, NOT NULL | Vehicle registration |
| isAvailable | BOOLEAN | DEFAULT TRUE | Availability status |
| rating | FLOAT | DEFAULT 0 | Average rating |
| createdAt | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update |

**Relations:**
- One delivery person → Many orders

---

### 8. **OrderTracking**
Tracks order status changes and location updates.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier |
| orderId | INT | FOREIGN KEY → Order(id) | Order reference |
| status | ENUM | NOT NULL | Status at this point |
| location | VARCHAR | NULLABLE | Location description |
| latitude | FLOAT | NULLABLE | GPS latitude |
| longitude | FLOAT | NULLABLE | GPS longitude |
| notes | TEXT | NULLABLE | Additional notes |
| timestamp | TIMESTAMP | DEFAULT NOW() | Event timestamp |

**Relations:**
- Many tracking events → One order

**Constraints:**
- `ON DELETE CASCADE` - Deleting an order deletes tracking history

---

### 9. **Payment**
Represents payment transactions.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier |
| orderId | INT | FOREIGN KEY → Order(id), UNIQUE | Order reference |
| amount | DECIMAL | NOT NULL | Payment amount |
| paymentMethod | ENUM | NOT NULL | Payment method |
| transactionId | VARCHAR | UNIQUE, NOT NULL | External transaction ID |
| status | ENUM | DEFAULT 'PENDING' | Payment status |
| createdAt | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update |

**Relations:**
- One payment → One order (1:1 relationship)

**Payment Method Enum:**
- CREDIT_CARD
- DEBIT_CARD
- UPI
- CASH_ON_DELIVERY
- WALLET

**Payment Status Enum:**
- PENDING
- COMPLETED
- FAILED
- REFUNDED

**Constraints:**
- `ON DELETE CASCADE` - Deleting an order deletes payment record
- `UNIQUE(orderId)` - One payment per order
- `UNIQUE(transactionId)` - Prevents duplicate transactions

---

### 10. **Review**
Represents customer reviews for restaurants and orders.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | INT | PRIMARY KEY, AUTO_INCREMENT | Unique identifier |
| userId | INT | FOREIGN KEY → User(id) | Reviewer reference |
| restaurantId | INT | FOREIGN KEY → Restaurant(id) | Restaurant reference |
| orderId | INT | FOREIGN KEY → Order(id), UNIQUE | Order reference |
| rating | INT | NOT NULL, CHECK (1-5) | Rating (1-5 stars) |
| comment | TEXT | NULLABLE | Review text |
| createdAt | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| updatedAt | TIMESTAMP | AUTO UPDATE | Last update |

**Relations:**
- Many reviews → One user
- Many reviews → One restaurant
- One review → One order (1:1)

**Constraints:**
- `ON DELETE CASCADE` - Deleting user/restaurant/order deletes reviews
- `CHECK (rating >= 1 AND rating <= 5)` - Rating validation
- `UNIQUE(orderId)` - One review per order

---

## Entity Relationships

```
User (1) ────────< (M) Address
User (1) ────────< (M) Order
User (1) ────────< (M) Review

Restaurant (1) ──< (M) MenuItem
Restaurant (1) ──< (M) Order
Restaurant (1) ──< (M) Review

Order (1) ───────< (M) OrderItem
Order (1) ───────< (M) OrderTracking
Order (1) ──────── (1) Payment
Order (1) ──────── (1) Review

MenuItem (1) ────< (M) OrderItem

DeliveryPerson (1) < (M) Order

Address (1) ─────< (M) Order
```

---

## ER Diagram

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│     User     │         │  Restaurant  │         │DeliveryPerson│
├──────────────┤         ├──────────────┤         ├──────────────┤
│ id (PK)      │         │ id (PK)      │         │ id (PK)      │
│ name         │         │ name         │         │ name         │
│ email (UQ)   │         │ email (UQ)   │         │ email (UQ)   │
│ phoneNumber  │         │ phoneNumber  │         │ phoneNumber  │
│ password     │         │ description  │         │ vehicleType  │
│ role         │         │ address      │         │ vehicleNumber│
└──────┬───────┘         │ city         │         │ isAvailable  │
       │                 │ state        │         │ rating       │
       │                 │ zipCode      │         └──────┬───────┘
       │                 │ rating       │                │
       │                 │ isActive     │                │
       │                 └──────┬───────┘                │
       │                        │                        │
       │                        │                        │
       ▼                        ▼                        │
┌──────────────┐         ┌──────────────┐               │
│   Address    │         │  MenuItem    │               │
├──────────────┤         ├──────────────┤               │
│ id (PK)      │         │ id (PK)      │               │
│ userId (FK)  │         │restaurantId  │               │
│ addressLine1 │         │ name         │               │
│ city         │         │ description  │               │
│ state        │         │ price        │               │
│ zipCode      │         │ category     │               │
│ isDefault    │         │ isAvailable  │               │
└──────┬───────┘         │ prepTime     │               │
       │                 └──────┬───────┘               │
       │                        │                        │
       │                        │                        │
       └────────┐      ┌────────┘                       │
                │      │                                 │
                ▼      ▼                                 ▼
         ┌──────────────────────┐
         │       Order          │
         ├──────────────────────┤
         │ id (PK)              │
         │ orderNumber (UQ)     │
         │ userId (FK)          │◄────────────┐
         │ restaurantId (FK)    │             │
         │ addressId (FK)       │             │
         │ deliveryPersonId(FK) │             │
         │ status               │             │
         │ totalAmount          │             │
         │ deliveryFee          │             │
         │ tax                  │             │
         │ discount             │             │
         └──────┬───────────────┘             │
                │                              │
       ┌────────┼────────┬──────────┐         │
       │        │        │          │         │
       ▼        ▼        ▼          ▼         │
┌──────────┐ ┌─────┐ ┌──────┐ ┌────────┐     │
│OrderItem │ │Track│ │Paymt │ │ Review │     │
├──────────┤ ├─────┤ ├──────┤ ├────────┤     │
│ orderId  │ │order│ │order │ │ userId │─────┘
│ menuItem │ │status│ │amount│ │restId  │
│ quantity │ │locat│ │method│ │orderId │
│ price    │ │notes│ │txnId │ │ rating │
└──────────┘ └─────┘ │status│ │comment │
                     └──────┘ └────────┘
```

---

## Normalization Principles

### **First Normal Form (1NF)**
✅ All tables have:
- Atomic values (no repeating groups)
- Primary keys
- No duplicate rows

**Example:** Address entity separates user addresses instead of storing multiple addresses in a single field.

### **Second Normal Form (2NF)**
✅ All non-key attributes are fully dependent on the primary key.

**Example:** `OrderItem` stores `priceAtTime` instead of deriving from `MenuItem.price`, preserving historical data integrity when menu prices change.

### **Third Normal Form (3NF)**
✅ No transitive dependencies - non-key attributes depend only on the primary key.

**Example:** 
- Restaurant location (city, state, zipCode) is in the Restaurant table, not derived from Order
- Order totals are calculated fields but stored for performance and audit purposes
- User roles stored directly on User, not through junction tables

### **Avoiding Redundancy**
- **OrderItem** junction table prevents duplication between Orders and MenuItems
- **Address** separate entity prevents repeating address data in every order
- **OrderTracking** stores status history without modifying the Order table repeatedly
- **Review** linked to Order (not just Restaurant) ensures one review per completed order

---

## Keys and Constraints

### Primary Keys (PK)
Every table has an auto-incrementing integer primary key (`id`) for:
- Guaranteed uniqueness
- Efficient indexing
- Simple foreign key relationships

### Foreign Keys (FK)
All relationships use foreign keys with referential integrity:

| Child Table | Foreign Key | Parent Table | On Delete |
|-------------|-------------|--------------|-----------|
| Address | userId | User | CASCADE |
| MenuItem | restaurantId | Restaurant | CASCADE |
| Order | userId | User | RESTRICT |
| Order | restaurantId | Restaurant | RESTRICT |
| Order | addressId | Address | RESTRICT |
| Order | deliveryPersonId | DeliveryPerson | SET NULL |
| OrderItem | orderId | Order | CASCADE |
| OrderItem | menuItemId | MenuItem | RESTRICT |
| OrderTracking | orderId | Order | CASCADE |
| Payment | orderId | Order | CASCADE |
| Review | userId | User | CASCADE |
| Review | restaurantId | Restaurant | CASCADE |
| Review | orderId | Order | CASCADE |

### Unique Constraints (UQ)
- `User.email`
- `User.phoneNumber`
- `Restaurant.email`
- `Restaurant.phoneNumber`
- `DeliveryPerson.email`
- `DeliveryPerson.phoneNumber`
- `DeliveryPerson.vehicleNumber`
- `Order.orderNumber`
- `Payment.orderId` (1:1 relationship)
- `Payment.transactionId`
- `Review.orderId` (1:1 relationship)
- `OrderItem (orderId, menuItemId)` - Composite unique

### Check Constraints
- `Review.rating` - CHECK (rating >= 1 AND rating <= 5)
- `OrderItem.quantity` - CHECK (quantity > 0)
- `MenuItem.price` - CHECK (price >= 0)

---

## Indexes for Performance

Indexes created on frequently queried columns:

### User Table
```sql
INDEX idx_user_email ON User(email)
INDEX idx_user_role ON User(role)
```

### Address Table
```sql
INDEX idx_address_userId ON Address(userId)
INDEX idx_address_zipCode ON Address(zipCode)
```

### Restaurant Table
```sql
INDEX idx_restaurant_city ON Restaurant(city)
INDEX idx_restaurant_zipCode ON Restaurant(zipCode)
INDEX idx_restaurant_rating ON Restaurant(rating)
INDEX idx_restaurant_isActive ON Restaurant(isActive)
```

### MenuItem Table
```sql
INDEX idx_menuitem_restaurantId ON MenuItem(restaurantId)
INDEX idx_menuitem_category ON MenuItem(category)
INDEX idx_menuitem_isAvailable ON MenuItem(isAvailable)
```

### Order Table
```sql
INDEX idx_order_userId ON Order(userId)
INDEX idx_order_restaurantId ON Order(restaurantId)
INDEX idx_order_status ON Order(status)
INDEX idx_order_orderNumber ON Order(orderNumber)
INDEX idx_order_createdAt ON Order(createdAt)
```

### OrderItem Table
```sql
INDEX idx_orderitem_orderId ON OrderItem(orderId)
```

### DeliveryPerson Table
```sql
INDEX idx_deliveryperson_isAvailable ON DeliveryPerson(isAvailable)
INDEX idx_deliveryperson_rating ON DeliveryPerson(rating)
```

### OrderTracking Table
```sql
INDEX idx_tracking_orderId ON OrderTracking(orderId)
INDEX idx_tracking_timestamp ON OrderTracking(timestamp)
```

### Payment Table
```sql
INDEX idx_payment_transactionId ON Payment(transactionId)
INDEX idx_payment_status ON Payment(status)
```

### Review Table
```sql
INDEX idx_review_userId ON Review(userId)
INDEX idx_review_restaurantId ON Review(restaurantId)
INDEX idx_review_rating ON Review(rating)
```

---

## Common Queries

### Query 1: Get user's order history with details
```sql
SELECT 
  o.orderNumber,
  r.name AS restaurantName,
  o.status,
  o.totalAmount,
  o.createdAt
FROM Order o
JOIN Restaurant r ON o.restaurantId = r.id
WHERE o.userId = ?
ORDER BY o.createdAt DESC;
```

**Optimized by:** `idx_order_userId`, `idx_order_createdAt`

---

### Query 2: Get restaurant menu items by category
```sql
SELECT 
  name,
  description,
  price,
  category,
  isAvailable
FROM MenuItem
WHERE restaurantId = ? AND isAvailable = true
ORDER BY category, price;
```

**Optimized by:** `idx_menuitem_restaurantId`, `idx_menuitem_category`, `idx_menuitem_isAvailable`

---

### Query 3: Track order status updates
```sql
SELECT 
  status,
  location,
  latitude,
  longitude,
  notes,
  timestamp
FROM OrderTracking
WHERE orderId = ?
ORDER BY timestamp ASC;
```

**Optimized by:** `idx_tracking_orderId`, `idx_tracking_timestamp`

---

### Query 4: Find available delivery persons
```sql
SELECT 
  id,
  name,
  phoneNumber,
  vehicleType,
  rating
FROM DeliveryPerson
WHERE isAvailable = true
ORDER BY rating DESC;
```

**Optimized by:** `idx_deliveryperson_isAvailable`, `idx_deliveryperson_rating`

---

### Query 5: Get restaurant ratings
```sql
SELECT 
  r.name,
  r.rating,
  COUNT(rev.id) AS totalReviews,
  AVG(rev.rating) AS averageRating
FROM Restaurant r
LEFT JOIN Review rev ON r.id = rev.restaurantId
WHERE r.city = ?
GROUP BY r.id
ORDER BY r.rating DESC;
```

**Optimized by:** `idx_restaurant_city`, `idx_restaurant_rating`, `idx_review_restaurantId`

---

## Scalability Considerations

### 1. **Partitioning Strategy**
- **Order table** can be partitioned by `createdAt` (monthly/yearly) for better query performance on historical data
- **OrderTracking** can be partitioned similarly

### 2. **Caching Strategy**
- Cache frequently accessed menu items
- Cache restaurant ratings and reviews
- Cache user addresses for quick checkout

### 3. **Read Replicas**
- Set up read replicas for order tracking queries
- Separate analytics queries from transactional queries

### 4. **Archival Strategy**
- Archive old orders (> 1 year) to separate tables
- Maintain payment records for audit purposes

### 5. **Connection Pooling**
- Use Prisma's connection pooling for efficient database connections
- Configure appropriate pool sizes based on load

---

## Migration Strategy

### Initial Migration
```bash
npx prisma migrate dev --name init_schema
```

### Future Migrations
When schema changes are needed:
1. Update `schema.prisma`
2. Run `npx prisma migrate dev --name descriptive_name`
3. Test in development environment
4. Apply to production with `npx prisma migrate deploy`

---

## Conclusion

This normalized schema:
- ✅ Eliminates data redundancy
- ✅ Ensures data integrity through constraints
- ✅ Supports complex queries efficiently with indexes
- ✅ Scales horizontally with proper partitioning
- ✅ Maintains audit trails with timestamps
- ✅ Provides referential integrity with cascading deletes

The design supports the full lifecycle of a food delivery application while maintaining flexibility for future enhancements.
