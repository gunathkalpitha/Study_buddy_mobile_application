
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';

class ChatTab extends ConsumerStatefulWidget {
  final String groupId;

  const ChatTab({super.key, required this.groupId});

  @override
  ConsumerState<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends ConsumerState<ChatTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100, // Extra scroll
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(groupMessagesProvider(widget.groupId));
    final currentUser = ref.watch(currentUserProvider);

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'No messages yet.\nStart the conversation!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                );
              }
              
              // Auto-scroll on new messages
              // Note: In a real app, careful with this if user scrolled up
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final isMe = msg.senderId == currentUser?.id;
                  final showDate = index == 0 ||
                      messages[index - 1].timestamp.day != msg.timestamp.day;

                  return Column(
                    children: [
                      if (showDate)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                DateFormat.yMMMd().format(msg.timestamp),
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                      _MessageBubble(message: msg, isMe: isMe),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading chat')),
          ),
        ),
        _buildInputArea(context),
      ],
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () => _pickAndSendImage(),
              icon: Icon(Icons.add_photo_alternate_outlined,
                  color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final msg = MessageModel(
      id: const Uuid().v4(),
      text: text,
      senderId: user.id,
      senderName: user.name,
      timestamp: DateTime.now(),
      type: MessageType.text,
    );

    _controller.clear();
    await ref.read(repositoryProvider).sendMessage(widget.groupId, msg);
    // Provider stream will auto-update UI
  }

  void _pickAndSendImage() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // In a real app, you would upload the image to a storage service
        // and get back a URL. For now, we'll use the file name as a placeholder.
        final imageUrl = file.name; // In production: upload to cloud storage
        
        final msg = MessageModel(
          id: const Uuid().v4(),
          text: imageUrl,
          senderId: user.id,
          senderName: user.name,
          timestamp: DateTime.now(),
          type: MessageType.image,
        );

        await ref.read(repositoryProvider).sendMessage(widget.groupId, msg);
        
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Image "${file.name}" sent (mock)')),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bgColor = isMe ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final textColor = isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: align,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                message.senderName,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  child: Text(message.senderName[0].toUpperCase()),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.type == MessageType.image) ...[
                        Container(
                          constraints: const BoxConstraints(maxWidth: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: textColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.image,
                                size: 48,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '(Mock image - upload to be implemented)',
                                style: TextStyle(
                                  color: textColor.withValues(alpha: 0.5),
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Text(
                          message.text,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.jm().format(message.timestamp),
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
