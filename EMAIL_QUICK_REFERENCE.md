# Transactional Email - Quick Reference

## 📧 Email Service Implementation Summary

### What Was Implemented

✅ **AWS SES Integration**
- SES client configuration
- Email sending service with error handling
- Support for HTML and plain text emails

✅ **6 Professional Email Templates**
1. Welcome Email (user signup)
2. Order Confirmation (with itemized details)
3. Password Reset (with secure link)
4. Order Status Update (real-time tracking)
5. Payment Confirmation (with receipt)
6. Generic Notification (custom messages)

✅ **API Endpoint**
- `POST /api/email` - Send emails
- `GET /api/email` - Get configuration
- Template-based or custom HTML
- Input validation and error handling

✅ **Testing Suite**
- PowerShell test script (`test-email.ps1`)
- Tests all templates and scenarios
- Comprehensive error checking

✅ **Documentation**
- Complete implementation guide
- Integration examples
- Troubleshooting guide
- Cost analysis

---

## 🚀 Quick Start (5 Minutes)

### 1. Configure AWS SES
```bash
# In AWS Console → SES
# 1. Verify sender email (e.g., noreply@foodontracks.com)
# 2. Verify recipient email (if in sandbox mode)
# 3. Get your AWS credentials
```

### 2. Update Environment Variables
```env
# Add to foodontracks/.env
SES_EMAIL_SENDER=noreply@foodontracks.com
SES_REPLY_TO=support@foodontracks.com
```

### 3. Test Email Service
```powershell
cd foodontracks
.\test-email.ps1
```

### 4. Integrate into Your Code
```typescript
import { sendEmail } from "@/app/lib/emailService";
import { welcomeEmailTemplate } from "@/app/lib/emailTemplates";

await sendEmail({
  to: "user@example.com",
  subject: "Welcome!",
  html: welcomeEmailTemplate({
    userName: "John Doe",
    userEmail: "user@example.com"
  })
});
```

---

## 📚 API Reference

### Send Email with Template
```bash
POST /api/email
Content-Type: application/json

{
  "to": "user@example.com",
  "template": "welcome",
  "templateData": {
    "userName": "John Doe",
    "userEmail": "user@example.com"
  }
}
```

### Send Custom HTML Email
```bash
POST /api/email
Content-Type: application/json

{
  "to": "user@example.com",
  "subject": "Custom Email",
  "message": "<h2>Hello!</h2><p>Custom content here.</p>"
}
```

### Get Configuration
```bash
GET /api/email
```

---

## 📋 Available Templates

| Template | Use Case | Data Required |
|----------|----------|---------------|
| `welcome` | User signup | `userName`, `userEmail` |
| `order-confirmation` | Order placed | `userName`, `orderNumber`, `totalAmount`, `orderItems`, `deliveryAddress` |
| `password-reset` | Forgot password | `userName`, `resetLink`, `expiryTime` |
| `order-status` | Status update | `userName`, `orderNumber`, `status`, `trackingLink` |
| `payment-confirmation` | Payment success | `userName`, `orderNumber`, `amount`, `paymentMethod`, `transactionId` |
| `notification` | Generic message | `subject`, `message`, `userName` |

---

## 🔧 File Structure

```
foodontracks/
├── src/app/
│   ├── api/email/
│   │   └── route.ts                    # Email API endpoint
│   └── lib/
│       ├── sesClient.ts                # AWS SES client config
│       ├── emailService.ts             # Email sending logic
│       ├── emailTemplates.ts           # HTML templates
│       ├── sendgridService.ts          # SendGrid alternative
│       └── emailIntegrationExamples.ts # Usage examples
├── test-email.ps1                      # Testing script
└── .env                                # Configuration
```

---

## 💡 Integration Examples

### Send Welcome Email on Signup
```typescript
// In auth/signup/route.ts
const user = await prisma.user.create({ data: userData });

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
// In orders/route.ts
const order = await prisma.order.create({
  data: orderData,
  include: { user: true, orderItems: true, address: true }
});

await sendEmail({
  to: order.user.email,
  subject: `Order Confirmed - ${order.orderNumber}`,
  html: orderConfirmationEmailTemplate({
    userName: order.user.name,
    orderNumber: order.orderNumber,
    totalAmount: order.totalAmount,
    deliveryAddress: `${order.address.addressLine1}, ${order.address.city}`,
    orderItems: order.orderItems.map(item => ({
      name: item.menuItem.name,
      quantity: item.quantity,
      price: item.priceAtTime
    }))
  })
});
```

### Send Status Update
```typescript
// In orders/[id]/route.ts
const order = await prisma.order.update({
  where: { id },
  data: { status: newStatus },
  include: { user: true }
});

await sendEmail({
  to: order.user.email,
  subject: `Order Update - ${order.orderNumber}`,
  html: orderStatusEmailTemplate({
    userName: order.user.name,
    orderNumber: order.orderNumber,
    status: order.status
  })
});
```

---

## ⚠️ Important Notes

### Sandbox Mode
- AWS SES starts in **sandbox mode**
- Can only send to **verified emails**
- Maximum **200 emails per 24 hours**
- **Solution**: Verify recipient emails OR request production access

### Request Production Access
1. Go to AWS Console → SES → Account Dashboard
2. Click "Request Production Access"
3. Explain your use case
4. Wait for approval (24-48 hours)

### Email Not Delivered?
✓ Check spam/junk folder
✓ Verify sender email in SES console
✓ Verify recipient email (if sandbox mode)
✓ Check SES sending statistics
✓ Review bounce/complaint notifications

---

## 💰 Cost Estimate

| Usage | Cost/Month |
|-------|------------|
| 10,000 emails | **FREE** |
| 100,000 emails | ~$3.80 |
| 1,000,000 emails | ~$93.80 |

**AWS SES Pricing**: $0.10 per 1,000 emails (after free tier)

---

## 🔒 Security Best Practices

✅ Verify all email addresses before sending
✅ Never expose AWS credentials in code
✅ Use environment variables for config
✅ Validate and sanitize user input
✅ Implement rate limiting
✅ Monitor bounce and complaint rates
✅ Handle errors gracefully

---

## 📊 Monitoring

### Check Email Statistics
1. AWS Console → SES → Sending Statistics
2. Monitor: Sends, Bounces, Complaints, Rejects
3. Set up CloudWatch alarms for issues

### Key Metrics
- **Bounce Rate**: Should be < 5%
- **Complaint Rate**: Should be < 0.1%
- **Delivery Rate**: Should be > 95%

---

## 🎯 Next Steps

1. ✅ Verify sender email in AWS SES Console
2. ✅ Update `.env` with your email address
3. ✅ Run `.\test-email.ps1` to test
4. ✅ Integrate into signup/order APIs
5. ✅ Monitor email statistics
6. ✅ Request production access (when ready)

---

## 📖 Full Documentation

For complete details, see:
- [EMAIL_DOCUMENTATION.md](../EMAIL_DOCUMENTATION.md) - Complete guide
- [emailIntegrationExamples.ts](../foodontracks/src/app/lib/emailIntegrationExamples.ts) - Code examples

---

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| "MessageRejected" error | Verify recipient email in SES |
| Email not delivered | Check spam folder, verify sender |
| Rate limit exceeded | Add delays, request limit increase |
| Invalid credentials | Check AWS keys in .env |
| Template not found | Use correct template name |

---

## 🎉 Success Checklist

- [ ] AWS SES configured
- [ ] Sender email verified
- [ ] Environment variables set
- [ ] Dependencies installed (`@aws-sdk/client-ses`)
- [ ] Test script passes
- [ ] Email received successfully
- [ ] Integrated into at least one API route

---

**Implementation completed: December 22, 2025**
**Ready for production use!** 🚀
