import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String receiverId;
  final String receiverName;
  final String? receiverImage;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.receiverId,
    required this.receiverName,
    this.receiverImage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final Color primaryNavy = const Color(0xFF1E3A8A);

  CollectionReference get _messagesRef => FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .collection('messages');

  @override
  void initState() {
    super.initState();
    _markMessagesRead();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Mark all messages from the other user as read
  Future<void> _markMessagesRead() async {
    try {
      final unread = await _messagesRef
          .where('senderId', isEqualTo: widget.receiverId)
          .where('read', isEqualTo: false)
          .get();

      for (final doc in unread.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || user == null) return;

    _msgController.clear();

    try {
      // Add message with all required fields per Firestore rules
      await _messagesRef.add({
        'text': text,
        'senderId': user!.uid,
        'receiverId': widget.receiverId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
      debugPrint('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: primaryNavy,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryNavy.withOpacity(0.1),
            backgroundImage: widget.receiverImage != null
                ? NetworkImage(widget.receiverImage!)
                : null,
            child: widget.receiverImage == null
                ? Icon(Icons.person, color: primaryNavy, size: 18)
                : null,
          ),
          const SizedBox(width: 10),
          Text(
            widget.receiverName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesRef.orderBy('timestamp', descending: false).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet.\nSay hello! 👋',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading messages: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data!.docs;

        // Auto-scroll on new message
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final isMine = data['senderId'] == user?.uid;
            final text = data['text'] ?? '';
            final ts = data['timestamp'] as Timestamp?;
            final isRead = (data['read'] ?? false) as bool;

            // Show date divider if needed
            Widget? divider;
            if (index == 0 && ts != null) {
              divider = _DateDivider(date: ts.toDate());
            } else if (index > 0 && ts != null) {
              final prevData = docs[index - 1].data() as Map<String, dynamic>?;
              if (prevData != null) {
                final prevTs = prevData['timestamp'] as Timestamp?;
                if (prevTs != null) {
                  final prev = prevTs.toDate();
                  final curr = ts.toDate();
                  if (curr.day != prev.day) {
                    divider = _DateDivider(date: curr);
                  }
                }
              }
            }

            return Column(
              children: [
                if (divider != null) divider,
                _MessageBubble(
                  text: text,
                  isMine: isMine,
                  timestamp: ts?.toDate(),
                  isRead: isRead,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: primaryNavy,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _sendMessage,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bubble Widget ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime? timestamp;
  final bool isRead;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    this.timestamp,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = timestamp != null
        ? '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}'
        : '';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMine ? Colors.white60 : Colors.grey.shade400,
                  ),
                ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: isRead ? Colors.lightBlueAccent : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date Divider ─────────────────────────────────────────────────────────────

class _DateDivider extends StatelessWidget {
  final DateTime date;
  const _DateDivider({required this.date});

  String _label() {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day)
      return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _label(),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }
}
