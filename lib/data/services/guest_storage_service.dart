import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';

class GuestStorageService {
  static const String _jobCountKey = 'guest_job_count';
  static const String _generationCountKey = 'guest_generation_count';
  static const String _guestJobsKey = 'guest_jobs';

  static const int maxJobs = 1;
  static const int maxGenerations = 1;

  Future<bool> canAddJob() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_jobCountKey) ?? 0;
    return count < maxJobs;
  }

  Future<bool> canGenerateCoverLetter() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_generationCountKey) ?? 0;
    return count < maxGenerations;
  }

  Future<void> incrementJobCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_jobCountKey) ?? 0;
    await prefs.setInt(_jobCountKey, count + 1);
  }

  Future<void> incrementGenerationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_generationCountKey) ?? 0;
    await prefs.setInt(_generationCountKey, count + 1);
  }

  Future<int> getJobCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_jobCountKey) ?? 0;
  }

  Future<int> getGenerationCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_generationCountKey) ?? 0;
  }

  Future<List<Job>> getGuestJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final jobsJson = prefs.getString(_guestJobsKey);
    if (jobsJson == null) return [];

    final List<dynamic> jobsList = jsonDecode(jobsJson);
    return jobsList.map((json) => Job.fromJson(json)).toList();
  }

  Future<void> saveGuestJob(Job job) async {
    final prefs = await SharedPreferences.getInstance();
    final jobs = await getGuestJobs();

    // Check if job already exists, update it
    final existingIndex = jobs.indexWhere((j) => j.id == job.id);
    if (existingIndex != -1) {
      jobs[existingIndex] = job;
    } else {
      jobs.add(job);
    }

    final jobsJson = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await prefs.setString(_guestJobsKey, jobsJson);
  }

  Future<void> deleteGuestJob(String jobId) async {
    final prefs = await SharedPreferences.getInstance();
    final jobs = await getGuestJobs();
    jobs.removeWhere((j) => j.id == jobId);

    final jobsJson = jsonEncode(jobs.map((j) => j.toJson()).toList());
    await prefs.setString(_guestJobsKey, jobsJson);
  }

  Future<void> clearGuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jobCountKey);
    await prefs.remove(_generationCountKey);
    await prefs.remove(_guestJobsKey);
  }
}
