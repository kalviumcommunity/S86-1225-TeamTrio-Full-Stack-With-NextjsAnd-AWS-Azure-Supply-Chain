#!/bin/bash
# Cloud Database Configuration Guide - AWS RDS & Azure PostgreSQL

## Overview
This guide covers provisioning and configuring managed PostgreSQL databases using AWS RDS or Azure Database for PostgreSQL for the FoodONtracks application.

---

## 📋 Prerequisites

### For AWS RDS:
- AWS Account with billing enabled
- IAM permissions for RDS
- Security Group management access
- AWS Management Console access

### For Azure PostgreSQL:
- Azure Subscription with active billing
- Appropriate RBAC roles
- Azure Portal access
- Virtual network access (optional for private endpoints)

---

## 🔧 Configuration Options

### AWS RDS PostgreSQL
- Engine: PostgreSQL 13+
- Instance Class: db.t3.micro (free tier eligible)
- Storage: 20GB (free tier eligible)
- Backup Retention: 7 days
- Multi-AZ: No (development)

### Azure PostgreSQL
- Tier: Basic / Free trial (development)
- Compute: 1 vCore
- Storage: 5GB minimum
- Backup Retention: 7 days
- Network: Allow Azure services (development)

---

## 🛠️ Environment Configuration

### .env.local Template
```bash
# Database Configuration
DATABASE_URL="postgresql://username:password@host:5432/database_name"
DB_HOST="your-db-endpoint.region.rds.amazonaws.com"
DB_PORT="5432"
DB_NAME="foodontracks_db"
DB_USER="admin"
DB_PASSWORD="YourStrongPassword123!"
DB_SSL_ENABLED="true"

# AWS RDS Specific
AWS_RDS_ENDPOINT="nextjs-db.c7h8p2j5.us-east-1.rds.amazonaws.com"
AWS_RDS_REGION="us-east-1"

# Azure PostgreSQL Specific
AZURE_POSTGRES_SERVER="nextjs-db-server.postgres.database.azure.com"
AZURE_POSTGRES_REGION="eastus"
```

---

## 🌐 Network Configuration

### AWS RDS - Security Group Rules
```
Type: PostgreSQL
Protocol: TCP
Port Range: 5432
Source: Your IP / Application Server IP
Description: PostgreSQL database access
```

### Azure PostgreSQL - Firewall Rules
```
Rule Name: AllowAppServer
Start IP: Your.App.Server.IP
End IP: Your.App.Server.IP
Description: Allow application server access
```

---

## ✅ Connection Testing

### Method 1: Using psql CLI
```bash
# Install psql (if not available)
# macOS: brew install libpq
# Ubuntu: sudo apt-get install postgresql-client

# Test connection
psql -h your-db-endpoint.rds.amazonaws.com \
     -U admin \
     -d foodontracks_db \
     -p 5432

# From database console:
SELECT NOW();  -- Should return current timestamp
```

### Method 2: Using Node.js
```javascript
// test-db-connection.js
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }
});

async function testConnection() {
  try {
    const result = await pool.query('SELECT NOW()');
    console.log('✅ Database connected:', result.rows[0]);
  } catch (error) {
    console.error('❌ Connection failed:', error.message);
  } finally {
    await pool.end();
  }
}

testConnection();
```

Run: `node test-db-connection.js`

### Method 3: Using Prisma
```bash
# Add to prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

# Test connection
npx prisma db pull
npx prisma db push
npx prisma studio
```

---

## 🔐 Security Best Practices

### 1. Restrict Network Access
**Development:**
- ✅ Allow specific IPs only
- ✅ Use VPC security groups
- ❌ Never use 0.0.0.0/0 (public to all)

**Production:**
- ✅ Use private endpoints (AWS PrivateLink / Azure Private Link)
- ✅ Only allow from application VPC
- ✅ Enable SSL/TLS enforced
- ✅ Implement database firewall rules

### 2. Credentials Management
```javascript
// ✅ CORRECT: Use environment variables
const dbUrl = process.env.DATABASE_URL;

// ❌ WRONG: Hardcoded credentials
const dbUrl = "postgresql://admin:password@host:5432/db";

// ✅ BEST: Use Prisma with env variables
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

### 3. SSL/TLS Configuration
```javascript
// Enable SSL for production
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production'
    ? { rejectUnauthorized: false }
    : false
});
```

### 4. Connection Pooling
```javascript
// Implement connection pooling for performance
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20,                    // max clients
  idleTimeoutMillis: 30000,   // 30 seconds
  connectionTimeoutMillis: 5000
});
```

---

## 📊 Backup Strategy

### AWS RDS Backups
1. **Automated Backups**
   - Retention Period: 7 days (minimum)
   - Backup Window: Off-peak hours (e.g., 03:00-04:00 UTC)
   - Backup Type: Automated snapshots

2. **Manual Snapshots**
   ```bash
   # Via AWS CLI
   aws rds create-db-snapshot \
     --db-instance-identifier nextjs-db \
     --db-snapshot-identifier manual-backup-$(date +%Y%m%d)
   ```

3. **Point-in-Time Recovery**
   - Enabled by default with automated backups
   - Recoverable to any point in retention period

### Azure PostgreSQL Backups
1. **Automatic Backups**
   - Retention: 7 days (minimum)
   - Frequency: Daily full backup + transaction logs every 5 minutes
   - Geo-redundant backup option available

2. **Manual Backups**
   - Via Azure Portal: Export to bacpac
   - Via Azure CLI: `az postgres server backup`

3. **Restore Options**
   - Point-in-time restore (within retention period)
   - Geo-restore (if enabled)

---

## 📈 Scaling Strategy

### Vertical Scaling (Instance Size)
```
Development:  db.t3.micro (1 GB RAM)
  ↓
Staging:      db.t3.small (2 GB RAM)
  ↓
Production:   db.t3.medium+ (4+ GB RAM)
```

### Horizontal Scaling (Read Replicas)
```javascript
// AWS RDS Read Replica
- Create read replica in same or different region
- Use read replica for analytics queries
- Keep primary for writes

// Azure Replica
- Server replica feature for read scaling
- Better for geographic distribution
```

---

## 🔄 Connection Resilience

### Retry Logic
```javascript
async function executeQuery(query, retries = 3) {
  for (let i = 0; i < retries; i++) {
    try {
      return await pool.query(query);
    } catch (error) {
      if (i < retries - 1) {
        await new Promise(r => setTimeout(r, 1000 * (i + 1)));
        continue;
      }
      throw error;
    }
  }
}
```

### Connection Pooling
```javascript
// Use pgBouncer for additional pooling layer
// Config: pgbouncer.ini
[databases]
foodontracks_db = host=your-rds-endpoint.amazonaws.com port=5432 user=admin password=password

[pgbouncer]
pool_mode = transaction
max_client_conn = 1000
default_pool_size = 25
```

---

## 📊 Monitoring & Alerting

### AWS CloudWatch Metrics
- **CPU Utilization**: Alert if > 80%
- **Database Connections**: Alert if > 80% of max
- **Disk Space**: Alert if < 10% remaining
- **Read/Write Latency**: Alert if > 100ms
- **Storage Space**: Alert if > 80% used

### Azure Monitor
- **CPU Percentage**: Alert if > 80%
- **Memory Percentage**: Alert if > 90%
- **Storage Percent**: Alert if > 80%
- **Active Connections**: Track trends
- **Failed Connections**: Alert on spikes

### Setup Alerts
```bash
# AWS CloudWatch Alarm
aws cloudwatch put-metric-alarm \
  --alarm-name rds-high-cpu \
  --alarm-description "Alert when RDS CPU is high" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold
```

---

## 💰 Cost Estimation

### AWS RDS (us-east-1)
```
db.t3.micro:      ~$15/month (free tier eligible)
Storage (20 GB):  ~$2.30/month
Backup (7 days):  Included
Data Transfer:    Free (same region)
─────────────────────────────
Estimated Total:  ~$17.30/month
```

### Azure PostgreSQL (Basic Tier)
```
Compute (1 vCore):    ~$25/month
Storage (5 GB):       ~$0.12/month
Backup (7 days):      Included
Data Transfer:        Free (Azure services)
─────────────────────────────
Estimated Total:      ~$25.12/month
```

---

## 🚀 Production Deployment Checklist

- [ ] Database provisioned in cloud account
- [ ] Security groups/firewall rules configured
- [ ] SSL/TLS enabled
- [ ] Automated backups enabled (7+ day retention)
- [ ] Read replicas configured (optional, for scaling)
- [ ] Monitoring and alerting set up
- [ ] Connection pooling implemented
- [ ] Environment variables configured
- [ ] Database tested from app server
- [ ] Database tested from admin client
- [ ] Disaster recovery plan documented
- [ ] Compliance requirements verified
- [ ] Cost monitoring configured

---

## 🔄 Disaster Recovery Plan

### Backup Schedule
- Daily automated backups (minimum)
- Weekly manual snapshots
- Monthly cross-region backups

### Recovery Time Objectives (RTO)
- Development: 24 hours (non-critical)
- Staging: 4 hours
- Production: 1 hour

### Recovery Point Objectives (RPO)
- Development: 24 hours
- Staging: 6 hours
- Production: 1 hour (use transaction logs)

### Failover Strategy
1. **Automated Failover**
   - Multi-AZ deployment (AWS)
   - Automatic health checks
   - < 2 minute failover time

2. **Manual Failover**
   - Promote read replica to primary
   - Update connection strings
   - Monitor application behavior

---

## 📚 Additional Resources

### AWS RDS
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [RDS Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.html)
- [RDS Security](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.html)

### Azure PostgreSQL
- [Azure PostgreSQL Docs](https://learn.microsoft.com/en-us/azure/postgresql/)
- [Security Best Practices](https://learn.microsoft.com/en-us/azure/postgresql/single-server/concepts-security)
- [Backup and Recovery](https://learn.microsoft.com/en-us/azure/postgresql/single-server/concepts-backup)

### PostgreSQL
- [PostgreSQL Official](https://www.postgresql.org/)
- [pgAdmin Web Interface](https://www.pgadmin.org/)
- [psql Command Reference](https://www.postgresql.org/docs/current/app-psql.html)

---

## 🧪 Troubleshooting

### Connection Refused
```
Error: connect ECONNREFUSED
Causes:
- Database not running
- Wrong host/port
- Security group blocks traffic
- Network connectivity issue

Solution:
1. Verify database status in console
2. Check security group rules
3. Test with public IP first
4. Verify credentials
```

### SSL Certificate Error
```
Error: CERTIFICATE_VERIFY_FAILED
Solution:
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false }  // Development only
});
```

### Too Many Connections
```
Error: FATAL: too many connections
Solution:
1. Increase max_connections in RDS parameter group
2. Implement connection pooling (pgBouncer)
3. Use Prisma connection pooling
4. Review long-running transactions
```

---

**Last Updated:** December 30, 2025
**Status:** Complete
**Next Steps:** Follow AWS RDS or Azure PostgreSQL setup section in README.md
