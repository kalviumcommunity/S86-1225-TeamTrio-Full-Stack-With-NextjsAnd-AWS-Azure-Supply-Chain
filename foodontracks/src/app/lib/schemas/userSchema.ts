import { z } from "zod";

export const userRoleEnum = z.enum(["CUSTOMER", "ADMIN", "RESTAURANT_OWNER"]);

export const createUserSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters long").max(100, "Name must not exceed 100 characters"),
  email: z.string().email("Invalid email address"),
  phoneNumber: z.string().optional().nullable(),
  password: z.string().min(6, "Password must be at least 6 characters long").max(100, "Password must not exceed 100 characters"),
  role: userRoleEnum.optional().default("CUSTOMER"),
});

export const updateUserSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters long").max(100, "Name must not exceed 100 characters").optional(),
  email: z.string().email("Invalid email address").optional(),
  phoneNumber: z.string().optional().nullable(),
  role: userRoleEnum.optional(),
});

export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
