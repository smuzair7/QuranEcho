import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class RecitePage extends StatefulWidget {
  final String? selectedSurah;
  final String? selectedReciter;
  
  const RecitePage({
    super.key, 
    this.selectedSurah,
    this.selectedReciter,
  });

  @override
  State<RecitePage> createState() => _RecitePageState();
}

class _RecitePageState extends State<RecitePage> {
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  String _recordingStatus = 'Tap to start reciting';
  
  // Keep the list but don't show UI for selection
  final List<String> surahs = [
    'Al-Fatihah', 'Al-Baqarah', 'Ali-Imran', 'An-Nisa', 
    'Al-Maidah', 'Al-Anam', 'Al-Araf', 'Al-Anfal'
  ];

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        setState(() {
          _recordingStatus = 'Permission denied for recording';
        });
        return;
      }

      final directory = await getTemporaryDirectory();
      String fileName = 'recitation_${DateTime.now().millisecondsSinceEpoch}.wav';
      
      if (widget.selectedSurah != null) {
        fileName = '${widget.selectedSurah!.replaceAll(' ', '_')}_$fileName';
      }
      
      final filePath = path.join(directory.path, fileName);

      final config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 2,
      );

      await _audioRecorder.start(config, path: filePath);

      setState(() {
        _isRecording = true;
        _recordingStatus = 'Reciting...';
        _recordingPath = filePath;
      });
    } catch (e) {
      setState(() {
        _recordingStatus = 'Recording error: ${e.toString()}';
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      
      if (path != null) {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Recitation saved';
          _recordingPath = path;
        });
      } else {
        setState(() {
          _isRecording = false;
          _recordingStatus = 'Failed to save recitation';
        });
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _recordingStatus = 'Error when stopping: ${e.toString()}';
      });
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath != null) {
      try {
        await _audioPlayer.setFilePath(_recordingPath!);
        _audioPlayer.play();
        setState(() {
          _isPlaying = true;
          _recordingStatus = 'Playing recitation...';
        });

        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
              _recordingStatus = 'Ready to recite';
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
        _recordingStatus = 'No recitation to play';
      });
    }
  }

  Future<void> _stopPlayback() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _recordingStatus = 'Ready to recite';
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isFromLehja = widget.selectedReciter != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isFromLehja ? 'Lehja Practice' : 'Recitation'),
        backgroundColor: const Color(0xFF05668D),
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
            Icon(
              isFromLehja ? Icons.headphones : Icons.menu_book,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              isFromLehja 
                ? 'Practice with ${widget.selectedReciter}'
                : 'Quran Recitation',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            if (widget.selectedSurah != null) ...[
              Text(
                'Surah: ${widget.selectedSurah}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
            
            Text(
              isFromLehja
                ? 'Listen to the reciter and practice the proper lehja'
                : 'Practice your Quran recitation and listen to your progress',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            
            const Spacer(),
            
            Text(
              _recordingStatus,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Record button
                ElevatedButton(
                  onPressed: _isPlaying ? null : (_isRecording ? _stopRecording : _startRecording),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : const Color(0xFF05668D),
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
                
                // Play button
                ElevatedButton(
                  onPressed: (_recordingPath != null && !_isRecording) 
                      ? (_isPlaying ? _stopPlayback : _playRecording)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPlaying ? Colors.orange : const Color(0xFF028090),
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
            
            const SizedBox(height: 20),
            
            if (_recordingPath != null) ...[
              Text(
                'Recitation saved at:\n${_recordingPath!.split('/').last}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
            
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
