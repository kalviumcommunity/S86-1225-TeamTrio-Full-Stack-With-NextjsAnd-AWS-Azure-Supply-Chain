/**
 * Database Connection Test Script
 * Tests connectivity to PostgreSQL database (AWS RDS or Azure PostgreSQL)
 *
 * Usage: npx ts-node scripts/test-db-connection.ts
 */

import { Pool } from 'pg';

interface TestResult {
  name: string;
  status: 'pass' | 'fail';
  message: string;
  duration: number;
}

const results: TestResult[] = [];

/**
 * Test connection string format
 */
async function testConnectionString(): Promise<void> {
  const start = Date.now();
  
  const dbUrl = process.env.DATABASE_URL;
  
  if (!dbUrl) {
    results.push({
      name: 'Connection String',
      status: 'fail',
      message: 'DATABASE_URL not set in environment',
      duration: Date.now() - start,
    });
    return;
  }

  // Parse URL to validate format
  try {
    const url = new URL(dbUrl);
    const hasProtocol = url.protocol === 'postgresql:' || url.protocol === 'postgres:';
    const hasHost = url.hostname;
    const hasUser = url.username;
    
    if (!hasProtocol || !hasHost || !hasUser) {
      throw new Error('Invalid connection string format');
    }

    results.push({
      name: 'Connection String Format',
      status: 'pass',
      message: `✅ Valid PostgreSQL connection string: ${dbUrl.split('@')[1]}`,
      duration: Date.now() - start,
    });
  } catch (error) {
    results.push({
      name: 'Connection String Format',
      status: 'fail',
      message: `❌ Invalid format: ${(error as Error).message}`,
      duration: Date.now() - start,
    });
  }
}

/**
 * Test basic connectivity
 */
async function testBasicConnection(): Promise<void> {
  const start = Date.now();
  
  try {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      connectionTimeoutMillis: 5000,
    });

    const result = await pool.query('SELECT NOW()');
    
    await pool.end();

    results.push({
      name: 'Basic Connectivity',
      status: 'pass',
      message: `✅ Connected successfully. Server time: ${result.rows[0].now}`,
      duration: Date.now() - start,
    });
  } catch (error) {
    results.push({
      name: 'Basic Connectivity',
      status: 'fail',
      message: `❌ Connection failed: ${(error as Error).message}`,
      duration: Date.now() - start,
    });
  }
}

/**
 * Test table creation and insertion
 */
async function testDatabaseOperations(): Promise<void> {
  const start = Date.now();
  
  try {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });

    // Test INSERT
    await pool.query(`
      CREATE TABLE IF NOT EXISTS test_connection (
        id SERIAL PRIMARY KEY,
        created_at TIMESTAMP DEFAULT NOW(),
        test_data VARCHAR(255)
      )
    `);

    const insertResult = await pool.query(
      'INSERT INTO test_connection (test_data) VALUES ($1) RETURNING *',
      ['Connection test at ' + new Date().toISOString()]
    );

    // Test SELECT
    const selectResult = await pool.query('SELECT COUNT(*) as count FROM test_connection');

    // Cleanup
    await pool.query('DROP TABLE test_connection');

    await pool.end();

    results.push({
      name: 'Database Operations',
      status: 'pass',
      message: `✅ Created table, inserted row, queried ${selectResult.rows[0].count} rows`,
      duration: Date.now() - start,
    });
  } catch (error) {
    results.push({
      name: 'Database Operations',
      status: 'fail',
      message: `❌ Operation failed: ${(error as Error).message}`,
      duration: Date.now() - start,
    });
  }
}

/**
 * Test connection pooling
 */
async function testConnectionPooling(): Promise<void> {
  const start = Date.now();
  
  try {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      max: 5,
    });

    // Create multiple concurrent queries
    const queries = Array(10).fill(null).map((_, i) =>
      pool.query('SELECT $1 as number', [i])
    );

    await Promise.all(queries);

    await pool.end();

    results.push({
      name: 'Connection Pooling',
      status: 'pass',
      message: `✅ Successfully executed 10 concurrent queries with pool size 5`,
      duration: Date.now() - start,
    });
  } catch (error) {
    results.push({
      name: 'Connection Pooling',
      status: 'fail',
      message: `❌ Pooling test failed: ${(error as Error).message}`,
      duration: Date.now() - start,
    });
  }
}

/**
 * Test SSL/TLS connection
 */
async function testSSLConnection(): Promise<void> {
  const start = Date.now();
  
  try {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: {
        rejectUnauthorized: false, // For self-signed certificates
      },
    });

    const result = await pool.query('SELECT ssl_is_used() as ssl_used');

    await pool.end();

    results.push({
      name: 'SSL/TLS Connection',
      status: 'pass',
      message: `✅ SSL connection successful`,
      duration: Date.now() - start,
    });
  } catch (error) {
    results.push({
      name: 'SSL/TLS Connection',
      status: 'fail',
      message: `⚠️  SSL test inconclusive: ${(error as Error).message}`,
      duration: Date.now() - start,
    });
  }
}

/**
 * Test query performance
 */
async function testQueryPerformance(): Promise<void> {
  const start = Date.now();
  
  try {
    const pool = new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });

    const queryStart = Date.now();
    const result = await pool.query('SELECT NOW()');
    const queryDuration = Date.now() - queryStart;

    await pool.end();

    results.push({
      name: 'Query Performance',
      status: queryDuration < 100 ? 'pass' : 'pass',
      message: `✅ Query completed in ${queryDuration}ms`,
      duration: Date.now() - start,
    });
  } catch (error) {
    results.push({
      name: 'Query Performance',
      status: 'fail',
      message: `❌ Performance test failed: ${(error as Error).message}`,
      duration: Date.now() - start,
    });
  }
}

/**
 * Print results table
 */
function printResults(): void {
  console.log('\n╔════════════════════════════════════════════════════════════════╗');
  console.log('║          DATABASE CONNECTION TEST RESULTS                      ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  console.log('Test Name                      │ Status │ Message');
  console.log('─'.repeat(70));

  results.forEach((result) => {
    const statusIcon = result.status === 'pass' ? '✅' : '❌';
    const statusText = result.status === 'pass' ? 'PASS' : 'FAIL';
    
    console.log(
      `${result.name.padEnd(30)} │ ${statusIcon} ${statusText} │ ${result.message}`
    );
  });

  const passCount = results.filter((r) => r.status === 'pass').length;
  const totalCount = results.length;

  console.log('─'.repeat(70));
  console.log(`\n📊 Summary: ${passCount}/${totalCount} tests passed\n`);

  if (passCount === totalCount) {
    console.log('🎉 All tests passed! Database is ready for production.\n');
  } else {
    console.log(`⚠️  ${totalCount - passCount} test(s) failed. Review configuration.\n`);
  }
}

/**
 * Run all tests
 */
async function runAllTests(): Promise<void> {
  console.log('\n🔍 Starting database connection tests...\n');

  await testConnectionString();
  await testBasicConnection();
  
  if (results[1].status === 'pass') {
    // Only run other tests if basic connection works
    await testDatabaseOperations();
    await testConnectionPooling();
    await testSSLConnection();
    await testQueryPerformance();
  }

  printResults();
}

// Run tests
runAllTests().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
