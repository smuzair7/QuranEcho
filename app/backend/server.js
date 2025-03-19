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

// Update user stats
app.put('/user-stats/:userId', async (req, res) => {
  try {
    const updates = req.body;
    const userId = req.params.userId;
    
    console.log('Received update request with body:', JSON.stringify(updates));
    
    if (!isValidObjectId(userId)) {
      return res.status(400).json({ 
        message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
      });
    }
    
    // Build the aggregation pipeline for atomic updates
    const pipeline = [];
    
    // Handle new memorized ayats with uniqueness check
    if (updates.newMemorizedAyats && Array.isArray(updates.newMemorizedAyats)) {
      pipeline.push({
        $set: {
          memorizedAyatsList: {
            $setUnion: ["$memorizedAyatsList", updates.newMemorizedAyats]
          }
        }
      }, {
        $set: {
          memorizedAyats: { $size: "$memorizedAyatsList" }
        }
      });
    }
    
    // Handle new memorized surahs with uniqueness check
    if (updates.newMemorizedSurahs && Array.isArray(updates.newMemorizedSurahs)) {
      pipeline.push({
        $set: {
          memorizedSurahsList: {
            $setUnion: ["$memorizedSurahsList", updates.newMemorizedSurahs]
          }
        }
      }, {
        $set: {
          memorizedSurahs: { $size: "$memorizedSurahsList" }
        }
      });
    }
    
    // Handle time addition
    if (updates.timeSpentMinutes !== undefined) {
      const additionalTime = parseInt(updates.timeSpentMinutes) || 0;
      if (additionalTime > 0) {
        pipeline.push({
          $set: {
            timeSpentMinutes: { $add: ["$timeSpentMinutes", additionalTime] }
          }
        });
      }
    }
    
    // Add mandatory updates
    pipeline.push({
      $set: {
        lastActivityDate: new Date(),
        lastUpdated: new Date()
      }
    });
    
    // Execute atomic update
    const updatedStats = await UserStats.findOneAndUpdate(
      { userId },
      pipeline,
      { new: true, runValidators: true }
    );

    if (!updatedStats) {
      return res.status(404).json({ message: 'User stats not found' });
    }
    
    res.json({
      ...updatedStats.toObject(),
      memorizedAyats: updatedStats.memorizedAyatsList?.length || 0,
      memorizedSurahs: updatedStats.memorizedSurahsList?.length || 0
    });
    
  } catch (error) {
    console.error('Error updating user stats:', error);
    res.status(500).json({ message: 'Server error updating user stats', error: error.message });
  }
});

// Update weekly progress
app.put('/user-stats/:userId/weekly-progress', async (req, res) => {
  try {
    const { dayIndex, value } = req.body;
    const userId = req.params.userId;
    
    // Check if userId is a valid MongoDB ObjectId
    if (!isValidObjectId(userId)) {
      return res.status(400).json({ 
        message: 'Invalid user ID format. Must be a valid MongoDB ObjectId.'
      });
    }
    
    if (dayIndex < 0 || dayIndex > 6) {
      return res.status(400).json({ message: 'Day index must be between 0 and 6' });
    }
    
    // Get the current weekly progress
    const userStats = await UserStats.findOne({ userId });
    
    if (!userStats) {
      return res.status(404).json({ message: 'User stats not found' });
    }
    
    // Update the specific day's progress
    const weeklyProgress = [...userStats.weeklyProgress];
    weeklyProgress[dayIndex] = value;
    
    // Save the updated progress
    const updatedStats = await UserStats.findOneAndUpdate(
      { userId },
      { 
        $set: { 
          weeklyProgress: weeklyProgress,
          lastUpdated: new Date(),
          lastActivityDate: new Date()
        }
      },
      { new: true }
    );
    
    res.json(updatedStats);
  } catch (error) {
    console.error('Error updating weekly progress:', error);
    res.status(500).json({ message: 'Server error updating weekly progress' });
  }
});

const PORT = 3000;
const IP = '0.0.0.0';  // Change this to listen on all network interfaces

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
  console.log('- PUT  /user-stats/:userId');
  console.log('- PUT  /user-stats/:userId/daily-goal');
  console.log('- PUT  /user-stats/:userId/weekly-progress');
  console.log('- POST /user-stats/:userId/add-time'); // Add this line
});
