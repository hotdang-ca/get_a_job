import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/job_repository.dart';
import 'job_event.dart';
import 'job_state.dart';

class JobBloc extends Bloc<JobEvent, JobState> {
  final JobRepository _jobRepository;

  JobBloc({required JobRepository jobRepository})
      : _jobRepository = jobRepository,
        super(const JobState()) {
    on<LoadJobs>(_onLoadJobs);
    on<AddJob>(_onAddJob);
    on<UpdateJob>(_onUpdateJob);
    on<DeleteJob>(_onDeleteJob);
    on<UploadResume>(_onUploadResume);
    on<GenerateCoverLetter>(_onGenerateCoverLetter);
    on<ClearJobState>(_onClearJobState);
  }

  Future<void> _onLoadJobs(LoadJobs event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobStatus.loading));
    try {
      final jobs = await _jobRepository.getJobs();
      emit(state.copyWith(
        status: JobStatus.success,
        jobs: jobs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JobStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddJob(AddJob event, Emitter<JobState> emit) async {
    // We keep the current jobs while adding, but set status to loading if we want to show a spinner
    // Or we can just optimistically update?
    // Let's stick to simple: Loading -> Success (with new list)
    emit(state.copyWith(status: JobStatus.loading));
    try {
      await _jobRepository.addJob(event.job);
      // Reload jobs to ensure consistency and get the generated ID
      // Alternatively, we could append the returned job to the list
      add(LoadJobs());
    } catch (e) {
      emit(state.copyWith(
        status: JobStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateJob(UpdateJob event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobStatus.loading));
    try {
      await _jobRepository.updateJob(event.job);
      add(LoadJobs());
    } catch (e) {
      emit(state.copyWith(
        status: JobStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteJob(DeleteJob event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobStatus.loading));
    try {
      await _jobRepository.deleteJob(event.jobId);
      add(LoadJobs());
    } catch (e) {
      emit(state.copyWith(
        status: JobStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUploadResume(
      UploadResume event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobStatus.loading));
    try {
      final downloadUrl = await _jobRepository.uploadResume(
        event.jobId,
        event.fileBytes,
        event.fileName,
      );

      // We need to update the job with the new resume URL
      // Find the job in the current list or fetch it?
      // Since we might be in "Add Job" mode, the job might not exist in DB yet if we haven't saved.
      // BUT, the requirement implies we are editing or adding.
      // If we are adding, we haven't saved the job yet. So updating the DB record won't work if it doesn't exist.
      // However, the UI flow usually is: Fill form -> Upload Resume -> Save.
      // Or: Save -> Edit -> Upload Resume.

      // If the job exists in the state, we can update it.
      // But the UI needs to know the URL to put it in the form field (hidden or visible).
      // The BLoC state update will trigger a rebuild.

      // Ideally, the UI should handle the "success" of upload and get the URL back.
      // But BLoC is void return.
      // So we should update the state with the new URL, perhaps in a specific field or by updating the job in the list.

      // Simplified approach: Just emit success and let UI reload? No, UI needs the URL.
      // Let's add `resumeUrl` to the state or just update the job in the list if found.

      // Actually, for "Add Job", the job isn't in the list yet.
      // So we might need a specific state for "UploadSuccess" with the URL?
      // Or we just update the job in the DB?

      emit(state.copyWith(
        status: JobStatus.success,
        lastUploadedResumeUrl: downloadUrl,
        errorMessage: null,
        isUploading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JobStatus.failure,
        errorMessage: e.toString(),
        isUploading: false,
      ));
    }
  }

  Future<void> _onGenerateCoverLetter(
      GenerateCoverLetter event, Emitter<JobState> emit) async {
    emit(state.copyWith(isGenerating: true));
    try {
      final coverLetter = await _jobRepository.generateCoverLetter(event.job);
      emit(state.copyWith(
        status: JobStatus.success,
        lastGeneratedCoverLetter: coverLetter,
        errorMessage: null,
        isGenerating: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JobStatus.failure,
        errorMessage: e.toString(),
        isGenerating: false,
      ));
    }
  }

  void _onClearJobState(ClearJobState event, Emitter<JobState> emit) {
    emit(state.copyWith(
      lastUploadedResumeUrl: null,
      lastGeneratedCoverLetter: null,
      errorMessage: null,
      isUploading: false,
      isGenerating: false,
    ));
  }
}
