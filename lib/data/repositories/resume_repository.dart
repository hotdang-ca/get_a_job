import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../models/resume_model.dart';
import 'package:uuid/uuid.dart';

abstract class ResumeRepository {
  Future<List<Resume>> getResumes();
  Future<Resume> uploadResume(Uint8List fileBytes, String fileName);
  Future<void> deleteResume(String path);
}

class SupabaseResumeRepository implements ResumeRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<Resume>> getResumes() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // List files in the user's folder
    final List<FileObject> objects = await _client.storage
        .from(AppConstants.resumesBucket)
        .list(path: user.id);

    // Map to Resume objects
    return objects.map((obj) {
      final path = '${user.id}/${obj.name}';
      final publicUrl =
          _client.storage.from(AppConstants.resumesBucket).getPublicUrl(path);

      return Resume(
        name: obj.name,
        url: publicUrl,
        path: path,
        createdAt: obj.createdAt != null
            ? DateTime.tryParse(obj.createdAt.toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<Resume> uploadResume(Uint8List fileBytes, String fileName) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // To prevent overwrite issues or just to be safe, we might want to check existence or prepend timestamp.
    // For now, let's prepend a UUID to ensure uniqueness if needed, or just allow overwrite?
    // User request: "upload a new one". Usually implies keeping old ones.
    // Let's prepend a short ID or timestamp to filename to avoid collisions if user uploads "resume.pdf" twice.
    final uniqueId = const Uuid().v4().substring(0, 8);
    final ext = fileName.split('.').last;
    final name = fileName.split('.').first;
    final storedFileName = '${name}_$uniqueId.$ext';

    final path = '${user.id}/$storedFileName';

    await _client.storage.from(AppConstants.resumesBucket).uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl =
        _client.storage.from(AppConstants.resumesBucket).getPublicUrl(path);

    return Resume(
      name: storedFileName,
      url: publicUrl,
      path: path,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteResume(String path) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Security check: ensure path starts with user id
    if (!path.startsWith('${user.id}/')) {
      throw Exception('Unauthorized deletion');
    }

    await _client.storage.from(AppConstants.resumesBucket).remove([path]);
  }
}
