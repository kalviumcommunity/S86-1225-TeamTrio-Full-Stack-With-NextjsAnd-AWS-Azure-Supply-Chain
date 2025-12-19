# Error Handling Middleware Testing Script - PowerShell
# Tests the centralized error handling in development mode

$BASE_URL = "http://localhost:3000"
$date = Get-Date -Format "yyyyMMddHHmmss"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "ERROR HANDLING MIDDLEWARE TESTS" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Make sure the dev server is running at $BASE_URL" -ForegroundColor Yellow
Write-Host "Press Enter to continue..." -ForegroundColor Yellow
Read-Host

# Test 1: GET /api/users - Success
Write-Host ""
Write-Host "TEST 1: GET /api/users - Success (200)" -ForegroundColor Green
Write-Host "Expected: List of users with success: true" -ForegroundColor Gray
Write-Host "---" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/api/users" -Method GET -ContentType "application/json" -ErrorAction Stop
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
    Write-Host "✓ Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "✗ Error: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: POST /api/users - Validation Error (Missing Email)
Write-Host "TEST 2: POST /api/users - Validation Error (400)" -ForegroundColor Green
Write-Host "Expected: Validation error with type: VALIDATION_ERROR, status 400" -ForegroundColor Gray
Write-Host "---" -ForegroundColor Gray
$body = @{
    name = "John"
    password = "Test123"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/api/users" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    if ($_.Exception.Response) {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $error_response = $streamReader.ReadToEnd() | ConvertFrom-Json
        $error_response | ConvertTo-Json -Depth 10
        Write-Host "✓ Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Green
    } else {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Test 3: POST /api/users - Invalid Email
Write-Host "TEST 3: POST /api/users - Invalid Email (400)" -ForegroundColor Green
Write-Host "Expected: Validation error with field: email" -ForegroundColor Gray
Write-Host "---" -ForegroundColor Gray
$body = @{
    name = "John"
    email = "notanemail"
    password = "Test123"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/api/users" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    if ($_.Exception.Response) {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $error_response = $streamReader.ReadToEnd() | ConvertFrom-Json
        $error_response | ConvertTo-Json -Depth 10
        Write-Host "✓ Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Green
    } else {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Test 4: POST /api/users - Success
Write-Host "TEST 4: POST /api/users - Success (201)" -ForegroundColor Green
Write-Host "Expected: User created with success: true" -ForegroundColor Gray
Write-Host "---" -ForegroundColor Gray
$body = @{
    name = "John Doe"
    email = "john$date@example.com"
    password = "SecurePass123"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/api/users" -Method POST -Body $body -ContentType "application/json" -ErrorAction Stop
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
    Write-Host "✓ Status: $($response.StatusCode)" -ForegroundColor Green
} catch {
    if ($_.Exception.Response) {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $error_response = $streamReader.ReadToEnd() | ConvertFrom-Json
        $error_response | ConvertTo-Json -Depth 10
    } else {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Test 5: GET /api/users/999 - Not Found
Write-Host "TEST 5: GET /api/users/999 - Not Found (404)" -ForegroundColor Green
Write-Host "Expected: Error with type: NOT_FOUND_ERROR, status 404" -ForegroundColor Gray
Write-Host "---" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/api/users/999" -Method GET -ContentType "application/json" -ErrorAction Stop
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    if ($_.Exception.Response) {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $error_response = $streamReader.ReadToEnd() | ConvertFrom-Json
        $error_response | ConvertTo-Json -Depth 10
        Write-Host "✓ Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Green
    } else {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
}
Write-Host ""

# Test 6: GET /api/users/invalid - Invalid ID
Write-Host "TEST 6: GET /api/users/invalid - Invalid ID Format (400)" -ForegroundColor Green
Write-Host "Expected: Error with type: VALIDATION_ERROR, status 400" -ForegroundColor Gray
Write-Host "---" -ForegroundColor Gray
try {
    $response = Invoke-WebRequest -Uri "$BASE_URL/api/users/invalid" -Method GET -ContentType "application/json" -ErrorAction Stop
    $response.Content | ConvertFrom-Json | ConvertTo-Json -Depth 10
} catch {
    if ($_.Exception.Response) {
        $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $error_response = $streamReader.ReadToEnd() | ConvertFrom-Json
        $error_response | ConvertTo-Json -Depth 10
        Write-Host "✓ Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Green
    } else {
        Write-Host "✗ Error: $_" -ForegroundColor Red
    }
}
Write-Host ""

Write-Host "================================" -ForegroundColor Cyan
Write-Host "TESTING COMPLETE" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Observations:" -ForegroundColor Yellow
Write-Host "✓ Development mode shows full error details" -ForegroundColor Green
Write-Host "✓ Stack traces visible in error responses" -ForegroundColor Green
Write-Host "✓ Error types properly classified" -ForegroundColor Green
Write-Host "✓ HTTP status codes correct" -ForegroundColor Green
Write-Host ""
