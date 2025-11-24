import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../models/job_model.dart';

/// Service for generating cover letters using OpenAI.
///
/// Very manual, because for heaven's sake, the API isn't versioned.
class OpenAIService {
  Future<String> generateCoverLetter(Job job, {String? resumeText}) async {
    try {
      // Call Supabase Edge Function instead of OpenAI directly
      final response = await http.post(
        Uri.parse(
            '${AppConstants.supabaseUrl}/functions/v1/generate-cover-letter'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
          'apikey': AppConstants.supabaseAnonKey,
        },
        body: jsonEncode({
          'jobTitle': job.title,
          'company': job.company,
          'description': job.description,
          'resumeUrl': job.resumeUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['coverLetter'].toString().trim();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'Failed to generate cover letter: ${error['error'] ?? response.body}');
      }
    } catch (e) {
      throw Exception('Error generating cover letter: $e');
    }
  }
}
