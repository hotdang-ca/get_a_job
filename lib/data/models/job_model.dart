import 'package:equatable/equatable.dart';

enum JobStatus {
  toApply,
  applied,
  interviewing,
  offer,
  rejected;

  String get displayName {
    switch (this) {
      case JobStatus.toApply:
        return 'To Apply';
      case JobStatus.applied:
        return 'Applied';
      case JobStatus.interviewing:
        return 'Interviewing';
      case JobStatus.offer:
        return 'Offer';
      case JobStatus.rejected:
        return 'Rejected';
    }
  }

  static JobStatus fromString(String value) {
    return JobStatus.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => JobStatus.toApply,
    );
  }
}

enum JobSource {
  linkedIn,
  indeed,
  jobBank,
  direct,
  other;

  String get displayName {
    switch (this) {
      case JobSource.linkedIn:
        return 'LinkedIn';
      case JobSource.indeed:
        return 'Indeed';
      case JobSource.jobBank:
        return 'Job Bank';
      case JobSource.direct:
        return 'Direct';
      case JobSource.other:
        return 'Other';
    }
  }

  static JobSource fromString(String value) {
    return JobSource.values.firstWhere(
      (e) => e.displayName == value,
      orElse: () => JobSource.other,
    );
  }
}

class Job extends Equatable {
  final String id;
  final String title;
  final String? company;
  final String? location;
  final String? payRange;
  final JobSource? source;
  final DateTime? closingDate;
  final DateTime createdAt;
  final JobStatus status;
  final String? description;
  final String? coverLetter;
  final String? resumeUrl;
  final int position;

  const Job({
    required this.id,
    required this.title,
    this.company,
    this.location,
    this.payRange,
    this.source,
    this.closingDate,
    required this.createdAt,
    required this.status,
    this.description,
    this.coverLetter,
    this.resumeUrl,
    this.position = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String?,
      location: json['location'] as String?,
      payRange: json['pay_range'] as String?,
      source: json['source'] != null
          ? JobSource.fromString(json['source'] as String)
          : null,
      closingDate: json['closing_date'] != null
          ? DateTime.parse(json['closing_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: JobStatus.fromString(json['status'] as String),
      description: json['description'] as String?,
      coverLetter: json['cover_letter'] as String?,
      resumeUrl: json['resume_url'] as String?,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'pay_range': payRange,
      'source': source?.displayName,
      'closing_date': closingDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status.displayName,
      'description': description,
      'cover_letter': coverLetter,
      'resume_url': resumeUrl,
      'position': position,
    };
  }

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    String? payRange,
    JobSource? source,
    DateTime? closingDate,
    DateTime? createdAt,
    JobStatus? status,
    String? description,
    String? coverLetter,
    String? resumeUrl,
    int? position,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      company: company ?? this.company,
      location: location ?? this.location,
      payRange: payRange ?? this.payRange,
      source: source ?? this.source,
      closingDate: closingDate ?? this.closingDate,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      description: description ?? this.description,
      coverLetter: coverLetter ?? this.coverLetter,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        company,
        location,
        payRange,
        source,
        closingDate,
        createdAt,
        status,
        description,
        coverLetter,
        resumeUrl,
        position,
      ];
}
