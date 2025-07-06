import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String audioUrl;
  final bool isOwnMessage;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onPin;

  const VoiceMessageBubble({
    Key? key,
    required this.audioUrl,
    this.isOwnMessage = false,
    this.onDelete,
    this.onEdit,
    this.onPin,
  }) : super(key: key);

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _totalDuration = duration;
      });
    });
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showBubbleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.white),
              title: const Text(
                "Pin Pesan",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (widget.onPin != null) widget.onPin!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text(
                "Edit Pesan",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                if (widget.onEdit != null) widget.onEdit!();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Hapus Pesan",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                if (widget.onDelete != null) widget.onDelete!();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isOwnMessage
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showBubbleMenu(context),
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isOwnMessage ? Color(0xFF6C5CE7) : Color(0xFF222237),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: _togglePlayPause,
              ),
              SizedBox(width: 8),
              SizedBox(
                width: 70,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _currentPosition.inMilliseconds.toDouble(),
                    min: 0,
                    max: (_totalDuration.inMilliseconds.toDouble() > 0)
                        ? _totalDuration.inMilliseconds.toDouble()
                        : 1,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white24,
                    onChanged: (value) async {
                      await _audioPlayer.seek(
                        Duration(milliseconds: value.toInt()),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                ' / ',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
