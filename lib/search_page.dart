import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'video_player_page.dart'; // Import the VideoPlayerPage

class VideoData {
  final String id;
  final String videoUrl;
  final String title;
  final String description;
  final String author;

  VideoData({
    required this.id,
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.author,
  });

  factory VideoData.fromJson(Map<String, dynamic> json) {
    return VideoData(
      id: json['id'],
      videoUrl: json['videoUrl'],
      title: json['title'],
      description: json['description'],
      author: json['author'],
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<VideoData> allVideos = [];
  List<VideoData> filteredVideos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchVideos();
  }

  Future<void> fetchVideos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.5:8000/api/videos'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          allVideos = data.map((item) => VideoData.fromJson(item)).toList();
          filteredVideos = allVideos;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      print('Error fetching videos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterVideos(String query) {
    final filtered = allVideos.where((video) {
      return video.title.toLowerCase().contains(query.toLowerCase()) ||
          video.author.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredVideos = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: _filterVideos,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
          ),
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: filteredVideos.length,
        itemBuilder: (context, index) {
          final video = filteredVideos[index];
          return ListTile(
            title: Text(video.title),
            subtitle: Text(video.author),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerPage(
                    videoUrl: video.videoUrl,
                    title: video.title,
                    author: video.author,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
