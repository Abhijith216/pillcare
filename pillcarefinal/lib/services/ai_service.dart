import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models/medication.dart';
import '../services/medication_store.dart';

class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  // Using Groq or OpenRouter (OpenAI compatible)
  // For Groq: https://api.groq.com/openai/v1
  // For OpenRouter: https://openrouter.ai/api/v1
  static const _baseUrl = 'https://api.groq.com/openai/v1';
  static const _apiKey = 'YOUR_GROQ_API_KEY_HERE'; // Replace with your Groq API key
  static const _model = 'llama-3.3-70b-versatile';

  static const _systemPrompt =
      'You are PillCare AI, a helpful medication assistant. '
      'You provide general health information and medication guidance. '
      'Always remind users to consult their doctor for medical decisions. '
      'Keep responses concise, friendly, and formatted with bullet points when listing items. '
      'Never diagnose conditions or prescribe medication. '
      'If asked about drug interactions, provide general knowledge but emphasize consulting a pharmacist.';

  List<Map<String, String>> _history = [];

  String _buildMedicationContext() {
    final store = MedicationStore();
    final meds = store.medications;
    if (meds.isEmpty) return 'The user currently has no medications tracked.';

    final buffer = StringBuffer('Current medications:\n');
    for (final m in meds) {
      buffer.writeln('- ${m.name} ${m.dosage}, ${m.instruction}, scheduled at ${m.time}, '
          'taken today: ${m.takenToday}, refill: ${m.refillCount}/${m.refillTotal}');
    }
    return buffer.toString();
  }

  void _initHistory() {
    if (_history.isEmpty) {
      _history.add({'role': 'system', 'content': _systemPrompt});
      _history.add({
        'role': 'user',
        'content': 'Here is context about my medications:\n${_buildMedicationContext()}\n'
            'Please keep this in mind when answering my questions.'
      });
      _history.add({
        'role': 'assistant',
        'content': 'I have your medication information. I\'m ready to help you with any questions '
            'about your medications, schedules, or general health tips. How can I help? 😊'
      });
    }
  }

  void resetChat() {
    _history = [];
  }

  /// Send a chat message and get a streamed response
  Stream<String> sendMessageStream(String message) async* {
    try {
      _initHistory();
      _history.add({'role': 'user', 'content': message});

      final request = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
      request.headers.addAll({
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      });

      request.body = jsonEncode({
        'model': _model,
        'messages': _history,
        'stream': true,
        'temperature': 0.7,
      });

      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        throw Exception('API Error (${response.statusCode}): $errorBody');
      }

      String fullContent = '';
      await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          
          try {
            final decoded = jsonDecode(data);
            final content = decoded['choices'][0]['delta']['content'] as String?;
            if (content != null) {
              fullContent += content;
              yield content;
            }
          } catch (e) {
            dev.log('Error decoding stream chunk: $e');
          }
        }
      }
      
      _history.add({'role': 'assistant', 'content': fullContent});
    } catch (e, st) {
      dev.log('AI stream error: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Send a message and get the full response
  Future<String> sendMessage(String message) async {
    try {
      _initHistory();
      _history.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': _history,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final content = decoded['choices'][0]['message']['content'] as String;
        _history.add({'role': 'assistant', 'content': content});
        return content;
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e, st) {
      dev.log('AI message error: $e', error: e, stackTrace: st);
      return 'Sorry, I couldn\'t process that. Error: $e';
    }
  }

  /// Generate health insights based on current medications
  Future<String> generateHealthInsights() async {
    try {
      final context = _buildMedicationContext();
      final prompt = '''Based on the following medication data, provide a brief health insight summary in 2-3 short bullet points. 
Focus on: adherence tips, timing optimization, or general wellness advice related to these medications.
Keep it very concise (under 80 words total).

$context''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['choices'][0]['message']['content'] as String;
      } else {
        return 'Unable to generate insights right now. (${response.statusCode})';
      }
    } catch (e, st) {
      dev.log('AI insights error: $e', error: e, stackTrace: st);
      return 'Unable to connect to AI service. Error: $e';
    }
  }

  /// Check for potential drug interactions
  Future<String> checkInteractions(String newMedName) async {
    try {
      final store = MedicationStore();
      final existing = store.medications.map((m) => '${m.name} (${m.dosage})').join(', ');
      if (existing.isEmpty) return 'No existing medications to check against.';

      final prompt = '''The user is considering adding "$newMedName" to their medication list.
Their current medications are: $existing.

Provide a VERY brief safety note (2-3 sentences max) about potential interactions or things to watch for. 
Always end by recommending they consult their pharmacist or doctor.
If there are no common interactions, say so reassuringly.''';

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['choices'][0]['message']['content'] as String;
      } else {
        return 'Unable to check interactions right now.';
      }
    } catch (e, st) {
      dev.log('AI interaction check error: $e', error: e, stackTrace: st);
      return 'Unable to check interactions. Please consult your pharmacist.';
    }
  }
}

