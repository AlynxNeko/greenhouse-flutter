import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/bluetooth_provider.dart';

class DevChatPage extends StatefulWidget {
  const DevChatPage({super.key});

  @override
  State<DevChatPage> createState() => _DevChatPageState();
}

class _DevChatPageState extends State<DevChatPage> {
  final TextEditingController _textController = TextEditingController();
  final List<String> chatMessages = [];
  final ScrollController _scrollController = ScrollController();
  
  StreamSubscription<String>? _messageSubscription; 

  @override
  void initState() {
    super.initState();
    // Start listening to the shared stream from BluetoothProvider/Service
    _messageSubscription = context.read<BluetoothProvider>().messageStream.listen((raw) {
      if (mounted) {
        // Log all messages in chat.
        setState(() {
          chatMessages.add("DEVICE: $raw");
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(BluetoothProvider bt) {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      bt.send(message);
      setState(() {
        chatMessages.add("ME: $message");
        _textController.clear();
        _scrollToBottom();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bt = context.read<BluetoothProvider>();
    final isConnected = bt.isConnected;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8.0),
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              final message = chatMessages[index];
              return Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: message.startsWith("ME:") ? Colors.lightBlueAccent : Colors.white,
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 4.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: isConnected,
                  decoration: InputDecoration(
                    hintText: isConnected ? "Enter command..." : "Disconnected",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onSubmitted: isConnected ? (_) => _sendMessage(bt) : null,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: isConnected ? () => _sendMessage(bt) : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}