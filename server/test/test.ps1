$ErrorActionPreference = "Stop"

$BaseUrl = "http://192.168.101.134:8080"
$DbFile = "pension.db"

Write-Host "=== API TEST SCRIPT START ==="

# 1. Ensure admin user exists (manual fallback)
if (Test-Path $DbFile) {
    Write-Host "Ensuring admin user exists..."
    $sql = @"
INSERT OR IGNORE INTO users (username, password, dob, is_admin)
VALUES (
  'admin',
  '\$2b\$10\$C9z8dD6WwU9sK9fKqvZkMuZ9q1QYx0G0yYy1YyYyYyYyYyYyY',
  '1970-01-01',
  1
);
"@
    sqlite3 $DbFile $sql
}

# 2. Register normal user
Write-Host "Registering normal user..."
try {
    Invoke-RestMethod -Method Post -Uri "$BaseUrl/register" -ContentType "application/json" -Body @"
{
  "username": "user1",
  "password": "password123",
  "dob": "1990-01-01"
}
"@
} catch {
    Write-Host "User may already exist (continuing)"
}

# 3. Login as admin
Write-Host "Logging in as admin..."
$adminLogin = Invoke-RestMethod -Method Post -Uri "$BaseUrl/login" -ContentType "application/json" -Body @"
{
  "username": "admin",
  "password": "admin"
}
"@
$AdminToken = $adminLogin.token

# 4. Login as normal user
Write-Host "Logging in as user..."
$userLogin = Invoke-RestMethod -Method Post -Uri "$BaseUrl/login" -ContentType "application/json" -Body @"
{
  "username": "user1",
  "password": "password123"
}
"@
$UserToken = $userLogin.token

# 5. Admin locks user (id = 2)
Write-Host "Admin locking user..."
Invoke-RestMethod -Method Post -Uri "$BaseUrl/admin/lock_user" `
  -Headers @{ Authorization = "Bearer $AdminToken" } `
  -ContentType "application/json" `
  -Body '{ "user_id": 2 }'

# 6. Admin resets user password
Write-Host "Admin resetting password..."
Invoke-RestMethod -Method Post -Uri "$BaseUrl/admin/reset_password" `
  -Headers @{ Authorization = "Bearer $AdminToken" } `
  -ContentType "application/json" `
  -Body @"
{
  "user_id": 2,
  "new_password": "newpass123"
}
"@

# 7. Create pension pot
Write-Host "Creating pension pot..."
Invoke-RestMethod -Method Post -Uri "$BaseUrl/pension_pots" `
  -Headers @{ Authorization = "Bearer $UserToken" } `
  -ContentType "application/json" `
  -Body @"
{
  "amount": 50000,
  "date": "2024-01-01",
  "interest_rate": 0.05
}
"@

# 8. List pension pots
Write-Host "Listing pension pots..."
Invoke-RestMethod -Method Get -Uri "$BaseUrl/pension_pots" `
  -Headers @{ Authorization = "Bearer $UserToken" }

# 9. Create drawdown
Write-Host "Creating drawdown..."
Invoke-RestMethod -Method Post -Uri "$BaseUrl/drawdowns" `
  -Headers @{ Authorization = "Bearer $UserToken" } `
  -ContentType "application/json" `
  -Body @"
{
  "amount": 1000,
  "start_date": "2030-01-01",
  "end_date": null,
  "interest_rate": 0.02
}
"@

# 10. List drawdowns
Write-Host "Listing drawdowns..."
Invoke-RestMethod -Method Get -Uri "$BaseUrl/drawdowns" `
  -Headers @{ Authorization = "Bearer $UserToken" }

# 11. Set state pension
Write-Host "Setting state pension..."
Invoke-RestMethod -Method Post -Uri "$BaseUrl/state_pension" `
  -Headers @{ Authorization = "Bearer $UserToken" } `
  -ContentType "application/json" `
  -Body @"
{
  "start_age": 67,
  "amount": 9000,
  "interest_rate": 0.02
}
"@

# 12. Get state pension
Write-Host "Getting state pension..."
Invoke-RestMethod -Method Get -Uri "$BaseUrl/state_pension" `
  -Headers @{ Authorization = "Bearer $UserToken" }

# 13. Run simulation
Write-Host "Running simulation..."
Invoke-RestMethod -Method Post -Uri "$BaseUrl/simulate" `
  -Headers @{ Authorization = "Bearer $UserToken" }

Write-Host "=== API TEST SCRIPT COMPLETE ==="
