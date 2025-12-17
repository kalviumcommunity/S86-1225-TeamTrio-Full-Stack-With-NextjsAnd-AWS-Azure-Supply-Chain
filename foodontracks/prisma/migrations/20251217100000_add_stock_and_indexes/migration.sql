-- Add stock column to MenuItem
ALTER TABLE "MenuItem" ADD COLUMN IF NOT EXISTS "stock" INTEGER NOT NULL DEFAULT 100;

-- Add index on MenuItem name for faster lookups by name
CREATE INDEX IF NOT EXISTS "MenuItem_name_idx" ON "MenuItem"("name");

-- Add composite index on Order(userId, createdAt) for user timeline queries
CREATE INDEX IF NOT EXISTS "Order_userId_createdAt_idx" ON "Order"("userId", "createdAt");
