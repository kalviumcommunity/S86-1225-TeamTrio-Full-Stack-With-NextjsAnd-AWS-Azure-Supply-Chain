import { SESClient } from "@aws-sdk/client-ses";

// Initialize SES client with credentials from environment variables
export const sesClient = new SESClient({
  region: process.env.AWS_REGION || "ap-south-1",
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!,
  },
});

export const SES_EMAIL_SENDER =
  process.env.SES_EMAIL_SENDER || "noreply@foodontracks.com";
export const SES_REPLY_TO =
  process.env.SES_REPLY_TO || "support@foodontracks.com";
