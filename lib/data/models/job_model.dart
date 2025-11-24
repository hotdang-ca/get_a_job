import 'package:equatable/equatable.dart';

class Job extends Equatable {
  final String id;
  final String title;
  final String? company;
  final String? location;
  final String? payRange;
  final String? source;
  final DateTime? closingDate;
  final DateTime createdAt;
  final String status;
  final String? description;
  final String? coverLetter;
  final String? resumeUrl;

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
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as String,
      title: json['title'] as String,
      company: json['company'] as String?,
      location: json['location'] as String?,
      payRange: json['pay_range'] as String?,
      source: json['source'] as String?,
      closingDate: json['closing_date'] != null
          ? DateTime.parse(json['closing_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String,
      description: json['description'] as String?,
      coverLetter: json['cover_letter'] as String?,
      resumeUrl: json['resume_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company': company,
      'location': location,
      'pay_range': payRange,
      'source': source,
      'closing_date': closingDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'description': description,
      'cover_letter': coverLetter,
      'resume_url': resumeUrl,
    };
  }

  Job copyWith({
    String? id,
    String? title,
    String? company,
    String? location,
    String? payRange,
    String? source,
    DateTime? closingDate,
    DateTime? createdAt,
    String? status,
    String? description,
    String? coverLetter,
    String? resumeUrl,
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
      ];
}
