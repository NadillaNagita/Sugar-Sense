// comments_sheet.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'registration_data.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUsername; // username (unique) untuk detect mention
  final String currentDisplayName; // nama tampilan (displayName) pengguna
  final String postAuthorId;
  final String postAuthorName;
  final RegistrationData regData;

  const CommentsSheet({
    Key? key,
    required this.postId,
    required this.currentUserId,
    required this.currentUsername,
    required this.currentDisplayName,
    required this.postAuthorId,
    required this.postAuthorName,
    required this.regData,
  }) : super(key: key);

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentCtl = TextEditingController();
  final CollectionReference _postsRef =
      FirebaseFirestore.instance.collection('posts');
  final CollectionReference _usersRef =
      FirebaseFirestore.instance.collection('users');

  /// Tambah komentar baru + simpan commentCount + kirim notif comment & mention
  Future<void> _addComment() async {
    final body = _commentCtl.text.trim();
    if (body.isEmpty) return;

    // 1. Deteksi mention di format "@username"
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(body);
    final List<String> mentionedUsernames = [];
    for (var m in matches) {
      final uname = m.group(1);
      if (uname != null &&
          uname.isNotEmpty &&
          !mentionedUsernames.contains(uname)) {
        mentionedUsernames.add(uname);
      }
    }

    // 2. Siapkan data komentar
    final commentData = {
      "authorId": widget.currentUserId,
      "authorName": widget.currentDisplayName,
      "body": body,
      "timestamp": FieldValue.serverTimestamp(),
      "mentions": mentionedUsernames,
    };

    // 3. Simpan komentar ke Firestore: posts/{postId}/comments
    final commentRef = await _postsRef
        .doc(widget.postId)
        .collection('comments')
        .add(commentData);

    // 4. Increment commentCount di dokumen post utama
    await _postsRef.doc(widget.postId).update({
      "commentCount": FieldValue.increment(1),
    });

    // 5. Kirim notifikasi "comment" ke postAuthor jika berbeda user
    if (widget.postAuthorId != widget.currentUserId) {
      await _usersRef.doc(widget.postAuthorId).collection('notifications').add({
        "type": "comment",
        "fromUserId": widget.currentUserId,
        "fromUserName": widget.currentDisplayName,
        "postId": widget.postId,
        "commentId": commentRef.id,
        "timestamp": FieldValue.serverTimestamp(),
      });
    }

    // 6. Kirim notifikasi "mention" untuk tiap username yang disebut
    for (String uname in mentionedUsernames) {
      final query =
          await _usersRef.where("username", isEqualTo: uname).limit(1).get();
      if (query.docs.isNotEmpty) {
        final mentionedUserId = query.docs.first.id;
        // Hanya kirim mention jika yang di-mention bukan komentator itu sendiri
        if (mentionedUserId != widget.currentUserId) {
          await _usersRef.doc(mentionedUserId).collection('notifications').add({
            "type": "mention",
            "fromUserId": widget.currentUserId,
            "fromUserName": widget.currentDisplayName,
            "postId": widget.postId,
            "commentId": commentRef.id,
            "timestamp": FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // 7. Clear input
    _commentCtl.clear();
    // Bottom sheet akan otomatis menampilkan komentar baru via StreamBuilder
  }

  @override
  Widget build(BuildContext context) {
    final commentsStream = _postsRef
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();

    return Padding(
      // Agar bottom sheet naik saat keyboard muncul
      padding: MediaQuery.of(context).viewInsets,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              'Comments',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: commentsStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text("No comments yet."));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: docs.length,
                    itemBuilder: (context, idx) {
                      final cData = docs[idx].data() as Map<String, dynamic>;
                      final authorName = cData['authorName'] ?? 'Unknown';
                      final body = cData['body'] ?? '';
                      final timestamp =
                          (cData['timestamp'] as Timestamp?)?.toDate() ??
                              DateTime.now();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: Text(
                            authorName.isNotEmpty
                                ? authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(authorName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(body),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM dd, yyyy • HH:mm')
                                  .format(timestamp),
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtl,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _addComment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
