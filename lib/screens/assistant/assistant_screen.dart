import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/assistant_message.dart';
import '../../services/ai_assistant_service.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<AssistantMessage> _messages = [
    AssistantMessage(
      id: 'assistant-welcome',
      role: 'assistant',
        content:
          'Xin chào! Mình là SmartLife Assistant. Bạn có thể hỏi về deadline, học tập, chi tiêu hoặc xin gợi ý nhanh.',
      createdAt: DateTime.now(),
    ),
  ];
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trợ lý AI')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final item = _messages[index];
                final isUser = item.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isUser
                          ? Colors.indigo.withValues(alpha: 0.16)
                          : Colors.teal.withValues(alpha: 0.16),
                    ),
                    child: Text(item.content),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn...',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : () => _send(context),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(BuildContext context) async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _sending = true;
      _messages.add(
        AssistantMessage(
          id: 'user-${DateTime.now().microsecondsSinceEpoch}',
          role: 'user',
          content: prompt,
          createdAt: DateTime.now(),
        ),
      );
      _controller.clear();
    });

    final assistant = context.read<AIAssistantService>();
    final reply = await assistant.reply(prompt);

    if (!mounted) return;
    setState(() {
      _messages.add(
        AssistantMessage(
          id: 'assistant-${DateTime.now().microsecondsSinceEpoch}',
          role: 'assistant',
          content: reply,
          createdAt: DateTime.now(),
        ),
      );
      _sending = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
