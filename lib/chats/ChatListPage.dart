import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatpage.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color primaryNavy = const Color(0xFF1E3A8A);

  /// Returns a consistent chatId regardless of who initiated
  String _buildChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: primaryNavy,
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Fetch all users except self to list potential chats
        stream: FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, isNotEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading users: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>?;
              if (data == null) {
                return const SizedBox.shrink();
              }

              final otherId = docs[index].id;
              final name = data['name'] as String? ?? 'Unknown';
              final role = data['role'] as String? ?? 'user';
              final profileImage = data['profileImage'] as String?;
              final chatId = _buildChatId(user!.uid, otherId);

              return _ChatTile(
                chatId: chatId,
                receiverId: otherId,
                name: name,
                role: role,
                profileImage: profileImage,
                currentUserId: user!.uid,
              );
            },
          );
        },
      ),
    );
  }
}

/// A single chat list item that shows latest message via a sub-stream
class _ChatTile extends StatelessWidget {
  final String chatId;
  final String receiverId;
  final String name;
  final String role;
  final String? profileImage;
  final String currentUserId;

  const _ChatTile({
    required this.chatId,
    required this.receiverId,
    required this.name,
    required this.role,
    required this.profileImage,
    required this.currentUserId,
  });

  Color get _roleColor {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Colors.blue;
      case 'admin':
        return Colors.purple;
      case 'pharmacy':
        return Colors.orange;
      case 'ambulance_responder':
        return Colors.red;
      default:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, msgSnap) {
        String lastMsg = 'Start a conversation...';
        String timeStr = '';
        bool hasUnread = false;

        if (msgSnap.hasData && msgSnap.data!.docs.isNotEmpty) {
          try {
            final lastData =
                msgSnap.data!.docs.first.data() as Map<String, dynamic>?;
            if (lastData != null) {
              lastMsg = lastData['text'] as String? ?? '';

              // Check if message is unread and from the other user
              final senderId = lastData['senderId'] as String?;
              final isRead = (lastData['read'] ?? false) as bool;
              hasUnread = senderId != currentUserId && !isRead;

              final ts = lastData['timestamp'] as Timestamp?;
              if (ts != null) {
                final dt = ts.toDate();
                final now = DateTime.now();
                if (dt.year == now.year &&
                    dt.month == now.month &&
                    dt.day == now.day) {
                  timeStr =
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                } else {
                  timeStr = '${dt.day}/${dt.month}';
                }
              }
            }
          } catch (e) {
            debugPrint('Error parsing message data: $e');
          }
        }

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  chatId: chatId,
                  receiverId: receiverId,
                  receiverName: name,
                  receiverImage: profileImage,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: _roleColor.withOpacity(0.1),
                        backgroundImage: profileImage != null
                            ? NetworkImage(profileImage!)
                            : null,
                        child: profileImage == null
                            ? Icon(Icons.person, color: _roleColor, size: 26)
                            : null,
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Name + last message
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: hasUnread
                                    ? Colors.redAccent
                                    : Colors.grey,
                                fontWeight: hasUnread
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _roleColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _roleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lastMsg,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: hasUnread
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
