const mongoose = require('mongoose');
const { Schema } = mongoose;

const userStatsSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true,
    index: true
  },
  // Total count
  memorizedAyats: {
    type: Number,
    default: 0
  },
  memorizedSurahs: {
    type: Number,
    default: 0
  },

  /**
   * Tracks individual ayats memorized
   * Format: { surahNumber: [ayatNumber1, ayatNumber2, ...] }
   */
  memorizedAyatList: {
    type: Map,
    of: [Number], // array of ayat numbers
    default: {}
  },

  /**
   * Tracks individual surahs completed
   * Array of surah numbers that have been fully memorized
   */
  memorizedSurahList: {
    type: [Number],
    default: []
  },

  // This could track completion percentage or ayats of each surah being worked on
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

module.exports = mongoose.model('UserStats', userStatsSchema);