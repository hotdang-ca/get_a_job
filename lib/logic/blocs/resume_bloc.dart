import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/resume_repository.dart';
import 'resume_event.dart';
import 'resume_state.dart';

class ResumeBloc extends Bloc<ResumeEvent, ResumeState> {
  final ResumeRepository _resumeRepository;

  ResumeBloc({required ResumeRepository resumeRepository})
      : _resumeRepository = resumeRepository,
        super(const ResumeState()) {
    on<LoadResumes>(_onLoadResumes);
    on<UploadResume>(_onUploadResume);
    on<DeleteResume>(_onDeleteResume);
  }

  Future<void> _onLoadResumes(
    LoadResumes event,
    Emitter<ResumeState> emit,
  ) async {
    emit(state.copyWith(status: ResumeStatus.loading));
    try {
      final resumes = await _resumeRepository.getResumes();
      emit(state.copyWith(
        status: ResumeStatus.success,
        resumes: resumes,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ResumeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUploadResume(
    UploadResume event,
    Emitter<ResumeState> emit,
  ) async {
    emit(state.copyWith(isUploading: true));
    try {
      await _resumeRepository.uploadResume(event.fileBytes, event.fileName);
      add(LoadResumes()); // Reload to show new resume
      emit(state.copyWith(isUploading: false));
    } catch (e) {
      emit(state.copyWith(
        status: ResumeStatus.failure,
        errorMessage: e.toString(),
        isUploading: false,
      ));
    }
  }

  Future<void> _onDeleteResume(
    DeleteResume event,
    Emitter<ResumeState> emit,
  ) async {
    // Optimistic update or waiting? Let's wait.
    try {
      await _resumeRepository.deleteResume(event.path);
      add(LoadResumes());
    } catch (e) {
      emit(state.copyWith(
        status: ResumeStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
