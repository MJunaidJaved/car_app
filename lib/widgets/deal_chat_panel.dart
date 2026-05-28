import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../services/deal_chat_service.dart';
import '../utils/app_colors.dart';

class DealChatPanel extends StatefulWidget {
  final String dealId;
  final double height;

  const DealChatPanel({
    super.key,
    required this.dealId,
    this.height = 220,
  });

  @override
  State<DealChatPanel> createState() => _DealChatPanelState();
}

class _DealChatPanelState extends State<DealChatPanel> {
  final _chat = DealChatService();
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;
    final role = user.role == 'captain' ? 'captain' : 'passenger';
    try {
      await _chat.sendMessage(
        dealId: widget.dealId,
        text: _input.text,
        senderRole: role,
      );
      _input.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message failed: $e'), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context, listen: false).user?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Messages', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.bark)),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chat.messagesStream(widget.dealId),
            builder: (context, snap) {
              final messages = snap.data ?? [];
              if (messages.isEmpty) {
                return const Center(
                  child: Text('No messages yet', style: TextStyle(color: AppColors.sage)),
                );
              }
              return ListView.builder(
                controller: _scroll,
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[i];
                  final isMe = m['senderId'] == uid;
                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.moss : AppColors.bg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        m['text']?.toString() ?? '',
                        style: TextStyle(
                          color: isMe ? AppColors.white : AppColors.bark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AppColors.bg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _send,
              icon: const Icon(Icons.send_rounded, color: AppColors.moss),
            ),
          ],
        ),
      ],
    );
  }
}

