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
  // Change from Map to Object type
  surahProgress: {
    type: Object,
    default: {},
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
  weeklyProgress: {
    type: [Number],
    default: [0, 0, 0, 0, 0, 0, 0]
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  lastActivityDate: {
    type: Date,
    default: Date.now
  }
});

// Create index for faster queries
userStatsSchema.index({ userId: 1 });

module.exports = mongoose.model('UserStats', userStatsSchema);