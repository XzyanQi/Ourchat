import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class OurSimpleAudioPlayer extends StatefulWidget {
  final String audioUrl;
  const OurSimpleAudioPlayer({Key? key, required this.audioUrl})
    : super(key: key);

  @override
  State<OurSimpleAudioPlayer> createState() => _OurSimpleAudioPlayerState();
}

class _OurSimpleAudioPlayerState extends State<OurSimpleAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _current = Duration.zero;
  Duration _total = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });
    _audioPlayer.onDurationChanged.listen((d) {
      setState(() => _total = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      setState(() => _current = p);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _format(Duration d) =>
      "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(d.inSeconds.remainder(60)).toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            color: Colors.white,
            size: 32,
          ),
          onPressed: _toggle,
        ),
        SizedBox(
          width: 70,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _current.inMilliseconds.toDouble(),
              min: 0,
              max: (_total.inMilliseconds.toDouble() > 0)
                  ? _total.inMilliseconds.toDouble()
                  : 1,
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(milliseconds: value.toInt()));
              },
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          _format(_current),
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        Text(' / ', style: TextStyle(color: Colors.white38, fontSize: 12)),
        Text(
          _format(_total),
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
