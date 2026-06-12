import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/portfolio_advice.dart';

class PortfolioService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080';
    }
    return Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://127.0.0.1:8080';
  }

  Future<PortfolioAdviceResponse> getPortfolioAdvice({
    required double riskScore,
    required String segment,
    required String label,
    required int horizonYears,
    required String goal,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/portfolio-advice'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "risk_score": riskScore,
          "segment": segment,
          "label": label,
          "horizon_years": horizonYears,
          "goal": goal,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return PortfolioAdviceResponse.fromJson(data);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        throw Exception("Geçersiz veri");
      } else {
        throw Exception("AI şu anda cevap veremiyor");
      }
    } on SocketException {
      throw Exception("Bağlantı hatası");
    } catch (e) {
      if (e.toString().contains("Geçersiz veri") || e.toString().contains("AI şu anda cevap veremiyor")) {
        rethrow;
      }
      throw Exception("Bağlantı hatası");
    }
  }

  Future<String> askAi({
    required String question,
    required String riskLabel,
    required String segment,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/ask-ai'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "question": question,
          "risk_label": riskLabel,
          "segment": segment,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? '';
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        throw Exception("Geçersiz veri");
      } else {
        throw Exception("AI şu anda cevap veremiyor");
      }
    } on SocketException {
      throw Exception("Bağlantı hatası");
    } catch (e) {
      if (e.toString().contains("Geçersiz veri") || e.toString().contains("AI şu anda cevap veremiyor")) {
        rethrow;
      }
      throw Exception("Bağlantı hatası");
    }
  }
}
