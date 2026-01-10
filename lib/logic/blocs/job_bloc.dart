import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/job_repository.dart';
import '../../data/models/job_model.dart';
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
    on<ReorderJob>(_onReorderJob);
    on<ClearJobState>(_onClearJobState);
    on<JobSearched>(_onJobSearched);
  }

  Future<void> _onLoadJobs(LoadJobs event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobLoadingStatus.loading));
    try {
      final jobs = await _jobRepository.getJobs();
      emit(state.copyWith(
        status: JobLoadingStatus.success,
        jobs: jobs,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JobLoadingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onAddJob(AddJob event, Emitter<JobState> emit) async {
    // We keep the current jobs while adding, but set status to loading if we want to show a spinner
    // Or we can just optimistically update?
    // Let's stick to simple: Loading -> Success (with new list)
    emit(state.copyWith(status: JobLoadingStatus.loading));
    try {
      await _jobRepository.addJob(event.job);
      // Reload jobs to ensure consistency and get the generated ID
      // Alternatively, we could append the returned job to the list
      add(LoadJobs());
    } catch (e) {
      emit(state.copyWith(
        status: JobLoadingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateJob(UpdateJob event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobLoadingStatus.loading));
    try {
      await _jobRepository.updateJob(event.job);
      add(LoadJobs());
    } catch (e) {
      emit(state.copyWith(
        status: JobLoadingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteJob(DeleteJob event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobLoadingStatus.loading));
    try {
      await _jobRepository.deleteJob(event.jobId);
      add(LoadJobs());
    } catch (e) {
      emit(state.copyWith(
        status: JobLoadingStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUploadResume(
      UploadResume event, Emitter<JobState> emit) async {
    emit(state.copyWith(status: JobLoadingStatus.loading));
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
        status: JobLoadingStatus.success,
        lastUploadedResumeUrl: downloadUrl,
        errorMessage: null,
        isUploading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JobLoadingStatus.failure,
        errorMessage: e.toString(),
        isUploading: false,
      ));
    }
  }

  Future<void> _onReorderJob(ReorderJob event, Emitter<JobState> emit) async {
    final currentJobs = List<Job>.from(state.jobs);
    final job = event.job;
    final JobStatus newStatus =
        event.newStatus; // Ensure newStatus is JobStatus
    final newIndex = event.newIndex;

    // Update job status if changed
    final updatedJob = job.copyWith(status: newStatus);

    // Remove the job from the list (it might be the old version)
    currentJobs.removeWhere((j) => j.id == job.id);

    // Get all jobs with the new status
    final statusJobs = currentJobs.where((j) => j.status == newStatus).toList();

    // Insert at new index
    // Clamp index to be safe
    final index = newIndex.clamp(0, statusJobs.length);
    statusJobs.insert(index, updatedJob);

    // Update positions for all jobs in this status
    final updatedStatusJobs = <Job>[];
    for (int i = 0; i < statusJobs.length; i++) {
      updatedStatusJobs.add(statusJobs[i].copyWith(position: i));
    }

    // Rebuild global list
    // We keep the others and append the new status list.
    // Note: This changes the global order of statuses, but that's fine for column view.
    final otherJobs = currentJobs.where((j) => j.status != newStatus).toList();
    final newGlobalList = [...otherJobs, ...updatedStatusJobs];

    emit(state.copyWith(jobs: newGlobalList));

    // Persist changes
    try {
      // If status changed, update the job fully first
      if (job.status != newStatus) {
        await _jobRepository.updateJob(updatedJob.copyWith(position: index));
      }

      // Update positions for all affected jobs
      // We only need to update jobs whose position changed, but for simplicity we update all in the column
      await _jobRepository.updateJobPositions(updatedStatusJobs);
    } catch (e) {
      // Handle error silently or emit failure?
      // For now, we assume it works. If it fails, next reload will fix it.
    }
  }

  Future<void> _onGenerateCoverLetter(
      GenerateCoverLetter event, Emitter<JobState> emit) async {
    emit(state.copyWith(isGenerating: true));
    try {
      final coverLetter = await _jobRepository.generateCoverLetter(event.job);
      emit(state.copyWith(
        status: JobLoadingStatus.success,
        lastGeneratedCoverLetter: coverLetter,
        errorMessage: null,
        isGenerating: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: JobLoadingStatus.failure,
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

  Future<void> _onJobSearched(JobSearched event, Emitter<JobState> emit) async {
    final jobs = await _jobRepository.getJobs();
    final searchText = event.searchText.trim().toLowerCase();

    if (searchText.isEmpty) {
      emit(state.copyWith(jobs: jobs));
    }

    final List<Job> jobsToReturn = [];
    emit(state.copyWith(status: JobLoadingStatus.loading));
    for (final job in jobs) {
      if ((job.company ?? '').toLowerCase().contains(searchText)) {
        jobsToReturn.add(job);
      } else if (job.title.toLowerCase().contains(searchText)) {
        jobsToReturn.add(job);
      }
    }

    emit(state.copyWith(
      status: JobLoadingStatus.success,
      jobs: jobsToReturn,
    ));
  }
}
