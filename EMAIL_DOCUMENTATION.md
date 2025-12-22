# Transactional Email Implementation Guide

## Overview

FoodONtracks uses AWS SES (Simple Email Service) for sending transactional emails. These are automated, trigger-based emails sent in response to user actions like signup, order placement, password reset, etc.

## Architecture

```
User Action → API Endpoint → Email Service → AWS SES → Recipient
     ↓              ↓               ↓            ↓
  (Signup)    (POST /api/email)  (Template)  (Delivery)
```

## Setup Instructions

### 1. AWS SES Configuration

#### Verify Email Address (Sandbox Mode)
1. Go to AWS Console → SES
2. Select "Email Addresses" under "Identity Management"
3. Click "Verify a New Email Address"
4. Enter your sender email (e.g., `noreply@foodontracks.com`)
5. Check inbox and click verification link
6. **Important**: Also verify recipient emails while in sandbox mode

#### Request Production Access (Optional)
- SES starts in sandbox mode (limited to verified emails)
- To send to any email, request production access:
  1. Go to SES → Account Dashboard
  2. Click "Request production access"
  3. Fill out form explaining use case
  4. Wait for approval (usually 24 hours)

#### Configure Environment Variables
Add to `.env`:
```env
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=ap-south-1
SES_EMAIL_SENDER=noreply@foodontracks.com
SES_REPLY_TO=support@foodontracks.com
```

### 2. Install Dependencies

```bash
cd foodontracks
npm install @aws-sdk/client-ses
```

## Email Templates

### Available Templates

1. **Welcome Email** - Sent when user signs up
2. **Order Confirmation** - Sent after order placement
3. **Password Reset** - Sent for password recovery
4. **Order Status Update** - Sent when order status changes
5. **Payment Confirmation** - Sent after successful payment
6. **Generic Notification** - For custom notifications

### Template Examples

#### Welcome Email
```typescript
{
  template: "welcome",
  templateData: {
    userName: "John Doe",
    userEmail: "john@example.com"
  }
}
```

#### Order Confirmation
```typescript
{
  template: "order-confirmation",
  templateData: {
    userName: "John Doe",
    orderNumber: "ORD-2025-001",
    totalAmount: 450.00,
    deliveryAddress: "123 Main St, Mumbai",
    estimatedDelivery: "30-45 minutes",
    orderItems: [
      { name: "Butter Chicken", quantity: 2, price: 180.00 },
      { name: "Garlic Naan", quantity: 3, price: 30.00 }
    ]
  }
}
```

## API Usage

### Endpoint: POST /api/email

#### Send Email with Template
```bash
curl -X POST http://localhost:3000/api/email \
  -H "Content-Type: application/json" \
  -d '{
    "to": "user@example.com",
    "template": "welcome",
    "templateData": {
      "userName": "John Doe",
      "userEmail": "user@example.com"
    }
  }'
```

#### Send Custom HTML Email
```bash
curl -X POST http://localhost:3000/api/email \
  -H "Content-Type: application/json" \
  -d '{
    "to": "user@example.com",
    "subject": "Custom Subject",
    "message": "<h2>Hello!</h2><p>This is a custom email.</p>"
  }'
```

#### Response Format
```json
{
  "success": true,
  "message": "Email sent successfully",
  "data": {
    "messageId": "01010189b2c3d4e5-f6789abc-def0-1234-5678-9abcdef01234-000000",
    "to": "user@example.com",
    "subject": "Welcome to FoodONtracks!"
  }
}
```

### Endpoint: GET /api/email

Get email service configuration:
```bash
curl http://localhost:3000/api/email
```

Response:
```json
{
  "success": true,
  "data": {
    "provider": "AWS SES",
    "region": "ap-south-1",
    "sender": "noreply@foodontracks.com",
    "availableTemplates": [
      "welcome",
      "order-confirmation",
      "password-reset",
      "order-status",
      "payment-confirmation",
      "notification"
    ]
  }
}
```

## Integration Examples

### Send Welcome Email on Signup
```typescript
// In your signup API route
import { sendEmail } from "@/app/lib/emailService";
import { welcomeEmailTemplate } from "@/app/lib/emailTemplates";

// After user creation
await sendEmail({
  to: user.email,
  subject: "Welcome to FoodONtracks!",
  html: welcomeEmailTemplate({
    userName: user.name,
    userEmail: user.email
  })
});
```

### Send Order Confirmation
```typescript
// In your order creation API route
import { sendEmail } from "@/app/lib/emailService";
import { orderConfirmationEmailTemplate } from "@/app/lib/emailTemplates";

// After order placement
await sendEmail({
  to: order.user.email,
  subject: `Order Confirmed - ${order.orderNumber}`,
  html: orderConfirmationEmailTemplate({
    userName: order.user.name,
    orderNumber: order.orderNumber,
    totalAmount: order.totalAmount,
    deliveryAddress: order.address.fullAddress,
    orderItems: order.items.map(item => ({
      name: item.menuItem.name,
      quantity: item.quantity,
      price: item.priceAtTime
    }))
  })
});
```

### Send Order Status Update
```typescript
// In your order update API route
await sendEmail({
  to: order.user.email,
  subject: `Order Update - ${order.orderNumber}`,
  html: orderStatusEmailTemplate({
    userName: order.user.name,
    orderNumber: order.orderNumber,
    status: order.status,
    trackingLink: `https://foodontracks.com/track/${order.orderNumber}`
  })
});
```

## Testing

### Run Test Script
```powershell
cd foodontracks
.\test-email.ps1
```

This script tests:
- ✓ Configuration retrieval
- ✓ Welcome email
- ✓ Order confirmation
- ✓ Password reset
- ✓ Order status update
- ✓ Payment confirmation
- ✓ Custom HTML email

### Manual Testing with Postman

Import the request:
```json
{
  "method": "POST",
  "url": "http://localhost:3000/api/email",
  "headers": {
    "Content-Type": "application/json"
  },
  "body": {
    "to": "your-verified-email@example.com",
    "template": "welcome",
    "templateData": {
      "userName": "Test User",
      "userEmail": "your-verified-email@example.com"
    }
  }
}
```

## Error Handling

### Common Issues

#### 1. Email Not Delivered
**Symptoms**: API returns success but email not received

**Solutions**:
- Check spam/junk folder
- Verify recipient email in SES (if in sandbox mode)
- Check SES sending statistics in AWS Console
- Review bounce/complaint notifications

#### 2. MessageRejected Error
**Cause**: Email address not verified (sandbox mode)

**Solution**:
```bash
# Verify email in AWS Console
# OR request production access
```

#### 3. Rate Limit Exceeded
**Cause**: Sending too many emails too quickly

**Solution**:
- Implement queue system (Redis + Bull)
- Add delays between sends
- Request rate limit increase from AWS

#### 4. Invalid Sender
**Cause**: Sender email not verified

**Solution**:
- Verify sender email in AWS SES Console
- Update `SES_EMAIL_SENDER` in .env

## Best Practices

### 1. Email Design
- ✅ Use responsive HTML templates
- ✅ Include plain text alternative
- ✅ Keep subject lines concise (< 50 chars)
- ✅ Use clear call-to-action buttons
- ✅ Include unsubscribe link (for marketing emails)

### 2. Sending
- ✅ Validate email addresses before sending
- ✅ Use templates for consistency
- ✅ Log all sent emails for auditing
- ✅ Handle bounces and complaints
- ✅ Implement retry logic for failures

### 3. Security
- ✅ Never expose AWS credentials
- ✅ Use environment variables for config
- ✅ Validate input data
- ✅ Sanitize user-provided content in emails
- ✅ Use HTTPS for all links in emails

### 4. Performance
- ✅ Send emails asynchronously (don't block API responses)
- ✅ Use queuing for bulk emails
- ✅ Monitor sending limits
- ✅ Cache templates when possible

## Monitoring

### SES Metrics to Track
1. **Send Rate** - Emails sent per second
2. **Bounce Rate** - Percentage of emails that bounced
3. **Complaint Rate** - Percentage of spam complaints
4. **Delivery Rate** - Successful deliveries

### Access Metrics
- AWS Console → SES → Sending Statistics
- Or use AWS CloudWatch

### Set Up Alarms
```typescript
// Monitor bounce rate
if (bounceRate > 5%) {
  alert("High bounce rate detected!");
  // Pause sending
  // Review email list
}
```

## Cost Estimation

### AWS SES Pricing (Mumbai Region)
- **First 62,000 emails/month**: FREE (when sent from EC2)
- **Additional emails**: $0.10 per 1,000 emails
- **Attachments**: $0.12 per GB

### Example Costs
| Usage | Cost/Month |
|-------|------------|
| 10,000 emails | FREE |
| 100,000 emails | ~$3.80 |
| 1,000,000 emails | ~$93.80 |

**Much cheaper than SendGrid or Mailgun!**

## Alternative: SendGrid

If you prefer SendGrid over AWS SES:

1. **Install**: `npm install @sendgrid/mail`
2. **Get API Key**: https://sendgrid.com
3. **Update .env**:
```env
SENDGRID_API_KEY=your-api-key
SENDGRID_SENDER=noreply@foodontracks.com
```
4. **Use SendGrid service**: See `src/app/lib/sendgridService.ts`

### SendGrid vs AWS SES

| Feature | AWS SES | SendGrid |
|---------|---------|----------|
| Free Tier | 62,000/month | 100/day |
| Pricing | $0.10/1k | $15-19/month |
| Setup | Moderate | Easy |
| Templates | Custom | Built-in editor |
| Analytics | Basic | Advanced |

**Recommendation**: Use AWS SES for cost-effectiveness at scale.

## Sandbox vs Production

### Sandbox Mode Limitations
- ✅ Can only send to verified emails
- ✅ Maximum 200 emails per 24 hours
- ✅ 1 email per second
- ❌ Cannot send to unverified emails

### Production Mode Benefits
- ✅ Send to any email address
- ✅ Higher sending limits (adjustable)
- ✅ Better deliverability reputation
- ✅ Access to dedicated IPs (optional)

### Request Production Access
1. Go to SES Console → Account Dashboard
2. Click "Request Production Access"
3. Provide:
   - Use case description
   - Process for handling bounces
   - Compliance with anti-spam policies
4. Wait for approval (24-48 hours)

## Email Authentication

### SPF, DKIM, DMARC
To improve deliverability, configure:

1. **SPF** (Sender Policy Framework)
   - Add TXT record to DNS
   - Example: `v=spf1 include:amazonses.com ~all`

2. **DKIM** (DomainKeys Identified Mail)
   - AWS SES automatically signs emails
   - Add DKIM records to DNS

3. **DMARC** (Domain-based Message Authentication)
   - Add TXT record: `v=DMARC1; p=quarantine`

### Verify Domain
Instead of individual emails, verify your entire domain:
1. SES Console → Domains → Verify a New Domain
2. Add provided DNS records
3. Wait for verification
4. All emails from `@yourdomain.com` now work!

## Files Structure

```
foodontracks/
├── src/app/
│   ├── api/email/
│   │   └── route.ts          # Email API endpoint
│   └── lib/
│       ├── sesClient.ts       # AWS SES client
│       ├── emailService.ts    # Email sending logic
│       ├── emailTemplates.ts  # HTML templates
│       └── sendgridService.ts # Alternative (SendGrid)
├── test-email.ps1             # Testing script
└── .env                       # Configuration
```

## Summary

✅ **Implemented Features**:
- AWS SES integration
- 6 email templates
- Email API endpoint
- SendGrid alternative
- Testing script
- Error handling
- Type safety

✅ **Benefits**:
- Automated transactional emails
- Professional HTML templates
- Cost-effective ($0.10/1k emails)
- Scalable (millions of emails)
- Easy integration

✅ **Next Steps**:
1. Verify sender email in AWS SES
2. Update `.env` with credentials
3. Run test script
4. Integrate into signup/order flows
5. Request production access (when ready)

---

*Implementation completed: December 22, 2025*
