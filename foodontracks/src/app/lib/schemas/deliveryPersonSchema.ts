import { z } from "zod";

export const createDeliveryPersonSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters long").max(100, "Name must not exceed 100 characters"),
  email: z.string().email("Invalid email address"),
  phoneNumber: z.string().regex(/^[0-9\-\+\(\)]+$/, "Invalid phone number format"),
  vehicleType: z.string().min(1, "Vehicle type is required").max(50, "Vehicle type must not exceed 50 characters"),
  vehicleNumber: z.string().min(1, "Vehicle number is required").max(20, "Vehicle number must not exceed 20 characters"),
  isAvailable: z.boolean().optional().default(true),
});

export const updateDeliveryPersonSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters long").max(100, "Name must not exceed 100 characters").optional(),
  email: z.string().email("Invalid email address").optional(),
  phoneNumber: z.string().regex(/^[0-9\-\+\(\)]+$/, "Invalid phone number format").optional(),
  vehicleType: z.string().min(1, "Vehicle type is required").max(50, "Vehicle type must not exceed 50 characters").optional(),
  vehicleNumber: z.string().min(1, "Vehicle number is required").max(20, "Vehicle number must not exceed 20 characters").optional(),
  isAvailable: z.boolean().optional(),
});

export type CreateDeliveryPersonInput = z.infer<typeof createDeliveryPersonSchema>;
export type UpdateDeliveryPersonInput = z.infer<typeof updateDeliveryPersonSchema>;
