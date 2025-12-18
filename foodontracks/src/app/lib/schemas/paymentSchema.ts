import { z } from "zod";

export const paymentMethodEnum = z.enum([
  "CREDIT_CARD",
  "DEBIT_CARD",
  "UPI",
  "CASH_ON_DELIVERY",
  "WALLET",
]);

export const paymentStatusEnum = z.enum([
  "PENDING",
  "COMPLETED",
  "FAILED",
  "REFUNDED",
]);

export const createPaymentSchema = z.object({
  orderId: z.number().int().positive("Order ID must be a positive integer"),
  amount: z.number().positive("Amount must be greater than 0").max(999999.99, "Amount must not exceed 999999.99"),
  paymentMethod: paymentMethodEnum,
  transactionId: z.string().min(1, "Transaction ID is required").max(100, "Transaction ID must not exceed 100 characters"),
});

export const updatePaymentSchema = z.object({
  status: paymentStatusEnum.optional(),
  transactionId: z.string().min(1, "Transaction ID is required").max(100, "Transaction ID must not exceed 100 characters").optional(),
});

export type CreatePaymentInput = z.infer<typeof createPaymentSchema>;
export type UpdatePaymentInput = z.infer<typeof updatePaymentSchema>;
