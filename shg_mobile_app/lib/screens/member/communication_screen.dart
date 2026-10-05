import 'package:flutter/material.dart';

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final String groupName = "Test SHG Group";
  final String currentUser = "Test User";

  // Mock messages
  final List<Map<String, dynamic>> messages = [
    {
      "id": "1",
      "sender": "Admin",
      "role": "admin",
      "message": "Welcome to the group chat!",
      "timestamp": "10:00 AM"
    },
    {
      "id": "2",
      "sender": "Member A",
      "role": "member",
      "message": "Hello everyone",
      "timestamp": "10:05 AM"
    }
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      messages.add({
        "id": DateTime.now().millisecondsSinceEpoch.toString(),
        "sender": currentUser,
        "role": "member",
        "message": _messageController.text.trim(),
        "timestamp": "Just now"
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Communication'),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Group Chat"),
              Tab(text: "Gemini AI"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGroupChat(),
            _buildGeminiChat(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupChat() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          width: double.infinity,
          child: Text(
            "$groupName Chat",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              bool isMe = msg['sender'] == currentUser;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    if (!isMe) ...[
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.teal,
                        child: Text(msg['sender'][0].toUpperCase(), style: const TextStyle(fontSize: 12, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(msg['sender'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: msg['role'] == 'admin' ? Colors.purple.shade100 : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(msg['role'], style: const TextStyle(fontSize: 8)),
                              ),
                              const SizedBox(width: 4),
                              Text(msg['timestamp'], style: const TextStyle(fontSize: 10, color: Colors.black54)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.teal.shade100 : Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12).copyWith(
                                topLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
                                topRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
                              ),
                            ),
                            child: Text(msg['message']),
                          ),
                        ],
                      ),
                    ),
                    if (isMe) const SizedBox(width: 8),
                  ],
                ),
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildGeminiChat() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.smart_toy, size: 64, color: Colors.teal),
        const SizedBox(height: 16),
        const Text("Gemini AI Assistant", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Ask questions about farming, financial literacy,\nand more. Coming soon!", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          )
        ]
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
              ),
            )
          ],
        ),
      ),
    );
  }
}
