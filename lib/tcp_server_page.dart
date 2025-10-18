
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class TCPServerPage extends StatefulWidget {
  const TCPServerPage({super.key});

  @override
  State<TCPServerPage> createState() => _TCPServerPageState();
}

class _TCPServerPageState extends State<TCPServerPage> {
  ServerSocket? _server;
  String _serverStatus = "Server is stopped";
  String _receivedMessage = "";
  final TextEditingController _messageController = TextEditingController();
  final List<Socket> _clients = [];

  @override
  void initState() {
    super.initState();
  }

  void _startServer() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, 1234);
      _server!.listen(_handleClient);
      if (mounted) {
        setState(() {
          _serverStatus = "Server is running on ${_server!.address.host}:${_server!.port}";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _serverStatus = "Error starting server: $e";
        });
      }
    }
  }

  void _handleClient(Socket client) {
    if (mounted) {
      setState(() {
        _clients.add(client);
      });
    }

    client.listen(
      (data) {
        if (mounted) {
          setState(() {
            _receivedMessage = utf8.decode(data);
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _clients.remove(client);
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _clients.remove(client);
          });
        }
      },
    );
  }

  void _stopServer() {
    for (var client in _clients) {
      client.close();
    }
    _server?.close();
    if (mounted) {
      setState(() {
        _server = null;
        _serverStatus = "Server is stopped";
        _clients.clear();
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      for (var client in _clients) {
        client.write(_messageController.text);
      }
      _messageController.clear();
    }
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TCP Server"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_serverStatus),
            Text("Connected clients: ${_clients.length}"),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _server == null ? _startServer : null,
                  child: const Text("Start Server"),
                ),
                ElevatedButton(
                  onPressed: _server != null ? _stopServer : null,
                  child: const Text("Stop Server"),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: "Message to clients",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sendMessage,
              child: const Text("Send Message"),
            ),
            const SizedBox(height: 16),
            const Text("Last Received Message:"),
            Text(_receivedMessage, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
