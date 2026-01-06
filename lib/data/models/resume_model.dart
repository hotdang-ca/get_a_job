import 'package:equatable/equatable.dart';

class Resume extends Equatable {
  final String name;
  final String url;
  final String path; // Storage path, e.g. users/123/resume.pdf
  final DateTime createdAt;

  const Resume({
    required this.name,
    required this.url,
    required this.path,
    required this.createdAt,
  });

  factory Resume.fromJson(Map<String, dynamic> json, String publicUrl) {
    return Resume(
      name: json['name'] as String,
      url: publicUrl,
      path: json['id'] != null
          ? json['id'] as String
          : json['name']
              as String, // 'id' in storage list response is usually the path/name
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  // Helper for when we construct from FileObject (Supabase storage list response) manually if needed
  // But typically the repository handles the raw Supabase response.

  @override
  List<Object?> get props => [name, url, path, createdAt];
}
