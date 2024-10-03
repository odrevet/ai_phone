import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';

import '../api.dart';

class SMSView extends StatefulWidget {
  final List<Map<String, String>> conversationHistory;
  final Function addConversation;

  const SMSView(
      {super.key,
      required this.conversationHistory,
      required this.addConversation});

  @override
  _SMSViewState createState() => _SMSViewState();
}

class _SMSViewState extends State<SMSView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom initially
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS View'),
      ),
      body: Column(
        children: [
          Expanded(
            child: widget.conversationHistory.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(fontSize: 20),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.conversationHistory.length,
                    itemBuilder: (context, index) {
                      final message = widget.conversationHistory[index];

                      return ChatBubble(
                        alignment: message['role'] == 'user'
                            ? Alignment.topLeft
                            : Alignment.topRight,
                        clipper: ChatBubbleClipper1(
                            type: message['role'] == 'user'
                                ? BubbleType.receiverBubble
                                : BubbleType.sendBubble),
                        backGroundColor: message['role'] == 'user'
                            ? const Color(0xffE7E7ED)
                            : Colors.grey,
                        margin: const EdgeInsets.only(top: 20),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.addConversation("user", message);
      _scrollToBottom();

      _messageController.clear();

      sendChatCompletion(widget.conversationHistory, "assistant").then((response) {
        String messageContent = response['choices'][0]['message']['content'];
        widget.addConversation("assistant", messageContent);
        _scrollToBottom();
      });
    }
  }
}
