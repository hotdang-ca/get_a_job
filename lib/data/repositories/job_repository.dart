import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../models/job_model.dart';
import '../services/openai_service.dart';
import '../services/guest_storage_service.dart';

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
  final GuestStorageService _guestStorage = GuestStorageService();

  @override
  Future<List<Job>> getJobs() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return await _guestStorage.getGuestJobs();
    }

    final response = await _client
        .from(AppConstants.jobsTable)
        .select()
        .eq('user_id', user.id)
        .order('position', ascending: true)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Job.fromJson(json)).toList();
  }

  @override
  Future<Job> addJob(Job job) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      await _guestStorage.saveGuestJob(job);
      await _guestStorage.incrementJobCount();
      return job;
    }

    // Ensure the job has the correct user_id
    final jobWithUserId = job.copyWith(userId: user.id);
    final jobData = jobWithUserId.toJson();

    final response = await _client
        .from(AppConstants.jobsTable)
        .insert(jobData)
        .select()
        .single();

    return Job.fromJson(response);
  }

  @override
  Future<void> updateJob(Job job) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      await _guestStorage.saveGuestJob(job);
      return;
    }

    // update job with userId
    final jobWithUserId = job.copyWith(userId: user.id);
    final jobData = jobWithUserId.toJson();

    await _client
        .from(AppConstants.jobsTable)
        .update(
          jobData,
        )
        .eq('id', job.id);
  }

  @override
  Future<void> updateJobPositions(List<Job> jobs) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      for (final job in jobs) {
        await _guestStorage.saveGuestJob(job);
      }
      return;
    }

    // Supabase doesn't support batch update with different values in one query easily without RPC.
    // We will iterate and update. For small lists (kanban columns), this is acceptable.
    // Optimisation: Use Future.wait to run in parallel.
    await Future.wait(jobs.map((job) {
      return _client.from(AppConstants.jobsTable).update(
        {'position': job.position},
      ).eq('id', job.id);
    }));
  }

  @override
  Future<void> deleteJob(String id) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      await _guestStorage.deleteGuestJob(id);
      return;
    }

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
