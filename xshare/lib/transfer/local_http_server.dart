import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mime/mime.dart';
import 'package:network_info_plus/network_info_plus.dart';

class SharedFile {
  SharedFile({
    required this.index,
    required this.file,
    required this.displayName,
    required this.sizeBytes,
    required this.mimeType,
  });

  final int index;
  final File file;
  final String displayName;
  final int sizeBytes;
  final String? mimeType;
}

class LocalFileServer {
  HttpServer? _server;
  String? _ipAddress;
  int? _port;
  String? _token;
  List<SharedFile> _files = [];

  bool get isRunning => _server != null;
  String? get ipAddress => _ipAddress;
  int? get port => _port;
  String? get token => _token;

  String? get baseUrl {
    if (_ipAddress == null || _port == null || _token == null) return null;
    return 'http://$_ipAddress:$_port/s/$_token';
    // Receiver will use `${baseUrl}/index.json` and `${baseUrl}/file/<index>`
  }

  Future<void> start(List<File> files) async {
    if (isRunning) {
      await stop();
    }

    _files = List.generate(files.length, (i) {
      final f = files[i];
      final stat = f.statSync();
      final name = f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : 'file_$i';
      return SharedFile(
        index: i,
        file: f,
        displayName: name,
        sizeBytes: stat.size,
        mimeType: lookupMimeType(f.path),
      );
    });

    _ipAddress = await _resolveLocalIpAddress();
    _token = _generateToken();

    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0, shared: true);
    _port = _server!.port;

    // Serve requests
    unawaited(_serve());
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _port = null;
    _token = null;
    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<void> _serve() async {
    final server = _server;
    if (server == null) return;

    await for (final req in server) {
      try {
        // Basic CORS for convenience
        req.response.headers.set('Access-Control-Allow-Origin', '*');
        req.response.headers.set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
        req.response.headers.set('Access-Control-Allow-Headers', 'Content-Type');

        if (req.method == 'OPTIONS') {
          await req.response.close();
          continue;
        }

        if (_token == null) {
          _notFound(req);
          continue;
        }

        // Expected paths: /s/<token>/index.json, /s/<token>/file/<index>
        final segments = req.uri.pathSegments;
        if (segments.length < 2 || segments[0] != 's' || segments[1] != _token) {
          _notFound(req);
          continue;
        }

        if (segments.length == 3 && segments[2] == 'index.json') {
          await _handleIndexJson(req);
          continue;
        }

        if (segments.length == 4 && segments[2] == 'file') {
          final index = int.tryParse(segments[3]);
          if (index == null || index < 0 || index >= _files.length) {
            _notFound(req);
            continue;
          }
          await _handleFile(req, index);
          continue;
        }

        // Root path: show simple HTML with instructions
        if (segments.length == 2) {
          await _handleRootHtml(req);
          continue;
        }

        _notFound(req);
      } catch (_) {
        _serverError(req);
      }
    }
  }

  Future<void> _handleRootHtml(HttpRequest req) async {
    final html = StringBuffer()
      ..writeln('<!doctype html>')
      ..writeln('<html><head><meta name="viewport" content="width=device-width, initial-scale=1" />')
      ..writeln('<title>XShare Session</title>')
      ..writeln('<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial;padding:16px;line-height:1.5;} .file{margin:8px 0;} .name{font-weight:600;} .size{color:#666;font-size:0.9em;}</style>')
      ..writeln('</head><body>')
      ..writeln('<h2>Files</h2>');

    for (final sf in _files) {
      final size = _formatBytes(sf.sizeBytes);
      final href = 'file/${sf.index}';
      html.writeln('<div class="file"><span class="name">${_escapeHtml(sf.displayName)}</span> ');
      html.writeln('<span class="size">($size)</span> — ');
      html.writeln('<a href="$href">Download</a></div>');
    }

    html.writeln('<p>Programmatic access: <code>index.json</code> and <code>file/{index}</code></p>');
    html.writeln('</body></html>');

    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.html;
    req.response.write(html.toString());
    await req.response.close();
  }

  Future<void> _handleIndexJson(HttpRequest req) async {
    final list = _files
        .map((f) => {
              'index': f.index,
              'name': f.displayName,
              'size': f.sizeBytes,
              'mime': f.mimeType,
            })
        .toList();

    final payload = jsonEncode({'files': list});
    req.response.statusCode = 200;
    req.response.headers.contentType = ContentType.json;
    req.response.write(payload);
    await req.response.close();
  }

  Future<void> _handleFile(HttpRequest req, int index) async {
    final sf = _files[index];
    final file = sf.file;
    if (!file.existsSync()) {
      _notFound(req);
      return;
    }

    final mime = sf.mimeType ?? lookupMimeType(file.path) ?? 'application/octet-stream';

    // HEAD: just headers
    if (req.method == 'HEAD') {
      req.response.statusCode = 200;
      req.response.headers.set(HttpHeaders.contentTypeHeader, mime);
      req.response.headers.set(HttpHeaders.contentLengthHeader, sf.sizeBytes);
      req.response.headers.set(HttpHeaders.contentDispositionHeader, 'attachment; filename="${_sanitizeHeaderFilename(sf.displayName)}"');
      await req.response.close();
      return;
    }

    if (req.method != 'GET') {
      req.response.statusCode = 405; // Method Not Allowed
      await req.response.close();
      return;
    }

    req.response.statusCode = 200;
    req.response.headers.set(HttpHeaders.contentTypeHeader, mime);
    req.response.headers.set(HttpHeaders.contentLengthHeader, sf.sizeBytes);
    req.response.headers.set(HttpHeaders.contentDispositionHeader, 'attachment; filename="${_sanitizeHeaderFilename(sf.displayName)}"');

    final stream = file.openRead();
    await req.response.addStream(stream);
    await req.response.close();
  }

  void _notFound(HttpRequest req) {
    req.response.statusCode = 404;
    req.response.close();
  }

  void _serverError(HttpRequest req) {
    req.response.statusCode = 500;
    req.response.close();
  }

  Future<String> _resolveLocalIpAddress() async {
    // Prefer Wi-Fi IPv4
    try {
      final info = NetworkInfo();
      final wifiIP = await info.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        return wifiIP;
      }
    } catch (_) {}

    // Fallback: first non-loopback IPv4
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
    for (final ni in interfaces) {
      for (final addr in ni.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }

    // Last resort
    return InternetAddress.loopbackIPv4.address;
  }

  String _generateToken() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
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

  String _sanitizeHeaderFilename(String name) {
    // Very conservative for Content-Disposition header
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}