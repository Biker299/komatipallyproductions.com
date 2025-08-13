import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

import '../transfer/local_http_server.dart';

class SendPage extends StatefulWidget {
  const SendPage({super.key});

  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  final LocalFileServer _server = LocalFileServer();
  List<File> _selectedFiles = [];
  bool _starting = false;

  @override
  void dispose() {
    _server.stop();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final res = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg', 'jpeg', 'png', 'gif', 'heic', 'heif', 'dng',
        'mp4', 'mov', 'm4v', 'avi', 'mkv', 'webm'
      ],
      withData: false,
    );
    if (res == null) return;

    final files = <File>[];
    for (final pf in res.files) {
      if (pf.path != null) {
        files.add(File(pf.path!));
      }
    }
    setState(() => _selectedFiles = files);
  }

  Future<void> _startSession() async {
    if (_selectedFiles.isEmpty) return;
    setState(() => _starting = true);
    try {
      await _server.start(_selectedFiles);
      setState(() {});
    } finally {
      setState(() => _starting = false);
    }
  }

  Future<void> _stopSession() async {
    await _server.stop();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final baseUrl = _server.baseUrl;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Send original photos and videos to another device on the same Wi‑Fi. No compression.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.photo_library),
            label: const Text('Select files'),
          ),
          const SizedBox(height: 8),
          if (_selectedFiles.isNotEmpty)
            Text('${_selectedFiles.length} selected'),
          const SizedBox(height: 16),
          if (!_server.isRunning)
            FilledButton.icon(
              onPressed: _starting || _selectedFiles.isEmpty ? null : _startSession,
              icon: _starting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Start session'),
            ),
          if (_server.isRunning) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    baseUrl ?? '',
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                IconButton(
                  onPressed: baseUrl == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: baseUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Link copied')),
                          );
                        },
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy link',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (baseUrl != null)
              Center(
                child: QrImageView(
                  data: baseUrl,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _stopSession,
              icon: const Icon(Icons.stop),
              label: const Text('Stop session'),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }
}