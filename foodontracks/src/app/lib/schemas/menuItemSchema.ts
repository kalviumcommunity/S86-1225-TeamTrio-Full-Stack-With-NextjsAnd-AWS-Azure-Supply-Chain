import { z } from "zod";

export const createMenuItemSchema = z.object({
  restaurantId: z.number().int().positive("Restaurant ID must be a positive integer"),
  name: z.string().min(2, "Menu item name must be at least 2 characters long").max(100, "Name must not exceed 100 characters"),
  description: z.string().optional().nullable(),
  price: z.number().positive("Price must be greater than 0").max(9999.99, "Price must not exceed 9999.99"),
  category: z.string().min(1, "Category is required").max(50, "Category must not exceed 50 characters"),
  imageUrl: z.string().url("Invalid image URL").optional().nullable(),
  isAvailable: z.boolean().optional().default(true),
  preparationTime: z.number().int().positive("Preparation time must be greater than 0").max(999, "Preparation time must not exceed 999 minutes"),
  stock: z.number().int().nonnegative("Stock cannot be negative").optional().default(100),
});

export const updateMenuItemSchema = z.object({
  name: z.string().min(2, "Menu item name must be at least 2 characters long").max(100, "Name must not exceed 100 characters").optional(),
  description: z.string().optional().nullable(),
  price: z.number().positive("Price must be greater than 0").max(9999.99, "Price must not exceed 9999.99").optional(),
  category: z.string().min(1, "Category is required").max(50, "Category must not exceed 50 characters").optional(),
  imageUrl: z.string().url("Invalid image URL").optional().nullable(),
  isAvailable: z.boolean().optional(),
  preparationTime: z.number().int().positive("Preparation time must be greater than 0").max(999, "Preparation time must not exceed 999 minutes").optional(),
  stock: z.number().int().nonnegative("Stock cannot be negative").optional(),
});

export type CreateMenuItemInput = z.infer<typeof createMenuItemSchema>;
export type UpdateMenuItemInput = z.infer<typeof updateMenuItemSchema>;
