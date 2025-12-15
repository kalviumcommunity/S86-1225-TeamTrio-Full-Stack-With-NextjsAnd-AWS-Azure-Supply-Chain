# PostgreSQL Setup Guide - FoodONtracks

Quick reference guide for setting up PostgreSQL with Prisma.

## Prerequisites

✅ Node.js 20+ installed
✅ PostgreSQL 15+ installed

## Step-by-Step Setup

### 1. Install PostgreSQL (Windows)

1. Download from: https://www.postgresql.org/download/windows/
2. Run the installer
3. Set password for `postgres` user (remember it!)
4. Use default port: 5432
5. Complete installation

### 2. Verify PostgreSQL Installation

```bash
psql --version
# Expected output: psql (PostgreSQL) 15.x
```

### 3. Create Database

**Option A: Using psql**
```bash
# Open PostgreSQL command line
psql -U postgres

# Create database
CREATE DATABASE foodontracks;

# Verify
\l

# Exit
\q
```

**Option B: Using pgAdmin**
- Open pgAdmin (installed with PostgreSQL)
- Right-click "Databases" → Create → Database
- Name: `foodontracks`
- Save

### 4. Update Environment Variables

Navigate to foodontracks folder and edit `.env`:

```bash
cd foodontracks
```

Edit `.env` file:
```env
DATABASE_URL="postgresql://postgres:YOUR_PASSWORD@localhost:5432/foodontracks?schema=public"
```

**Important:** Replace `YOUR_PASSWORD` with the password you set during PostgreSQL installation.

### 5. Install Dependencies

```bash
npm install
```

This installs:
- @prisma/client
- prisma
- bcrypt (for password hashing)
- ts-node (for running seed script)

### 6. Generate Prisma Client

```bash
npx prisma generate
```

This generates TypeScript types from your schema.

### 7. Run Database Migrations

```bash
npm run db:migrate
```

Or:
```bash
npx prisma migrate dev --name init_schema
```

**What happens:**
- Creates all 10 tables
- Sets up foreign keys
- Creates indexes
- Applies constraints

**Expected output:**
```
✔ Generated Prisma Client
✔ Applied migration(s): init_schema
```

### 8. Seed Database

```bash
npm run db:seed
```

**What gets seeded:**
- 3 Users (customers and admin)
- 2 Addresses
- 3 Restaurants
- 8 Menu Items
- 2 Delivery Persons
- 2 Orders
- 4 Order Items
- 5 Tracking Events
- 2 Payments
- 1 Review

**Expected output:**
```
🌱 Starting database seeding...
✅ Cleared existing data
✅ Created 3 users
✅ Created 2 addresses
✅ Created 3 restaurants
✅ Created 8 menu items
✅ Created 2 delivery persons
✅ Created 2 orders
✅ Created 4 order items
✅ Created 5 tracking events
✅ Created 2 payments
✅ Created 1 reviews

🎉 Database seeding completed successfully!
```

### 9. View Database

```bash
npm run db:studio
```

Opens Prisma Studio at http://localhost:5555

You can:
- Browse all tables
- View/edit records
- Run queries
- Export data

### 10. Verify Setup

Open Prisma Studio and check:
- [ ] User table has 3 records
- [ ] Restaurant table has 3 records
- [ ] Order table has 2 records
- [ ] All foreign keys are properly linked

## Common Commands

```bash
# Run migrations
npm run db:migrate

# Open Prisma Studio
npm run db:studio

# Seed database
npm run db:seed

# Reset database (CAUTION: Deletes all data)
npm run db:reset

# Pull existing schema
npx prisma db pull

# Format schema file
npx prisma format

# View migration status
npx prisma migrate status
```

## Troubleshooting

### Error: "Connection refused"

**Cause:** PostgreSQL service not running

**Solution:**
```bash
# Windows: Start PostgreSQL service
net start postgresql-x64-15

# Or use Services app (services.msc)
# Find "postgresql-x64-15" and start it
```

### Error: "Database does not exist"

**Solution:**
```bash
psql -U postgres
CREATE DATABASE foodontracks;
\q
```

### Error: "Password authentication failed"

**Solution:**
- Check your `.env` file
- Ensure `DATABASE_URL` has correct password
- Try connecting with psql to verify password

### Error: "Port 5432 is already in use"

**Solution:**
- Another PostgreSQL instance is running
- Change port in PostgreSQL config
- Or stop the conflicting service

### Error: "Migration failed"

**Solution:**
```bash
# Reset database and try again
npm run db:reset

# Or manually drop and recreate
psql -U postgres
DROP DATABASE foodontracks;
CREATE DATABASE foodontracks;
\q

# Then run migrations again
npm run db:migrate
```

### Seed script fails with bcrypt error

**Solution:**
```bash
# Reinstall bcrypt
npm uninstall bcrypt
npm install bcrypt

# Try seed again
npm run db:seed
```

## Database Connection Strings

### Local Development
```
postgresql://postgres:password@localhost:5432/foodontracks?schema=public
```

### Docker Container
```
postgresql://postgres:password@db:5432/foodontracks?schema=public
```
(Note: Use service name `db` instead of `localhost`)

### Remote Database (Example)
```
postgresql://user:password@db.example.com:5432/foodontracks?schema=public&sslmode=require
```

## Next Steps

After successful setup:

1. ✅ Database is ready
2. ✅ Sample data is loaded
3. 📝 Start building API routes in `app/api/`
4. 🔐 Implement authentication
5. 🍕 Create restaurant and menu pages
6. 🛒 Build order flow
7. 📍 Add real-time tracking

## Resources

- **Prisma Docs:** https://www.prisma.io/docs
- **PostgreSQL Docs:** https://www.postgresql.org/docs/
- **Schema Documentation:** See `DATABASE_SCHEMA.md`
- **ER Diagram:** See `DATABASE_SCHEMA.md`

## Support

If you encounter issues:
1. Check troubleshooting section above
2. Verify PostgreSQL is running
3. Check `.env` configuration
4. Review error messages carefully
5. Consult `DATABASE_SCHEMA.md` for schema details
