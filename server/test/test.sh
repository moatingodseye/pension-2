#!/usr/bin/env bash
set -e

BASE_URL="http://localhost:8080"
DB_FILE="pension.db"

echo "=== API TEST SCRIPT START ==="

echo
echo "=== 1. Ensure admin user exists (manual fallback) ==="
if [ -f "$DB_FILE" ]; then
  sqlite3 "$DB_FILE" <<'SQL'
INSERT OR IGNORE INTO users (username, password, dob, is_admin)
VALUES (
  'admin',
  '$2b$10$C9z8dD6WwU9sK9fKqvZkMuZ9q1QYx0G0yYy1YyYyYyYyYyYyY',
  '1970-01-01',
  1
);
SQL
fi

echo
echo "=== 2. Register normal user ==="
curl -s -X POST "$BASE_URL/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user1",
    "password": "password123",
    "dob": "1990-01-01"
  }' || true
echo

echo
echo "=== 3. Login as admin ==="
ADMIN_TOKEN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin"
  }' | jq -r .token)

echo "Admin token acquired"

echo
echo "=== 4. Login as normal user ==="
USER_TOKEN=$(curl -s -X POST "$BASE_URL/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "user1",
    "password": "password123"
  }' | jq -r .token)

echo "User token acquired"

echo
echo "=== 5. Admin locks user (id=2) ==="
curl -s -X POST "$BASE_URL/admin/lock_user" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{ "user_id": 2 }'
echo

echo
echo "=== 6. Admin resets user password ==="
curl -s -X POST "$BASE_URL/admin/reset_password" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 2,
    "new_password": "newpass123"
  }'
echo

echo
echo "=== 7. Create pension pot ==="
curl -s -X POST "$BASE_URL/pension_pots" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50000,
    "date": "2024-01-01",
    "interest_rate": 0.05
  }'
echo

echo
echo "=== 8. List pension pots ==="
curl -s -X GET "$BASE_URL/pension_pots" \
  -H "Authorization: Bearer $USER_TOKEN"
echo

echo
echo "=== 9. Create drawdown ==="
curl -s -X POST "$BASE_URL/drawdowns" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "start_date": "2030-01-01",
    "end_date": null,
    "interest_rate": 0.02
  }'
echo

echo
echo "=== 10. List drawdowns ==="
curl -s -X GET "$BASE_URL/drawdowns" \
  -H "Authorization: Bearer $USER_TOKEN"
echo

echo
echo "=== 11. Set state pension ==="
curl -s -X POST "$BASE_URL/state_pension" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "start_age": 67,
    "amount": 9000,
    "interest_rate": 0.02
  }'
echo

echo
echo "=== 12. Get state pension ==="
curl -s -X GET "$BASE_URL/state_pension" \
  -H "Authorization: Bearer $USER_TOKEN"
echo

echo
echo "=== 13. Run simulation ==="
curl -s -X POST "$BASE_URL/simulate" \
  -H "Authorization: Bearer $USER_TOKEN"
echo

echo
echo "=== API TEST SCRIPT COMPLETE ==="
