import 'package:equatable/equatable.dart';
import '../../data/models/resume_model.dart';

enum ResumeStatus { initial, loading, success, failure }

class ResumeState extends Equatable {
  final ResumeStatus status;
  final List<Resume> resumes;
  final String? errorMessage;
  final bool isUploading;

  const ResumeState({
    this.status = ResumeStatus.initial,
    this.resumes = const [],
    this.errorMessage,
    this.isUploading = false,
  });

  ResumeState copyWith({
    ResumeStatus? status,
    List<Resume>? resumes,
    String? errorMessage,
    bool? isUploading,
  }) {
    return ResumeState(
      status: status ?? this.status,
      resumes: resumes ?? this.resumes,
      errorMessage: errorMessage ?? this.errorMessage,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  @override
  List<Object?> get props => [status, resumes, errorMessage, isUploading];
}
