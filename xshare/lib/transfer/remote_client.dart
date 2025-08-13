import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class RemoteSessionClient {
  RemoteSessionClient(this.baseUrl);

  final String baseUrl; // e.g., http://192.168.1.23:53211/s/<token>

  Uri _indexUri() => Uri.parse('$baseUrl/index.json');
  Uri _fileUri(int index) => Uri.parse('$baseUrl/file/$index');

  Future<List<RemoteFileInfo>> fetchIndex() async {
    final res = await http.get(_indexUri());
    if (res.statusCode != 200) {
      throw Exception('Failed to fetch index: ${res.statusCode}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final files = (json['files'] as List)
        .map((e) => RemoteFileInfo(
              index: e['index'] as int,
              name: e['name'] as String,
              size: (e['size'] as num).toInt(),
              mime: e['mime'] as String?,
            ))
        .toList();
    return files;
  }

  Future<DownloadedFile> downloadFile({
    required RemoteFileInfo file,
    void Function(int received, int total)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', _fileUri(file.index));
      final streamed = await client.send(req);
      if (streamed.statusCode != 200) {
        throw Exception('Failed to download: ${streamed.statusCode}');
      }

      final total = file.size;
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/${file.name}';
      final outFile = File(savePath);
      if (outFile.existsSync()) {
        await outFile.delete();
      }
      final sink = outFile.openWrite();

      int received = 0;
      await for (final chunk in streamed.stream) {
        received += chunk.length;
        sink.add(chunk);
        if (onProgress != null) {
          onProgress(received, total);
        }
      }
      await sink.flush();
      await sink.close();

      return DownloadedFile(path: savePath, size: total);
    } finally {
      client.close();
    }
  }
}

class RemoteFileInfo {
  RemoteFileInfo({required this.index, required this.name, required this.size, this.mime});
  final int index;
  final String name;
  final int size;
  final String? mime;
}

class DownloadedFile {
  DownloadedFile({required this.path, required this.size});
  final String path;
  final int size;
}