import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/blocs/job_bloc.dart';
import '../../logic/blocs/job_event.dart';
import '../../logic/blocs/job_state.dart';
import '../../logic/blocs/theme_bloc.dart';
import '../../logic/blocs/theme_event.dart';
import '../../logic/blocs/theme_state.dart';
import '../../data/models/job_model.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<JobStatus> _statuses = JobStatus.values;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Get A Job'),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return IconButton(
                icon: Icon(
                  themeState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () {
                  context.read<ThemeBloc>().add(const ToggleTheme());
                },
                tooltip: themeState.isDarkMode ? 'Light mode' : 'Dark mode',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<JobBloc>().add(LoadJobs());
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<JobBloc, JobState>(
        builder: (context, state) {
          if (state.status == JobLoadingStatus.loading && state.jobs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == JobLoadingStatus.failure && state.jobs.isEmpty) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          }

          return Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              itemCount: _statuses.length,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final status = _statuses[index];
                final jobsInStatus =
                    state.jobs.where((job) => job.status == status).toList();

                return DragTarget<Job>(
                  onAccept: (job) {
                    if (job.status != status) {
                      final updatedJob = job.copyWith(status: status);
                      context.read<JobBloc>().add(UpdateJob(updatedJob));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Job status updated to ${status.displayName}')),
                      );
                    } else {
                      // Move to end of list
                      context.read<JobBloc>().add(
                            ReorderJob(
                              job: job,
                              newIndex: jobsInStatus.length,
                              newStatus: status,
                            ),
                          );
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      width: 300,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.3)
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: candidateData.isNotEmpty
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                          width: candidateData.isNotEmpty ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  status.displayName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${jobsInStatus.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: jobsInStatus.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final job = jobsInStatus[index];
                                return DragTarget<Job>(
                                  onWillAccept: (incomingJob) {
                                    return incomingJob != null &&
                                        incomingJob.id != job.id;
                                  },
                                  onAccept: (incomingJob) {
                                    context.read<JobBloc>().add(
                                          ReorderJob(
                                            job: incomingJob,
                                            newIndex: index,
                                            newStatus: status,
                                          ),
                                        );
                                  },
                                  builder:
                                      (context, candidateData, rejectedData) {
                                    return Column(
                                      children: [
                                        if (candidateData.isNotEmpty)
                                          Container(
                                            height: 4,
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                        Draggable<Job>(
                                          data: job,
                                          feedback: Material(
                                            elevation: 4,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: SizedBox(
                                              width: 280,
                                              child: Opacity(
                                                opacity: 0.8,
                                                child: JobCard(
                                                    job: job, onTap: () {}),
                                              ),
                                            ),
                                          ),
                                          childWhenDragging: Opacity(
                                            opacity: 0.3,
                                            child:
                                                JobCard(job: job, onTap: () {}),
                                          ),
                                          child: JobCard(
                                            job: job,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      JobDetailScreen(job: job),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const JobDetailScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
