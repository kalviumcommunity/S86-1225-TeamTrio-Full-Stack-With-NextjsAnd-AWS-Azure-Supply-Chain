# FoodONtracks API Test Script
# PowerShell version for Windows
# Make sure your Next.js dev server is running on http://localhost:3000

$baseUrl = "http://localhost:3000/api"
$headers = @{
    "Content-Type" = "application/json"
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "FoodONtracks API Testing Script" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Test counter
$testsPassed = 0
$testsFailed = 0

function Test-Endpoint {
    param(
        [string]$name,
        [string]$method,
        [string]$url,
        [object]$body = $null
    )
    
    Write-Host "Testing: $name" -ForegroundColor Yellow
    Write-Host "  Method: $method | URL: $url" -ForegroundColor Gray
    
    try {
        if ($method -eq "GET" -or $method -eq "DELETE") {
            $response = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -ErrorAction Stop
        } else {
            $bodyJson = $body | ConvertTo-Json -Depth 10
            $response = Invoke-RestMethod -Uri $url -Method $method -Headers $headers -Body $bodyJson -ErrorAction Stop
        }
        
        Write-Host "  ✓ Success" -ForegroundColor Green
        Write-Host "  Response: $($response | ConvertTo-Json -Compress -Depth 3)" -ForegroundColor Gray
        Write-Host ""
        $script:testsPassed++
        return $response
    } catch {
        Write-Host "  ✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        $script:testsFailed++
        return $null
    }
}

# ===========================
# 1. USERS API TESTS
# ===========================
Write-Host "`n[1] USERS API" -ForegroundColor Magenta
Write-Host "-----------------------------------" -ForegroundColor Magenta

# GET all users
Test-Endpoint -name "Get all users (paginated)" -method "GET" -url "$baseUrl/users?page=1&limit=5"

# POST create user
$newUser = @{
    name = "Test User $(Get-Random)"
    email = "test$(Get-Random)@example.com"
    phoneNumber = "+1555$(Get-Random -Minimum 1000000 -Maximum 9999999)"
    password = "securePass123"
    role = "CUSTOMER"
}
$createdUser = Test-Endpoint -name "Create new user" -method "POST" -url "$baseUrl/users" -body $newUser

if ($createdUser) {
    # GET specific user
    Test-Endpoint -name "Get user by ID" -method "GET" -url "$baseUrl/users/$($createdUser.data.id)"
    
    # PUT update user
    $updateUser = @{
        name = "Updated Name"
    }
    Test-Endpoint -name "Update user" -method "PUT" -url "$baseUrl/users/$($createdUser.data.id)" -body $updateUser
}

# ===========================
# 2. RESTAURANTS API TESTS
# ===========================
Write-Host "`n[2] RESTAURANTS API" -ForegroundColor Magenta
Write-Host "-----------------------------------" -ForegroundColor Magenta

# GET all restaurants
Test-Endpoint -name "Get all restaurants" -method "GET" -url "$baseUrl/restaurants?page=1&limit=5"

# GET with filters
Test-Endpoint -name "Filter restaurants by city" -method "GET" -url "$baseUrl/restaurants?city=New York"

# GET specific restaurant
Test-Endpoint -name "Get restaurant by ID" -method "GET" -url "$baseUrl/restaurants/1"

# POST create restaurant
$newRestaurant = @{
    name = "Test Restaurant $(Get-Random)"
    email = "restaurant$(Get-Random)@example.com"
    phoneNumber = "+1555$(Get-Random -Minimum 1000000 -Maximum 9999999)"
    description = "Test restaurant description"
    address = "123 Test Street"
    city = "Test City"
    state = "TC"
    zipCode = "12345"
}
$createdRestaurant = Test-Endpoint -name "Create new restaurant" -method "POST" -url "$baseUrl/restaurants" -body $newRestaurant

if ($createdRestaurant) {
    # PUT update restaurant
    $updateRestaurant = @{
        description = "Updated description"
        isActive = $true
    }
    Test-Endpoint -name "Update restaurant" -method "PUT" -url "$baseUrl/restaurants/$($createdRestaurant.data.id)" -body $updateRestaurant
}

# ===========================
# 3. MENU ITEMS API TESTS
# ===========================
Write-Host "`n[3] MENU ITEMS API" -ForegroundColor Magenta
Write-Host "-----------------------------------" -ForegroundColor Magenta

# GET all menu items
Test-Endpoint -name "Get all menu items" -method "GET" -url "$baseUrl/menu-items?page=1&limit=5"

# GET with filters
Test-Endpoint -name "Filter menu items by restaurant" -method "GET" -url "$baseUrl/menu-items?restaurantId=1"

# GET specific menu item
Test-Endpoint -name "Get menu item by ID" -method "GET" -url "$baseUrl/menu-items/1"

# POST create menu item
$newMenuItem = @{
    restaurantId = 1
    name = "Test Dish $(Get-Random)"
    description = "Delicious test dish"
    price = 15.99
    category = "Test Category"
    preparationTime = 20
}
$createdMenuItem = Test-Endpoint -name "Create new menu item" -method "POST" -url "$baseUrl/menu-items" -body $newMenuItem

if ($createdMenuItem) {
    # PUT update menu item
    $updateMenuItem = @{
        price = 17.99
        isAvailable = $true
    }
    Test-Endpoint -name "Update menu item" -method "PUT" -url "$baseUrl/menu-items/$($createdMenuItem.data.id)" -body $updateMenuItem
}

# ===========================
# 4. ADDRESSES API TESTS
# ===========================
Write-Host "`n[4] ADDRESSES API" -ForegroundColor Magenta
Write-Host "-----------------------------------" -ForegroundColor Magenta

# GET addresses for user
Test-Endpoint -name "Get addresses for user" -method "GET" -url "$baseUrl/addresses?userId=1"

# POST create address
$newAddress = @{
    userId = 1
    addressLine1 = "$(Get-Random) Test Avenue"
    city = "Test City"
    state = "TC"
    zipCode = "54321"
    country = "USA"
    isDefault = $false
}
$createdAddress = Test-Endpoint -name "Create new address" -method "POST" -url "$baseUrl/addresses" -body $newAddress

if ($createdAddress) {
    # GET specific address
    Test-Endpoint -name "Get address by ID" -method "GET" -url "$baseUrl/addresses/$($createdAddress.data.id)"
    
    # PUT update address
    $updateAddress = @{
        addressLine2 = "Apt 100"
    }
    Test-Endpoint -name "Update address" -method "PUT" -url "$baseUrl/addresses/$($createdAddress.data.id)" -body $updateAddress
}

# ===========================
# 5. ORDERS API TESTS
# ===========================
Write-Host "`n[5] ORDERS API" -ForegroundColor Magenta
Write-Host "-----------------------------------" -ForegroundColor Magenta

# GET all orders
Test-Endpoint -name "Get all orders" -method "GET" -url "$baseUrl/orders?page=1&limit=5"

# GET with filters
Test-Endpoint -name "Filter orders by user" -method "GET" -url "$baseUrl/orders?userId=1"

# GET specific order
Test-Endpoint -name "Get order by ID" -method "GET" -url "$baseUrl/orders/1"

# POST create order
$newOrder = @{
    userId = 1
    restaurantId = 1
    addressId = 1
    orderItems = @(
        @{
            menuItemId = 1
            quantity = 2
        }
    )
    deliveryFee = 3.99
    tax = 2.50
    discount = 0
}
$createdOrder = Test-Endpoint -name "Create new order" -method "POST" -url "$baseUrl/orders" -body $newOrder

if ($createdOrder) {
    # PATCH update order status
    $updateOrderStatus = @{
        status = "CONFIRMED"
        notes = "Order confirmed by test script"
    }
    Test-Endpoint -name "Update order status" -method "PATCH" -url "$baseUrl/orders/$($createdOrder.data.id)" -body $updateOrderStatus
}

# ===========================
# 6. REVIEWS API TESTS
# ===========================
Write-Host "`n[6] REVIEWS API" -ForegroundColor Magenta
Write-Host "-----------------------------------" -ForegroundColor Magenta

# GET all reviews
Test-Endpoint -name "Get all reviews" -method "GET" -url "$baseUrl/reviews?page=1&limit=5"

# GET with filters
Test-Endpoint -name "Filter reviews by restaurant" -method "GET" -url "$baseUrl/reviews?restaurantId=1"

# Note: Creating a review requires a delivered order, so we'll skip POST test

# ===========================
# 7. DELIVERY PERSONS API TESTS
# ===========================
Write-Host "`n[7] DELIVERY PERSONS API" -ForegroundColor Magenta
Write-Host "-----------------------------------" -ForegroundColor Magenta

# GET all delivery persons
Test-Endpoint -name "Get all delivery persons" -method "GET" -url "$baseUrl/delivery-persons?page=1&limit=5"

# GET available delivery persons
Test-Endpoint -name "Filter available delivery persons" -method "GET" -url "$baseUrl/delivery-persons?isAvailable=true"

# POST create delivery person
$newDeliveryPerson = @{
    name = "Test Driver $(Get-Random)"
    email = "driver$(Get-Random)@foodontracks.com"
    phoneNumber = "+1555$(Get-Random -Minimum 1000000 -Maximum 9999999)"
    vehicleType = "Motorcycle"
    vehicleNumber = "TEST-$(Get-Random -Minimum 1000 -Maximum 9999)"
}
$createdDeliveryPerson = Test-Endpoint -name "Create new delivery person" -method "POST" -url "$baseUrl/delivery-persons" -body $newDeliveryPerson

if ($createdDeliveryPerson) {
    # GET specific delivery person
    Test-Endpoint -name "Get delivery person by ID" -method "GET" -url "$baseUrl/delivery-persons/$($createdDeliveryPerson.data.id)"
    
    # PUT update delivery person
    $updateDeliveryPerson = @{
        isAvailable = $false
        vehicleType = "Car"
    }
    Test-Endpoint -name "Update delivery person" -method "PUT" -url "$baseUrl/delivery-persons/$($createdDeliveryPerson.data.id)" -body $updateDeliveryPerson
}

# ===========================
# SUMMARY
# ===========================
Write-Host "`n=====================================" -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor Red
Write-Host "Total Tests: $($testsPassed + $testsFailed)" -ForegroundColor Yellow
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✓ All tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Some tests failed. Check the output above for details." -ForegroundColor Red
}
