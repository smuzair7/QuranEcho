import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class MakharijPage extends StatefulWidget {
  final String? letter;
  
  const MakharijPage({super.key, this.letter});

  @override
  State<MakharijPage> createState() => _MakharijPageState();
}

class _MakharijPageState extends State<MakharijPage> {
  // Audio recording variables
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Tap to start recording';

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Start recording function
  Future<void> _startRecording() async {
    try {
      // Request permissions
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _recordingStatus = 'Permission denied for recording';
        });
        return;
      }

      // Get the temp directory
      final directory = await getTemporaryDirectory();
      String fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      // If a letter is provided, include it in the filename
      if (widget.letter != null) {
        fileName = '${widget.letter}_$fileName';
      }
      
      final filePath = path.join(directory.path, fileName);

      // Configure recording for WAV format
      final config = RecordConfig(
        encoder: AudioEncoder.wav, // Changed to WAV encoder
        sampleRate: 44100,
        numChannels: 2, // Stereo recording
      );

      // Start recording
      await _audioRecorder.start(config, path: filePath);

      setState(() {
        _isRecording = true;
        _recordingStatus = 'Recording in progress...';
        _recordingPath = filePath;
      });
    } catch (e) {
      setState(() {
        _recordingStatus = 'Recording error: ${e.toString()}';
      });
    }
  }

  // Stop recording function
  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Recording saved';
          _recordingPath = path;
        });
      } else {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Failed to save recording';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingStatus = 'Error when stopping: ${e.toString()}';
      });
    }
  }

  // Play recording function
  Future<void> _playRecording() async {
    if (_recordingPath != null) {
      try {
        await _audioPlayer.setFilePath(_recordingPath!);
        _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _recordingStatus = 'Playing recording...';
        });

        // Listen for playback completion
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
              _recordingStatus = 'Ready to record';
            });
          }
        });
      } catch (e) {
        setState(() {
          _recordingStatus = 'Error playing: ${e.toString()}';
        });
      }
    } else {
      setState(() {
        _recordingStatus = 'No recording to play';
      });
    }
  }

  // Stop playback function
  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _recordingStatus = 'Ready to record';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.letter != null 
          ? 'Recording: ${widget.letter}' 
          : 'Pronunciation Recording'),
        backgroundColor: const Color(0xFF1F8A70),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display selected letter if available
            if (widget.letter != null)
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F8A70).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.letter!,
                    style: const TextStyle(
                      fontSize: 70,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Scheherazade',
                    ),
                  ),
                ),
              )
            else
              Icon(
                Icons.record_voice_over,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            
            const SizedBox(height: 20),
            
            Text(
              widget.letter != null ? 'Practice Pronouncing' : 'Makharij',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              widget.letter != null
                  ? 'Record yourself pronouncing this letter correctly'
                  : 'Learn proper pronunciation points of Arabic letters',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Recording status text
            Text(
              _recordingStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Recording controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Record button
                ElevatedButton(
                  onPressed: _isPlaying ? null : (_isRecording ? _stopRecording : _startRecording),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : const Color(0xFF1F8A70),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    size: 36,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Play button (only enabled if recording exists)
                ElevatedButton(
                  onPressed: (_recordingPath != null && !_isRecording) 
                      ? (_isPlaying ? _stopPlayback : _playRecording)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.orange : const Color(0xFF00A896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.stop : Icons.play_arrow,
                    size: 36,
                  ),
                ),
              ],
            ),
            
            if (_recordingPath != null) ...[
              const SizedBox(height: 30),
              Text(
                'Recording saved at:\n${_recordingPath!.split('/').last}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
