// community_screen.dart

import 'dart:io';
import 'dart:convert'; // untuk base64Decode

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'home_screen.dart';
import 'diary_screen.dart';
import 'profile_screen.dart';
import 'registration_data.dart';
import 'community_post.dart';
import 'comments_sheet.dart'; // Bottom Sheet untuk komentar

/// Custom FAB location (agar tombol FAB berada di posisi tepat di bawah icon)
class FractionalOffsetFabLocation extends FloatingActionButtonLocation {
  final double fraction;
  const FractionalOffsetFabLocation(this.fraction);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry s) {
    final fabW = s.floatingActionButtonSize.width;
    final sw = s.scaffoldSize.width;
    final x = fraction * sw - fabW / 2;
    final fabH = s.floatingActionButtonSize.height;
    final bottom = s.scaffoldSize.height - s.minViewPadding.bottom;
    final y = bottom - fabH - 16;
    return Offset(x, y);
  }
}

// Predefined FAB locations
final dashboardLocation = FractionalOffsetFabLocation(0.2);
final bookLocation = FractionalOffsetFabLocation(0.375);
final communityLocation = FractionalOffsetFabLocation(0.625);
final personLocation = FractionalOffsetFabLocation(0.875);

class CommunityScreen extends StatefulWidget {
  final RegistrationData regData;
  final String? initialPostId;

  const CommunityScreen({
    Key? key,
    required this.regData,
    this.initialPostId,
  }) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _postsRef = FirebaseFirestore.instance.collection('posts');
  final _usersRef = FirebaseFirestore.instance.collection('users');

  FloatingActionButtonLocation _fabLocation = communityLocation;
  IconData _fabIcon = Icons.calendar_today;

  // Caching user reaction untuk UI (warnai icon)
  final Map<String, String> _userReactions = {};
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.initialPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToPost(widget.initialPostId!);
      });
    }
  }

  Future<void> _scrollToPost(String postId) async {
    final snap = await _postsRef.orderBy('timestamp', descending: true).get();
    final idx = snap.docs.indexWhere((d) => d.id == postId);
    if (idx >= 0) {
      _scrollController.animateTo(
        idx * 300.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _addPost() async {
    final bodyCtl = TextEditingController();
    File? pickedImage;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctxSB, setSB) {
          Future<void> pickImg() async {
            final img = await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 800,
              maxHeight: 800,
              imageQuality: 80,
            );
            if (img != null) setSB(() => pickedImage = File(img.path));
          }

          return AlertDialog(
            title: const Text('Create New Post'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bodyCtl,
                    decoration: const InputDecoration(
                      labelText: 'Write your question or message',
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: pickImg,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Pick Image'),
                  ),
                  if (pickedImage != null) ...[
                    const SizedBox(height: 8),
                    Text(path.basename(pickedImage!.path)),
                    const SizedBox(height: 8),
                    Image.file(
                      pickedImage!,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final userId = 'currentUserId';
                  final userName = widget.regData.name ?? 'Anonymous';
                  final body = bodyCtl.text.trim();
                  if (body.isEmpty && pickedImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Please enter text or select an image.')),
                    );
                    return;
                  }
                  String? imgPath;
                  if (pickedImage != null) {
                    final dir = await getApplicationDocumentsDirectory();
                    final fileName =
                        '${DateTime.now().millisecondsSinceEpoch}${path.extension(pickedImage!.path)}';
                    imgPath =
                        (await pickedImage!.copy('${dir.path}/$fileName')).path;
                  }
                  await _postsRef.add({
                    'authorId': userId,
                    'authorName': userName,
                    'body': body,
                    'imagePath': imgPath ?? '',
                    'timestamp': FieldValue.serverTimestamp(),
                    'likeCount': 0,
                    'loveCount': 0,
                    'hahaCount': 0,
                    'sadCount': 0,
                    'angryCount': 0,
                    'commentCount': 0,
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Post'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
    setState(() => _userReactions.remove(postId));
  }

  void _onReact(String postId, String reactionType, String fieldName) {
    // 1) update UI (warna icon)
    setState(() => _userReactions[postId] = reactionType);
    // 2) increment sekali di Firestore
    _postsRef.doc(postId).update({fieldName: FieldValue.increment(1)});
  }

  Future<void> _onReactWithNotif(
      CommunityPost post, String reactionType, String fieldName) async {
    final currentUserId = 'currentUserId';
    final currentUserName = widget.regData.name ?? 'Anonymous';
    _onReact(post.id, reactionType, fieldName);
    if (post.authorId != currentUserId) {
      await _usersRef.doc(post.authorId).collection('notifications').add({
        'type': 'reaction',
        'fromUserId': currentUserId,
        'fromUserName': currentUserName,
        'postId': post.id,
        'reactionType': reactionType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _openComments(BuildContext ctx, CommunityPost post) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CommentsSheet(
        postId: post.id,
        currentUserId: 'currentUserId',
        currentUsername: 'currentUsername',
        currentDisplayName: widget.regData.name ?? 'Anonymous',
        postAuthorId: post.authorId,
        postAuthorName: post.authorName,
        regData: widget.regData,
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post) {
    final sel = _userReactions[post.id];
    Color iconColor(String type) {
      if (sel == type) {
        switch (type) {
          case 'like':
            return Colors.blue;
          case 'love':
            return Colors.red;
          case 'haha':
            return Colors.orange;
          case 'sad':
            return Colors.blueGrey;
          case 'angry':
            return Colors.redAccent;
        }
      }
      return Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // HEADER
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                post.authorName.isNotEmpty
                    ? post.authorName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(post.timestamp),
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ]),
            ),
            PopupMenuButton<String>(
              onSelected: (v) => v == 'delete' ? _deletePost(post.id) : null,
              itemBuilder: (_) =>
                  [const PopupMenuItem(value: 'delete', child: Text('Delete'))],
              icon: const Icon(Icons.more_horiz, color: Colors.grey),
            ),
          ]),
        ),

        // BODY
        if (post.body.isNotEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(post.body)),
        if ((post.imagePath ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(File(post.imagePath!),
                  width: double.infinity, height: 200, fit: BoxFit.cover),
            ),
          ),

        const Divider(height: 1),

        // REACTION BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            InkWell(
              onTap: () => _onReactWithNotif(post, 'like', 'likeCount'),
              child: Row(children: [
                Icon(Icons.thumb_up_alt_outlined,
                    size: 20, color: iconColor('like')),
                const SizedBox(width: 4),
                Text(post.likeCount.toString(),
                    style: TextStyle(color: iconColor('like'), fontSize: 14)),
              ]),
            ),
            InkWell(
              onTap: () => _onReactWithNotif(post, 'love', 'loveCount'),
              child: Row(children: [
                Icon(Icons.favorite_border, size: 20, color: iconColor('love')),
                const SizedBox(width: 4),
                Text(post.loveCount.toString(),
                    style: TextStyle(color: iconColor('love'), fontSize: 14)),
              ]),
            ),
            InkWell(
              onTap: () => _onReactWithNotif(post, 'haha', 'hahaCount'),
              child: Row(children: [
                Icon(Icons.emoji_emotions_outlined,
                    size: 20, color: iconColor('haha')),
                const SizedBox(width: 4),
                Text(post.hahaCount.toString(),
                    style: TextStyle(color: iconColor('haha'), fontSize: 14)),
              ]),
            ),
            InkWell(
              onTap: () => _onReactWithNotif(post, 'sad', 'sadCount'),
              child: Row(children: [
                Icon(Icons.sentiment_dissatisfied_outlined,
                    size: 20, color: iconColor('sad')),
                const SizedBox(width: 4),
                Text(post.sadCount.toString(),
                    style: TextStyle(color: iconColor('sad'), fontSize: 14)),
              ]),
            ),
            InkWell(
              onTap: () => _onReactWithNotif(post, 'angry', 'angryCount'),
              child: Row(children: [
                Icon(Icons.mood_bad_outlined,
                    size: 20, color: iconColor('angry')),
                const SizedBox(width: 4),
                Text(post.angryCount.toString(),
                    style: TextStyle(color: iconColor('angry'), fontSize: 14)),
              ]),
            ),
            GestureDetector(
              onTap: () => _openComments(context, post),
              child: Row(children: [
                const Icon(Icons.chat_bubble_outline,
                    size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Text(post.commentCount.toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 4),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(200, 33, 0, 83),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Hello, ${widget.regData.name}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addPost,
              color: Colors.white),
          // Mengganti GestureDetector statis dengan StreamBuilder, agar avatar foto berubah otomatis
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user')
                .doc(widget.regData.docID)
                .snapshots(),
            builder: (context, snapUser) {
              if (snapUser.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    child: CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              if (!snapUser.hasData || !snapUser.data!.exists) {
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ProfileScreen(regData: widget.regData)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                );
              }

              final userData =
                  snapUser.data!.data() as Map<String, dynamic>? ?? {};
              final photoBase64 = userData['photoBase64'] as String?;

              if (photoBase64 != null && photoBase64.isNotEmpty) {
                try {
                  final bytes = base64Decode(photoBase64);
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ProfileScreen(regData: widget.regData)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        backgroundImage: MemoryImage(bytes),
                      ),
                    ),
                  );
                } catch (_) {
                  // Jika decode gagal, fallback ke inisial di bawah
                }
              }

              // fallback: menampilkan inisial huruf pertama nama user
              final initial = (widget.regData.name != null &&
                      widget.regData.name!.isNotEmpty)
                  ? widget.regData.name![0].toUpperCase()
                  : 'U';

              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfileScreen(regData: widget.regData)),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade300,
                    child: Text(
                      initial,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 18),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _postsRef.orderBy('timestamp', descending: true).snapshots(),
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Center(child: Text('No posts yet.'));
            }
            final posts = docs
                .map((d) => CommunityPost.fromJson(
                    d.id, d.data() as Map<String, dynamic>))
                .toList();
            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (_, i) => _buildPostCard(posts[i]),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black45,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.dashboard, color: Colors.white),
              onPressed: () {
                setState(() {
                  _fabLocation = dashboardLocation;
                  _fabIcon = Icons.dashboard;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          HomeScreen(registrationData: widget.regData)),
                ).then((_) {
                  setState(() {
                    _fabLocation = communityLocation;
                    _fabIcon = Icons.calendar_today;
                  });
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.book, color: Colors.white),
              onPressed: () {
                setState(() {
                  _fabLocation = bookLocation;
                  _fabIcon = Icons.book;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          DiaryScreen(registrationData: widget.regData)),
                ).then((_) {
                  setState(() {
                    _fabLocation = communityLocation;
                    _fabIcon = Icons.calendar_today;
                  });
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white),
              onPressed: () {
                // Already on Community
              },
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                setState(() {
                  _fabLocation = personLocation;
                  _fabIcon = Icons.person;
                });
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ProfileScreen(regData: widget.regData)),
                ).then((_) {
                  setState(() {
                    _fabLocation = communityLocation;
                    _fabIcon = Icons.calendar_today;
                  });
                });
              },
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: _fabLocation,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(_fabIcon, color: Colors.white),
        onPressed: null,
      ),
    );
  }
}
