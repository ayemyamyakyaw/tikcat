import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> videos = [];
  int currentVideoIndex = 0;
  VideoPlayerController? _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http.get(Uri.parse('https://raw.githubusercontent.com/ayemyamyakyaw/jsonx/main/post.json'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          videos = data.map((item) => {
            'videoUrl': item['videoUrl'] as String,
            'title': item['title'] as String,
            'author': item['author'] as String,
          }).toList().reversed.toList();
        });
        _initializeVideoPlayer();
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      print('Error fetching videos: $e');
    }
  }

  void _initializeVideoPlayer() {
    if (videos.isNotEmpty) {
      _controller = VideoPlayerController.network(videos[currentVideoIndex]['videoUrl']!)
        ..initialize().then((_) {
          setState(() {
            isLoading = false;
          });
          _controller!.play();
          _controller!.addListener(_onVideoEnd);
        });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _onVideoEnd() {
    if (_controller!.value.position == _controller!.value.duration) {
      _playNextVideo();
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoEnd);
    _controller?.dispose();
    super.dispose();
  }

  void _playNextVideo() {
    _controller?.removeListener(_onVideoEnd);
    setState(() {
      currentVideoIndex = (currentVideoIndex + 1) % videos.length;
      _controller = VideoPlayerController.network(videos[currentVideoIndex]['videoUrl']!)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
          _controller!.addListener(_onVideoEnd);
        });
    });
  }

  void _playPreviousVideo() {
    _controller?.removeListener(_onVideoEnd);
    setState(() {
      currentVideoIndex =
          (currentVideoIndex - 1 + videos.length) % videos.length;
      _controller = VideoPlayerController.network(videos[currentVideoIndex]['videoUrl']!)
        ..initialize().then((_) {
          setState(() {});
          _controller!.play();
          _controller!.addListener(_onVideoEnd);
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : _controller != null && _controller!.value.isInitialized
          ? Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller!.value.isPlaying) {
                  _controller!.pause();
                } else {
                  _controller!.play();
                }
              });
            },
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! < 0) {
                _playNextVideo();
              } else if (details.primaryVelocity! > 0) {
                _playPreviousVideo();
              }
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videos[currentVideoIndex]['title']!,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  videos[currentVideoIndex]['author']!,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: Column(
              children: [
                Icon(Icons.favorite, color: Colors.white, size: 32),
                SizedBox(height: 16),
                Icon(Icons.comment, color: Colors.white, size: 32),
                SizedBox(height: 16),
                Icon(Icons.share, color: Colors.white, size: 32),
              ],
            ),
          ),
        ],
      )
          : Center(child: Text("Loading ကြာနေရင် screen ကိုနှိပ်လိုက်ပါ")),
    );
  }
}
