import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../models/job_model.dart';
import '../services/openai_service.dart';

abstract class JobRepository {
  Future<List<Job>> getJobs();
  Future<Job> addJob(Job job);
  Future<void> updateJob(Job job);
  Future<void> updateJobPositions(List<Job> jobs);
  Future<void> deleteJob(String id);
  Future<String> uploadResume(
      String jobId, Uint8List fileBytes, String fileName);
  Future<String> generateCoverLetter(Job job);
}

class SupabaseJobRepository implements JobRepository {
  final SupabaseClient _client = Supabase.instance.client;
  final OpenAIService _openAIService = OpenAIService();

  @override
  Future<List<Job>> getJobs() async {
    final response = await _client
        .from(AppConstants.jobsTable)
        .select()
        .order('position', ascending: true)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Job.fromJson(json)).toList();
  }

  @override
  Future<Job> addJob(Job job) async {
    // We exclude 'id' from the insert because Supabase generates it.
    // However, the model requires an ID.
    // Strategy: Insert without ID, let Supabase generate it, then return the inserted row.
    final jobData = job.toJson();
    // jobData.remove('id'); // We now want to use the client-generated ID so it matches storage paths

    final response = await _client
        .from(AppConstants.jobsTable)
        .insert(jobData)
        .select()
        .single();

    return Job.fromJson(response);
  }

  @override
  Future<void> updateJob(Job job) async {
    await _client
        .from(AppConstants.jobsTable)
        .update(job.toJson())
        .eq('id', job.id);
  }

  @override
  Future<void> updateJobPositions(List<Job> jobs) async {
    // Supabase doesn't support batch update with different values in one query easily without RPC.
    // We will iterate and update. For small lists (kanban columns), this is acceptable.
    // Optimisation: Use Future.wait to run in parallel.
    await Future.wait(jobs.map((job) {
      return _client
          .from(AppConstants.jobsTable)
          .update({'position': job.position}).eq('id', job.id);
    }));
  }

  @override
  Future<void> deleteJob(String id) async {
    await _client.from(AppConstants.jobsTable).delete().eq('id', id);
  }

  @override
  Future<String> uploadResume(
      String jobId, Uint8List fileBytes, String fileName) async {
    final path = '$jobId/$fileName';
    await _client.storage.from(AppConstants.resumesBucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl =
        _client.storage.from(AppConstants.resumesBucket).getPublicUrl(path);

    return publicUrl;
  }

  @override
  Future<String> generateCoverLetter(Job job) async {
    // For now, we'll just pass the job info.
    // In the future, we could download and parse the resume from resumeUrl
    // to extract text content, but that requires additional PDF parsing libraries
    return await _openAIService.generateCoverLetter(job);
  }
}
