// community_post.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String authorName;
  final DateTime timestamp;
  final String body;
  final String? imagePath; // <– path lokal, bisa null jika tidak ada gambar
  final int likeCount;
  final int loveCount;
  final int hahaCount;
  final int sadCount;
  final int angryCount;
  final int commentCount;

  CommunityPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.timestamp,
    required this.body,
    this.imagePath,
    this.likeCount = 0,
    this.loveCount = 0,
    this.hahaCount = 0,
    this.sadCount = 0,
    this.angryCount = 0,
    this.commentCount = 0,
  });

  factory CommunityPost.fromJson(String id, Map<String, dynamic> json) {
    final rawTs = json['timestamp'];
    DateTime parsedTimestamp;
    if (rawTs != null && rawTs is Timestamp) {
      parsedTimestamp = rawTs.toDate();
    } else {
      parsedTimestamp = DateTime.now();
    }

    return CommunityPost(
      id: id,
      authorId: (json['authorId'] ?? '') as String,
      authorName: (json['authorName'] ?? '') as String,
      timestamp: parsedTimestamp,
      body: (json['body'] ?? '') as String,
      imagePath: json['imagePath'] as String?, // <― Path lokal di Firestore
      likeCount: (json['likeCount'] ?? 0) as int,
      loveCount: (json['loveCount'] ?? 0) as int,
      hahaCount: (json['hahaCount'] ?? 0) as int,
      sadCount: (json['sadCount'] ?? 0) as int,
      angryCount: (json['angryCount'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'timestamp': Timestamp.fromDate(timestamp),
      'body': body,
      'imagePath': imagePath, // <― Simpan path lokal jika ada
      'likeCount': likeCount,
      'loveCount': loveCount,
      'hahaCount': hahaCount,
      'sadCount': sadCount,
      'angryCount': angryCount,
      'commentCount': commentCount,
    };
  }
}
