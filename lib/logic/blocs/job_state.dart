import 'package:equatable/equatable.dart';
import '../../data/models/job_model.dart';

enum JobStatus { initial, loading, success, failure }

class JobState extends Equatable {
  final JobStatus status;
  final List<Job> jobs;
  final String? errorMessage;
  final String? lastUploadedResumeUrl;
  final String? lastGeneratedCoverLetter;
  final bool isUploading;
  final bool isGenerating;

  const JobState({
    this.status = JobStatus.initial,
    this.jobs = const [],
    this.errorMessage,
    this.lastUploadedResumeUrl,
    this.lastGeneratedCoverLetter,
    this.isUploading = false,
    this.isGenerating = false,
  });

  JobState copyWith({
    JobStatus? status,
    List<Job>? jobs,
    String? errorMessage,
    String? lastUploadedResumeUrl,
    String? lastGeneratedCoverLetter,
    bool? isUploading,
    bool? isGenerating,
  }) {
    return JobState(
      status: status ?? this.status,
      jobs: jobs ?? this.jobs,
      errorMessage: errorMessage,
      lastUploadedResumeUrl: lastUploadedResumeUrl,
      lastGeneratedCoverLetter: lastGeneratedCoverLetter,
      isUploading: isUploading ?? this.isUploading,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }

  @override
  List<Object?> get props => [
        status,
        jobs,
        errorMessage,
        lastUploadedResumeUrl,
        lastGeneratedCoverLetter,
        isUploading,
        isGenerating
      ];
}
