const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
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

    console.log('Login successful for user:', username);
    res.json({ 
      message: 'Login successful',
      user: { username: user.username, email: user.email }
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
    console.log('User registered successfully:', username);
    res.status(201).json({ message: 'User created successfully' });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ message: 'Server error during registration' });
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
});
