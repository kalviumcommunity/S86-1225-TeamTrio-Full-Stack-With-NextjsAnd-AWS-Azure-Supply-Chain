import { z } from "zod";

export const createRestaurantSchema = z.object({
  name: z.string().min(2, "Restaurant name must be at least 2 characters long").max(100, "Name must not exceed 100 characters"),
  email: z.string().email("Invalid email address"),
  phoneNumber: z.string().regex(/^[0-9\-\+\(\)]+$/, "Invalid phone number format"),
  description: z.string().optional().nullable(),
  address: z.string().min(5, "Address must be at least 5 characters long").max(200, "Address must not exceed 200 characters"),
  city: z.string().min(2, "City must be at least 2 characters long").max(50, "City must not exceed 50 characters"),
  state: z.string().min(2, "State must be at least 2 characters long").max(50, "State must not exceed 50 characters"),
  zipCode: z.string().regex(/^[0-9\-]+$/, "Invalid zip code format").max(10, "Zip code must not exceed 10 characters"),
});

export const updateRestaurantSchema = z.object({
  name: z.string().min(2, "Restaurant name must be at least 2 characters long").max(100, "Name must not exceed 100 characters").optional(),
  email: z.string().email("Invalid email address").optional(),
  phoneNumber: z.string().regex(/^[0-9\-\+\(\)]+$/, "Invalid phone number format").optional(),
  description: z.string().optional().nullable(),
  address: z.string().min(5, "Address must be at least 5 characters long").max(200, "Address must not exceed 200 characters").optional(),
  city: z.string().min(2, "City must be at least 2 characters long").max(50, "City must not exceed 50 characters").optional(),
  state: z.string().min(2, "State must be at least 2 characters long").max(50, "State must not exceed 50 characters").optional(),
  zipCode: z.string().regex(/^[0-9\-]+$/, "Invalid zip code format").max(10, "Zip code must not exceed 10 characters").optional(),
  isActive: z.boolean().optional(),
});

export type CreateRestaurantInput = z.infer<typeof createRestaurantSchema>;
export type UpdateRestaurantInput = z.infer<typeof updateRestaurantSchema>;
