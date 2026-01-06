import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class ResumeEvent extends Equatable {
  const ResumeEvent();

  @override
  List<Object> get props => [];
}

class LoadResumes extends ResumeEvent {}

class UploadResume extends ResumeEvent {
  final Uint8List fileBytes;
  final String fileName;

  const UploadResume({required this.fileBytes, required this.fileName});

  @override
  List<Object> get props => [fileBytes, fileName];
}

class DeleteResume extends ResumeEvent {
  final String path;

  const DeleteResume(this.path);

  @override
  List<Object> get props => [path];
}
