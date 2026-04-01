import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WhisperService {
  static const _endpoint =
      'https://api.openai.com/v1/audio/transcriptions';

  final String apiKey;

  const WhisperService({required this.apiKey});

  /// 音声ファイルをOpenAI Whisperでテキスト変換する
  Future<String> transcribe(String filePath) async {
    final file = File(filePath);
    final request = http.MultipartRequest('POST', Uri.parse(_endpoint))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'ja'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode != 200) {
      throw Exception('Whisper API error: ${response.statusCode} $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['text'] as String? ?? '';
  }
}
