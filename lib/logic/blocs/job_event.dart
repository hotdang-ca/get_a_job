import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../data/models/job_model.dart';

abstract class JobEvent extends Equatable {
  const JobEvent();

  @override
  List<Object?> get props => [];
}

class LoadJobs extends JobEvent {}

class AddJob extends JobEvent {
  final Job job;

  const AddJob(this.job);

  @override
  List<Object?> get props => [job];
}

class UpdateJob extends JobEvent {
  final Job job;

  const UpdateJob(this.job);

  @override
  List<Object?> get props => [job];
}

class DeleteJob extends JobEvent {
  final String jobId;

  const DeleteJob(this.jobId);

  @override
  List<Object?> get props => [jobId];
}

class UploadResume extends JobEvent {
  final String jobId;
  final Uint8List fileBytes;
  final String fileName;

  const UploadResume({
    required this.jobId,
    required this.fileBytes,
    required this.fileName,
  });

  @override
  List<Object?> get props => [jobId, fileBytes, fileName];
}

class GenerateCoverLetter extends JobEvent {
  final Job job;

  const GenerateCoverLetter(this.job);

  @override
  List<Object?> get props => [job];
}

class ClearJobState extends JobEvent {
  const ClearJobState();

  @override
  List<Object?> get props => [];
}
