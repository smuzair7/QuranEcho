const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
const UserStats = require('./models/UserStats');
require('dotenv').config();

const app = express();

app.use(cors({
  origin: '*',  // Allow all origins in development
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Add a more comprehensive logging middleware to debug request issues
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  console.log('Request body:', req.body);
  next();
});

// MongoDB Atlas Connection String
const MONGODB_URI = "mongodb+srv://QuranEcho:QuranEcho@db.mpffo.mongodb.net/fyp_app?retryWrites=true&w=majority";

mongoose.connect(MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
}).then(() => {
  console.log('Connected to MongoDB Atlas successfully');
}).catch((error) => {
  console.error('MongoDB Atlas connection error:', error);
  process.exit(1); // Exit if cannot connect to database
});

// Add MongoDB connection event handlers
mongoose.connection.on('error', (err) => {
  console.error('MongoDB connection error:', err);
});

mongoose.connection.on('disconnected', () => {
  console.log('MongoDB disconnected');
});

process.on('SIGINT', async () => {
  await mongoose.connection.close();
  process.exit(0);
});

// Default route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to FYP App API' });
});

// Test route with more information
app.get('/test', (req, res) => {
  res.json({ 
    status: 'success',
    message: 'Server is working',
    endpoints: {
      root: '/',
      test: '/test',
      login: '/login',
      register: '/registerUser'
    }
  });
});

// Login route
app.post('/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    console.log('Login attempt for username:', username);
    
    const user = await User.findOne({ username });
    if (!user) {
      console.log('User not found:', username);
      return res.status(400).json({ message: 'User not found' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      console.log('Invalid password for user:', username);
      return res.status(400).json({ message: 'Invalid password' });
    }

    // Get user stats or create default stats if they don't exist
    let userStats = await UserStats.findOne({ userId: user._id });
    if (!userStats) {
      userStats = new UserStats({ userId: user._id });
      await userStats.save();
    }

    // Update last activity date for streak tracking
    await UserStats.findOneAndUpdate(
      { userId: user._id },
      { lastActivityDate: new Date() }
    );

    // Convert MongoDB ObjectId to string
    const userId = user._id.toString();
    console.log('Login successful for user:', username);
    console.log('User ID:', userId); // Log the ID for debugging
    
    res.json({ 
      message: 'Login successful',
      user: { 
        _id: userId, // Ensure ID is a string
        username: user.username, 
        email: user.email,
        stats: {
          memorizedAyats: userStats.memorizedAyats,
          memorizedSurahs: userStats.memorizedSurahs,
          timeSpentMinutes: userStats.timeSpentMinutes,
          dailyGoal: userStats.dailyGoal,
          streakDays: userStats.streakDays,
          weeklyProgress: userStats.weeklyProgress
        }
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error during login' });
  }
});

// Register route
app.post('/registerUser', async (req, res) => {
  try {
    const { username, email, password } = req.body;
    
    // Check if user already exists
    const existingUser = await User.findOne({ $or: [{ email }, { username }] });
    if (existingUser) {
      return res.status(400).json({ 
        message: existingUser.email === email ? 'Email already exists' : 'Username already exists' 
      });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    
    const user = new User({
      username,
      email,
      password: hashedPassword,
    });

    await user.save();
    
    // Create initial stats for the new user
    const userStats = new UserStats({
      userId: user._id,
    });
    
    await userStats.save();
    
    console.log('User registered successfully:', username);
    res.status(201).json({ message: 'User created successfully' });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error during registration' });
  }
});

// Helper function to check if a string is a valid MongoDB ObjectId
function isValidObjectId(id) {
  return mongoose.Types.ObjectId.isValid(id) && 
         String(new mongoose.Types.ObjectId(id)) === id;
}

// Get user stats
app.get('/user-stats/:userId', async (req, res) => {
  try {
    const userId = req.params.userId;
    
    // Check if userId is a valid MongoDB ObjectId
    if (!isValidObjectId(userId)) {
      return res.status(400).json({ 
        message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
      });
    }
    
    const userStats = await UserStats.findOne({ userId });
    
    if (!userStats) {
      return res.status(404).json({ message: 'User stats not found' });
    }
    
    res.json(userStats);
  } catch (error) {
    console.error('Error retrieving user stats:', error);
    res.status(500).json({ message: 'Server error retrieving user stats' });
  }
});

// Fix issue with endpoints by using more consistent routing patterns
// Consider adding the route parameter explicitly to the handler function

// Weekly progress - both methods in one handler for consistency
app.route('/user-stats/:userId/weekly-progress')
  .get(async (req, res) => {
    try {
      const userId = req.params.userId;
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
      
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      res.json({ weeklyProgress: userStats.weeklyProgress || [0, 0, 0, 0, 0, 0, 0] });
    } catch (error) {
      console.error('Error getting weekly progress:', error);
      res.status(500).json({ message: 'Server error getting weekly progress' });
    }
  })
  .put(async (req, res) => {
    try {
      const { dayIndex, value } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ 
          message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
        });
      }
  
      if (dayIndex < 0 || dayIndex > 6) {
        return res.status(400).json({ message: 'Day index must be between 0 and 6' });
      }
  
      // Use a simpler approach to update that doesn't rely on complex operators
      // First retrieve the user stats
      const userStats = await UserStats.findOne({ userId });
      
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      // Ensure weeklyProgress is an array
      if (!Array.isArray(userStats.weeklyProgress) || userStats.weeklyProgress.length !== 7) {
        userStats.weeklyProgress = [0, 0, 0, 0, 0, 0, 0];
      }
      
      // Update the specific day
      userStats.weeklyProgress[dayIndex] = value;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      
      // Save the changes
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating weekly progress:', error);
      res.status(500).json({ message: 'Server error updating weekly progress' });
    }
  })
  .post(async (req, res) => {
    try {
      const { dayIndex, value } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ 
          message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
        });
      }
  
      if (dayIndex < 0 || dayIndex > 6) {
        return res.status(400).json({ message: 'Day index must be between 0 and 6' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      if (!Array.isArray(userStats.weeklyProgress) || userStats.weeklyProgress.length !== 7) {
        userStats.weeklyProgress = [0, 0, 0, 0, 0, 0, 0];
      }
      
      userStats.weeklyProgress[dayIndex] = value;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating weekly progress:', error);
      res.status(500).json({ message: 'Server error updating weekly progress' });
    }
  });

// Add Time - support both POST and PUT methods
app.route('/user-stats/:userId/add-time')
  .post(async (req, res) => {
    try {
      const { timeMinutes } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ 
          message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
        });
      }
  
      if (timeMinutes === undefined || typeof timeMinutes !== 'number' || timeMinutes <= 0) {
        return res.status(400).json({ 
          message: 'Time minutes must be a positive number'
        });
      }
  
      // Use findOne and save to avoid aggregation pipeline issues
      const userStats = await UserStats.findOne({ userId });
      
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      // Add time directly to the document
      userStats.timeSpentMinutes += timeMinutes;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error adding time to user stats:', error);
      res.status(500).json({ message: 'Server error adding time to user stats' });
    }
  })
  .put(async (req, res) => {
    try {
      const { timeMinutes } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (timeMinutes === undefined || typeof timeMinutes !== 'number' || timeMinutes <= 0) {
        return res.status(400).json({ message: 'Time minutes must be a positive number' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      userStats.timeSpentMinutes += timeMinutes;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error adding time to user stats:', error);
      res.status(500).json({ message: 'Server error adding time to user stats' });
    }
  });

// Memorized Ayats - consolidate route with route() method
app.route('/user-stats/:userId/memorized-ayats')
  .get(async (req, res) => {
    try {
      const userId = req.params.userId;
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
      
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      res.json({ memorizedAyats: userStats.memorizedAyats });
    } catch (error) {
      console.error('Error getting memorized ayats:', error);
      res.status(500).json({ message: 'Server error getting memorized ayats' });
    }
  })
  .put(async (req, res) => {
    try {
      const { count } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (count === undefined || typeof count !== 'number' || count < 0) {
        return res.status(400).json({ message: 'Count must be a non-negative number' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      userStats.memorizedAyats = count;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating memorized Ayats:', error);
      res.status(500).json({ message: 'Server error updating memorized Ayats' });
    }
  })
  .post(async (req, res) => {
    try {
      const { count } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (count === undefined || typeof count !== 'number' || count < 0) {
        return res.status(400).json({ message: 'Count must be a non-negative number' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      userStats.memorizedAyats = count;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating memorized Ayats:', error);
      res.status(500).json({ message: 'Server error updating memorized Ayats' });
    }
  });

// Memorized Surahs - consolidate route
app.route('/user-stats/:userId/memorized-surahs')
  .get(async (req, res) => {
    try {
      const userId = req.params.userId;
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
      
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      res.json({ memorizedSurahs: userStats.memorizedSurahs });
    } catch (error) {
      console.error('Error getting memorized surahs:', error);
      res.status(500).json({ message: 'Server error getting memorized surahs' });
    }
  })
  .put(async (req, res) => {
    try {
      const { count } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (count === undefined || typeof count !== 'number' || count < 0) {
        return res.status(400).json({ message: 'Count must be a non-negative number' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      userStats.memorizedSurahs = count;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating memorized Surahs:', error);
      res.status(500).json({ message: 'Server error updating memorized Surahs' });
    }
  })
  .post(async (req, res) => {
    try {
      const { count } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (count === undefined || typeof count !== 'number' || count < 0) {
        return res.status(400).json({ message: 'Count must be a non-negative number' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      userStats.memorizedSurahs = count;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating memorized Surahs:', error);
      res.status(500).json({ message: 'Server error updating memorized Surahs' });
    }
  });

// Surah Progress - consolidate route
app.route('/user-stats/:userId/surah-progress')
  .get(async (req, res) => {
    try {
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      res.json(userStats.surahProgress || {});
    } catch (error) {
      console.error('Error retrieving surah progress:', error);
      res.status(500).json({ message: 'Server error retrieving surah progress' });
    }
  })
  .put(async (req, res) => {
    try {
      const { surahNumber, progress } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (surahNumber === undefined || typeof surahNumber !== 'number' || surahNumber <= 0 || surahNumber > 114) {
        return res.status(400).json({ message: 'Surah number must be between 1 and 114' });
      }
  
      if (progress === undefined || typeof progress !== 'number' || progress < 0 || progress > 100) {
        return res.status(400).json({ message: 'Progress must be between 0 and 100' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      // Ensure surahProgress is initialized as an object
      if (!userStats.surahProgress) {
        userStats.surahProgress = {};
      }
  
      // Update the specific surah's progress
      userStats.surahProgress[surahNumber] = progress;
      userStats.markModified('surahProgress'); // Mark as modified since it's an object
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating surah progress:', error);
      res.status(500).json({ message: 'Server error updating surah progress' });
    }
  })
  .post(async (req, res) => {
    try {
      const { surahNumber, progress } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (surahNumber === undefined || typeof surahNumber !== 'number' || surahNumber <= 0 || surahNumber > 114) {
        return res.status(400).json({ message: 'Surah number must be between 1 and 114' });
      }
  
      if (progress === undefined || typeof progress !== 'number' || progress < 0 || progress > 100) {
        return res.status(400).json({ message: 'Progress must be between 0 and 100' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      if (!userStats.surahProgress) {
        userStats.surahProgress = {};
      }
  
      userStats.surahProgress[surahNumber] = progress;
      userStats.markModified('surahProgress');
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating surah progress:', error);
      res.status(500).json({ message: 'Server error updating surah progress' });
    }
  });

// Streak - consolidate route
app.route('/user-stats/:userId/streak')
  .get(async (req, res) => {
    try {
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      // Calculate if streak is still active
      const lastActivity = userStats.lastActivityDate;
      const now = new Date();
      const oneDayMs = 24 * 60 * 60 * 1000;
      const daysSinceLastActivity = Math.floor((now - lastActivity) / oneDayMs);
      
      const streakInfo = {
        streakDays: userStats.streakDays,
        isActive: daysSinceLastActivity <= 1, // Streak is active if last activity was today or yesterday
        daysSinceLastActivity
      };
  
      res.json(streakInfo);
    } catch (error) {
      console.error('Error retrieving streak information:', error);
      res.status(500).json({ message: 'Server error retrieving streak information' });
    }
  })
  .put(async (req, res) => {
    try {
      const { streakDays } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (streakDays === undefined || typeof streakDays !== 'number' || streakDays < 0) {
        return res.status(400).json({ message: 'Streak days must be a non-negative number' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      userStats.streakDays = streakDays;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating streak days:', error);
      res.status(500).json({ message: 'Server error updating streak days' });
    }
  })
  .post(async (req, res) => {
    try {
      const { streakDays } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
  
      if (streakDays === undefined || typeof streakDays !== 'number' || streakDays < 0) {
        return res.status(400).json({ message: 'Streak days must be a non-negative number' });
      }
  
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
  
      userStats.streakDays = streakDays;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating streak days:', error);
      res.status(500).json({ message: 'Server error updating streak days' });
    }
  });

// Daily Goal - consolidate route
app.route('/user-stats/:userId/daily-goal')
  .get(async (req, res) => {
    try {
      const userId = req.params.userId;
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ message: 'Invalid user ID format' });
      }
      
      const userStats = await UserStats.findOne({ userId });
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      res.json({ dailyGoal: userStats.dailyGoal });
    } catch (error) {
      console.error('Error getting daily goal:', error);
      res.status(500).json({ message: 'Server error getting daily goal' });
    }
  })
  .put(async (req, res) => {
    try {
      const { dailyGoal } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ 
          message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
        });
      }
  
      if (dailyGoal === undefined || typeof dailyGoal !== 'number' || dailyGoal <= 0) {
        return res.status(400).json({ 
          message: 'Daily goal must be a positive number'
        });
      }
  
      // Use direct document manipulation
      const userStats = await UserStats.findOne({ userId });
      
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      userStats.dailyGoal = dailyGoal;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating daily goal:', error);
      res.status(500).json({ message: 'Server error updating daily goal' });
    }
  })
  .post(async (req, res) => {
    try {
      const { dailyGoal } = req.body;
      const userId = req.params.userId;
  
      if (!isValidObjectId(userId)) {
        return res.status(400).json({ 
          message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
        });
      }
  
      if (dailyGoal === undefined || typeof dailyGoal !== 'number' || dailyGoal <= 0) {
        return res.status(400).json({ 
          message: 'Daily goal must be a positive number'
        });
      }
  
      const userStats = await UserStats.findOne({ userId });
      
      if (!userStats) {
        return res.status(404).json({ message: 'User stats not found' });
      }
      
      userStats.dailyGoal = dailyGoal;
      userStats.lastUpdated = new Date();
      userStats.lastActivityDate = new Date();
      
      await userStats.save();
  
      res.json(userStats);
    } catch (error) {
      console.error('Error updating daily goal:', error);
      res.status(500).json({ message: 'Server error updating daily goal' });
    }
  });

const PORT = 3000;
const IP = '0.0.0.0';  // Listen on all network interfaces

app.listen(PORT, IP, () => {
  console.log('Server running on:');
  console.log(`- Local: http://localhost:${PORT}`);
  console.log(`- Network: http://${IP}:${PORT}`);
  console.log('Available routes:');
  console.log('- GET  /');
  console.log('- GET  /test');
  console.log('- POST /login');
  console.log('- POST /registerUser');
  console.log('- GET  /user-stats/:userId');
  console.log('- PUT  /user-stats/:userId/weekly-progress');
  console.log('- POST /user-stats/:userId/weekly-progress');
  console.log('- PUT  /user-stats/:userId/daily-goal');
  console.log('- POST /user-stats/:userId/daily-goal');
  console.log('- POST /user-stats/:userId/add-time');
  console.log('- PUT  /user-stats/:userId/memorized-ayats');
  console.log('- POST /user-stats/:userId/memorized-ayats');
  console.log('- PUT  /user-stats/:userId/memorized-surahs');
  console.log('- POST /user-stats/:userId/memorized-surahs');
  console.log('- GET  /user-stats/:userId/surah-progress');
  console.log('- PUT  /user-stats/:userId/surah-progress');
  console.log('- POST /user-stats/:userId/surah-progress');
  console.log('- GET  /user-stats/:userId/streak');
  console.log('- PUT  /user-stats/:userId/streak');
  console.log('- POST /user-stats/:userId/streak');
});