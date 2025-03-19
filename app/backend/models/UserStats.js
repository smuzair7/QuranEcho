const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const userStatsSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true
  },
  memorizedAyats: {
    type: Number,
    default: 0
  },
  memorizedSurahs: {
    type: Number,
    default: 0
  },
  timeSpentMinutes: {
    type: Number,
    default: 0
  },
  dailyGoal: {
    type: Number,
    default: 10
  },
  streakDays: {
    type: Number,
    default: 0
  },
  // Array of the last 7 days of memorization progress
  weeklyProgress: {
    type: [Number],
    default: [0, 0, 0, 0, 0, 0, 0]
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  // Store the date of the last activity to calculate streaks
  lastActivityDate: {
    type: Date,
    default: Date.now
  }
});

// Create index for faster queries
userStatsSchema.index({ userId: 1 });

module.exports = mongoose.model('UserStats', userStatsSchema);
