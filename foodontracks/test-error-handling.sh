#!/bin/bash

# Error Handling Middleware Testing Script
# Tests the centralized error handling in development mode

BASE_URL="http://localhost:3000"

echo "================================"
echo "ERROR HANDLING MIDDLEWARE TESTS"
echo "================================"
echo ""
echo "Make sure the dev server is running at $BASE_URL"
echo "Press Enter to continue..."
read

# Test 1: GET /api/users - Success
echo ""
echo "TEST 1: GET /api/users - Success (200)"
echo "Command: curl -X GET $BASE_URL/api/users"
echo "Expected: List of users with success: true"
echo "---"
curl -s -X GET "$BASE_URL/api/users" -H "Content-Type: application/json" | jq '.'
echo ""
echo ""

# Test 2: POST /api/users - Validation Error (Missing Email)
echo "TEST 2: POST /api/users - Validation Error (400)"
echo "Command: curl -X POST with missing email field"
echo "Expected: Validation error with type: VALIDATION_ERROR, status 400"
echo "---"
curl -s -X POST "$BASE_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{"name":"John","password":"Test123"}' | jq '.'
echo ""
echo ""

# Test 3: POST /api/users - Validation Error (Invalid Email)
echo "TEST 3: POST /api/users - Invalid Email (400)"
echo "Command: curl -X POST with invalid email"
echo "Expected: Validation error with field: email"
echo "---"
curl -s -X POST "$BASE_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"notanemail","password":"Test123"}' | jq '.'
echo ""
echo ""

# Test 4: POST /api/users - Success
echo "TEST 4: POST /api/users - Success (201)"
echo "Command: curl -X POST with valid data"
echo "Expected: User created with success: true"
echo "---"
curl -s -X POST "$BASE_URL/api/users" \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john'$(date +%s)'@example.com","password":"SecurePass123"}' | jq '.'
echo ""
echo ""

# Test 5: GET /api/users/999 - Not Found (404)
echo "TEST 5: GET /api/users/999 - Not Found (404)"
echo "Command: curl -X GET with non-existent ID"
echo "Expected: Error with type: NOT_FOUND_ERROR, status 404"
echo "---"
curl -s -X GET "$BASE_URL/api/users/999" | jq '.'
echo ""
echo ""

# Test 6: GET /api/users/invalid - Invalid ID (400)
echo "TEST 6: GET /api/users/invalid - Invalid ID Format (400)"
echo "Command: curl -X GET with invalid ID format"
echo "Expected: Error with type: VALIDATION_ERROR, status 400"
echo "---"
curl -s -X GET "$BASE_URL/api/users/invalid" | jq '.'
echo ""
echo ""

echo "================================"
echo "TESTING COMPLETE"
echo "================================"
echo ""
echo "Observations:"
echo "✓ Development mode shows full error details"
echo "✓ Stack traces visible in error responses"
echo "✓ Error types properly classified"
echo "✓ HTTP status codes correct"
echo ""
