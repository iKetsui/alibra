import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Your Gemini API key
  static const String _apiKey = 'AIzaSyBUnOwFMbXMeCeRwXowA7gTO12sBarwYyg'; // Replace with your actual key
  
  // Choose your model based on needs:
  // - 'gemini-2.5-flash': Fast, balanced (250 requests/day)
  // - 'gemini-2.5-flash-lite': Most economical (1000 requests/day)
  // - 'gemini-2.5-pro': Most powerful, 1M context (100 requests/day)
  static const String _model = 'gemini-2.5-flash-lite'; // Start with this for generous quota
  
  static Future<String> chat(String message) async {
    try {
      print('📤 Sending request to Google Gemini...');
      print('Using model: $_model');
      
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text': '''
You are Librarian AI, a helpful assistant specialized in books, literature, and reading recommendations. 
You help users find books, suggest readings, explain literary concepts, and discuss authors and genres.
Keep responses concise, friendly, and helpful (2-4 sentences unless asked for more detail).

User query: $message
'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 800,
            'topP': 0.9,
            'topK': 40
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract the text from Gemini's response
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (text != null) {
          print('✅ Response received');
          return text;
        } else {
          print('⚠️ No text in response');
          return 'I received your message but couldn\'t generate a proper response.';
        }
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        
        // Handle specific error cases
        if (response.statusCode == 429) {
          return 'Rate limit reached. Please try again in a moment.';
        } else if (response.statusCode == 403) {
          return 'API key error. Please check your configuration.';
        } else {
          return 'Sorry, I encountered an error. Please try again.';
        }
      }
    } catch (e) {
      print('❌ Exception: $e');
      return 'Network error. Please check your connection.';
    }
  }
  
  // Optional: Method to get available models (for debugging)
  static Future<void> listAvailableModels() async {
    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$_apiKey');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 Available models:');
        for (var model in data['models']) {
          print('  - ${model['name']} (${model['description']})');
        }
      } else {
        print('❌ Failed to list models: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception: $e');
    }
  }
}