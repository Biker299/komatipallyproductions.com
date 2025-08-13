import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:open_filex/open_filex.dart';

import '../transfer/remote_client.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final TextEditingController _linkCtrl = TextEditingController();

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  void _openScanner() async {
    final baseUrl = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ScanQrScreen()),
    );
    if (!mounted) return;
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _linkCtrl.text = baseUrl;
      _openSession(baseUrl);
    }
  }

  void _openSession(String baseUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReceiveSessionScreen(baseUrl: baseUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('Scan the sender\'s QR code or paste the link.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _linkCtrl,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Or paste link here',
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              final url = _linkCtrl.text.trim();
              if (url.isNotEmpty) _openSession(url);
            },
            icon: const Icon(Icons.link),
            label: const Text('Open link'),
          ),
        ],
      ),
    );
  }
}

class _ScanQrScreen extends StatefulWidget {
  const _ScanQrScreen();

  @override
  State<_ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<_ScanQrScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final val = codes.first.rawValue;
    if (val != null && val.startsWith('http')) {
      _handled = true;
      Navigator.of(context).pop(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}

class ReceiveSessionScreen extends StatefulWidget {
  const ReceiveSessionScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<ReceiveSessionScreen> createState() => _ReceiveSessionScreenState();
}

class _ReceiveSessionScreenState extends State<ReceiveSessionScreen> {
  late final RemoteSessionClient _client;
  Future<List<RemoteFileInfo>>? _future;
  final Map<int, _DownloadState> _states = {};

  @override
  void initState() {
    super.initState();
    _client = RemoteSessionClient(widget.baseUrl);
    _future = _client.fetchIndex();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive')),
      body: FutureBuilder<List<RemoteFileInfo>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Failed to load: ${snap.error}'),
            );
          }
          final files = snap.data ?? const [];
          if (files.isEmpty) {
            return const Center(child: Text('No files available'));
          }
          return ListView.separated(
            itemCount: files.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final f = files[i];
              final st = _states[f.index];
              return ListTile(
                title: Text(f.name),
                subtitle: Text(_formatBytes(f.size)),
                trailing: st == null
                    ? FilledButton.icon(
                        onPressed: () => _startDownload(f),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      )
                    : st.completed
                        ? IconButton(
                            onPressed: () => _openFile(st.savedPath!),
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'Open',
                          )
                        : SizedBox(
                            width: 120,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: st.progressTotal > 0
                                        ? st.progressReceived / st.progressTotal
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_progressText(st)),
                              ],
                            ),
                          ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startDownload(RemoteFileInfo f) async {
    setState(() {
      _states[f.index] = _DownloadState();
    });
    try {
      final result = await _client.downloadFile(
        file: f,
        onProgress: (received, total) {
          setState(() {
            final s = _states[f.index]!;
            s.progressReceived = received;
            s.progressTotal = total;
          });
        },
      );
      setState(() {
        final s = _states[f.index]!;
        s.completed = true;
        s.savedPath = result.path;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${result.path}')),
        );
      }
    } catch (e) {
      setState(() {
        _states.remove(f.index);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  void _openFile(String path) {
    OpenFilex.open(path);
  }

  String _progressText(_DownloadState s) {
    final r = _formatBytes(s.progressReceived);
    final t = _formatBytes(s.progressTotal);
    return t == '0 B' ? r : '$r / $t';
  }

  String _formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    return '${size.toStringAsFixed(1)} ${units[unit]}';
  }
}

class _DownloadState {
  int progressReceived = 0;
  int progressTotal = 0;
  bool completed = false;
  String? savedPath;
}