import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/risk_result.dart';

class RiskApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://127.0.0.1:8080';
  }

  Future<RiskResult> predict(Map<String, dynamic> answers) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(answers),
    );

    if (response.statusCode == 200) {
      return RiskResult.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }

    throw Exception('API Hatası: ${response.statusCode} - ${response.body}');
  }
}