# Thunder Client API Test Cases

## Base URL
```
http://localhost:3000
```

## 1. GET / (Welcome Route)
**Method:** GET
**URL:** `http://localhost:3000/`
**Headers:** None
**Body:** None

## 2. GET /test (Test Route)
**Method:** GET
**URL:** `http://localhost:3000/test`
**Headers:** None
**Body:** None

## 3. POST /registerUser (Register User)
**Method:** POST
**URL:** `http://localhost:3000/registerUser`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "username": "testuser123",
  "email": "testuser@example.com",
  "password": "password123"
}
```

## 4. POST /login (Login User)
**Method:** POST
**URL:** `http://localhost:3000/login`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "username": "testuser123",
  "password": "password123"
}
```

## 5. GET /user-stats/:userId (Get User Stats)
**Method:** GET
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2`
**Headers:** None
**Body:** None
**Note:** Replace `67b71830696e8c0d1e370ee2` with the actual user ID from login response

## 6. GET /user-stats/:userId/weekly-progress (Get Weekly Progress)
**Method:** GET
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/weekly-progress`
**Headers:** None
**Body:** None

## 7. PUT /user-stats/:userId/weekly-progress (Update Weekly Progress)
**Method:** PUT
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/weekly-progress`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "dayIndex": 0,
  "value": 30
}
```

## 8. POST /user-stats/:userId/weekly-progress (Add Weekly Progress)
**Method:** POST
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/weekly-progress`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "dayIndex": 1,
  "value": 45
}
```

## 9. POST /user-stats/:userId/add-time (Add Time)
**Method:** POST
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/add-time`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "timeMinutes": 25
}
```

## 10. PUT /user-stats/:userId/add-time (Add Time - Alternative)
**Method:** PUT
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/add-time`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "timeMinutes": 15
}
```

## 11. GET /user-stats/:userId/memorized-ayats (Get Memorized Ayats)
**Method:** GET
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/memorized-ayats`
**Headers:** None
**Body:** None

## 12. PUT /user-stats/:userId/memorized-ayats (Update Memorized Ayats)
**Method:** PUT
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/memorized-ayats`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "count": 50
}
```

## 13. POST /user-stats/:userId/memorized-ayats (Set Memorized Ayats)
**Method:** POST
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/memorized-ayats`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "count": 75
}
```

## 14. GET /user-stats/:userId/memorized-surahs (Get Memorized Surahs)
**Method:** GET
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/memorized-surahs`
**Headers:** None
**Body:** None

## 15. PUT /user-stats/:userId/memorized-surahs (Update Memorized Surahs)
**Method:** PUT
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/memorized-surahs`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "count": 3
}
```

## 16. POST /user-stats/:userId/memorized-surahs (Set Memorized Surahs)
**Method:** POST
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/memorized-surahs`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "count": 5
}
```

## 17. GET /user-stats/:userId/surah-progress (Get Surah Progress)
**Method:** GET
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/surah-progress`
**Headers:** None
**Body:** None

## 18. PUT /user-stats/:userId/surah-progress (Update Surah Progress)
**Method:** PUT
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/surah-progress`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "surahNumber": 1,
  "progress": 80
}
```

## 19. POST /user-stats/:userId/surah-progress (Set Surah Progress)
**Method:** POST
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/surah-progress`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "surahNumber": 2,
  "progress": 45
}
```

## 20. GET /user-stats/:userId/streak (Get Streak)
**Method:** GET
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/streak`
**Headers:** None
**Body:** None

## 21. PUT /user-stats/:userId/streak (Update Streak)
**Method:** PUT
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/streak`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "streakDays": 7
}
```

## 22. POST /user-stats/:userId/streak (Set Streak)
**Method:** POST
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/streak`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "streakDays": 10
}
```

## 23. GET /user-stats/:userId/daily-goal (Get Daily Goal)
**Method:** GET
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/daily-goal`
**Headers:** None
**Body:** None

## 24. PUT /user-stats/:userId/daily-goal (Update Daily Goal)
**Method:** PUT
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/daily-goal`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "dailyGoal": 60
}
```

## 25. POST /user-stats/:userId/daily-goal (Set Daily Goal)
**Method:** POST
**URL:** `http://localhost:3000/user-stats/67b71830696e8c0d1e370ee2/daily-goal`
**Headers:** 
```json
{
  "Content-Type": "application/json"
}
```
**Body:**
```json
{
  "dailyGoal": 90
}
```

## Testing Flow:
1. First, test the welcome and test routes to ensure server is running
2. Register a new user using the register endpoint
3. Login with the registered user to get the user ID
4. Copy the user ID from the login response
5. Replace `67b71830696e8c0d1e370ee2` in all other endpoints with the actual user ID
6. Test all other endpoints using the actual user ID

## Sample User ID Format:
User IDs are MongoDB ObjectIds that look like: `507f1f77bcf86cd799439011`

## Error Testing:
You can also test error cases by:
- Using invalid user IDs (like "invalid-id")
- Sending malformed JSON
- Missing required fields
- Invalid data types (strings instead of numbers, etc.)
