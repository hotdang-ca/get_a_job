import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../logic/blocs/job_bloc.dart';
import '../../logic/blocs/job_event.dart';
import '../../logic/blocs/job_state.dart';
import '../../logic/blocs/theme_bloc.dart';
import '../../logic/blocs/theme_event.dart';
import '../../logic/blocs/theme_state.dart';
import '../../data/models/job_model.dart';
import '../widgets/job_card.dart';
import 'job_detail_screen.dart';
import '../../logic/blocs/auth_bloc.dart';
import '../../logic/blocs/auth_event.dart';
import '../widgets/account_request_dialog.dart';
import '../../data/services/guest_storage_service.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuestMode;

  const HomeScreen({super.key, this.isGuestMode = true});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<JobStatus> _statuses = JobStatus.values;

  final ScrollController _scrollController = ScrollController();

  String? _searchText;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();

    _searchText = '';
    _searchController = TextEditingController(text: _searchText ?? '');
    _searchController.addListener(searchTextDidChange);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(searchTextDidChange);
    _searchController.dispose();

    super.dispose();
  }

  void searchTextDidChange() {
    final String searchText = _searchController.text;
    final jobBloc = context.read<JobBloc>();
    jobBloc.add(JobSearched(searchText));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Get A Job'),
          Spacer(),
          Expanded(
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary.withAlpha(125),
                  ),
                  suffix: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      }),
                  labelText: 'Search Job Titles / Company'),
            ),
          ),
        ]),
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
          if (!widget.isGuestMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                context.read<JobBloc>().add(LoadJobs());
              },
              tooltip: 'Refresh',
            ),
          if (!widget.isGuestMode)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                context.read<AuthBloc>().add(const AuthSignOutRequested());
              },
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isGuestMode)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Guest Mode: Changes are saved locally and limited to 1 job.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context
                          .read<AuthBloc>()
                          .add(const AuthSignOutRequested());
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: BlocBuilder<JobBloc, JobState>(
              builder: (context, state) {
                if (state.status == JobLoadingStatus.loading &&
                    state.jobs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == JobLoadingStatus.failure &&
                    state.jobs.isEmpty) {
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
                      final jobsInStatus = state.jobs
                          .where((job) => job.status == status)
                          .toList();

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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        status.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                        builder: (context, candidateData,
                                            rejectedData) {
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
                                                        BorderRadius.circular(
                                                            2),
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
                                                          job: job,
                                                          onTap: () {}),
                                                    ),
                                                  ),
                                                ),
                                                childWhenDragging: Opacity(
                                                  opacity: 0.3,
                                                  child: JobCard(
                                                      job: job, onTap: () {}),
                                                ),
                                                child: JobCard(
                                                  job: job,
                                                  onTap: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            JobDetailScreen(
                                                                job: job),
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
          ),
          if (widget.isGuestMode) _buildBrandingFooter(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (widget.isGuestMode) {
            final guestService = GuestStorageService();
            final canAdd = await guestService.canAddJob();

            if (!canAdd && context.mounted) {
              showDialog(
                context: context,
                builder: (context) => const AccountRequestDialog(),
              );
              return;
            }
          }

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailScreen(
                  isGuestMode: widget.isGuestMode,
                ),
              ),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBrandingFooter(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _launchCompanyWebsite(),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    'https://www.fourandahalfgiraffes.ca/_next/image?url=%2Flogo-sm.png&w=3840&q=75',
                    height: 32,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.business, size: 24);
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Four And A Half Giraffes, Ltd.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'I Build Small, Useful Things for Your Business.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                      fontStyle: FontStyle.italic,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchCompanyWebsite() async {
    final Uri url = Uri.parse('https://fourandahalfgiraffes.ca/');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }
}
