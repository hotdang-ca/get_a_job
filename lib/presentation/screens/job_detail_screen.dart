import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/job_model.dart';
import '../../logic/blocs/job_bloc.dart';
import '../../logic/blocs/job_state.dart';
import '../../logic/blocs/job_event.dart';

class JobDetailScreen extends StatefulWidget {
  final Job? job;

  const JobDetailScreen({super.key, this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  FocusNode _titleFocusNode = FocusNode();

  late TextEditingController _companyController;
  FocusNode _companyFocusNode = FocusNode();

  late TextEditingController _locationController;
  FocusNode _locationFocusNode = FocusNode();

  late TextEditingController _payRangeController;
  FocusNode _payRangeFocusNode = FocusNode();

  late TextEditingController _descriptionController;
  FocusNode _descriptionFocusNode = FocusNode();

  FocusNode _statusFocusNode = FocusNode();
  FocusNode _sourceFocusNode = FocusNode();
  FocusNode _createdAtFocusNode = FocusNode();
  FocusNode _closingDateFocusNode = FocusNode();

  late String _status;
  late String _source;
  DateTime? _closingDate;
  late DateTime _createdAt;
  String? _resumeUrl;
  String? _coverLetter;
  late final String _tempJobId;
  bool _hasBeenSaved = false; // Track if job has been saved to DB

  final List<String> _statuses = const [
    'To Apply',
    'Applied',
    'Interviewing',
    'Offer',
    'Rejected',
  ];

  final List<String> _sources = const [
    'LinkedIn',
    'Indeed',
    'Job Bank',
    'Direct',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tempJobId = const Uuid().v4();
    _titleController = TextEditingController(text: widget.job?.title ?? '');
    _companyController = TextEditingController(text: widget.job?.company ?? '');
    _locationController =
        TextEditingController(text: widget.job?.location ?? '');
    _payRangeController =
        TextEditingController(text: widget.job?.payRange ?? '');
    _descriptionController =
        TextEditingController(text: widget.job?.description ?? '');
    _status = widget.job?.status ?? 'To Apply';
    if (!_statuses.contains(_status)) {
      _status = 'To Apply';
    }

    _source = widget.job?.source ?? 'LinkedIn';
    if (!_sources.contains(_source)) {
      _source = 'Other';
    }

    _closingDate = widget.job?.closingDate;
    _createdAt = widget.job?.createdAt ?? DateTime.now();
    _resumeUrl = widget.job?.resumeUrl;
    _coverLetter = widget.job?.coverLetter;
    _hasBeenSaved =
        widget.job != null; // If editing existing job, it's already saved

    // Clear any stale BLoC state from previous screen visits
    context.read<JobBloc>().add(const ClearJobState());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    _companyController.dispose();
    _companyFocusNode.dispose();
    _locationController.dispose();
    _locationFocusNode.dispose();
    _payRangeController.dispose();
    _payRangeFocusNode.dispose();
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
    _createdAtFocusNode.dispose();
    _closingDateFocusNode.dispose();
    _statusFocusNode.dispose();
    _sourceFocusNode.dispose();

    super.dispose();
  }

  void _saveJob() {
    if (_formKey.currentState!.validate()) {
      final job = Job(
        id: widget.job?.id ?? _tempJobId,
        title: _titleController.text,
        company: _companyController.text,
        source: _source,
        location: _locationController.text,
        payRange: _payRangeController.text,
        description: _descriptionController.text,
        status: _status,
        createdAt: _createdAt,
        closingDate: _closingDate,
        coverLetter: _coverLetter,
        resumeUrl: _resumeUrl,
      );

      // Use AddJob only if never saved before, otherwise use UpdateJob
      if (!_hasBeenSaved) {
        context.read<JobBloc>().add(AddJob(job));
        _hasBeenSaved = true; // Mark as saved
      } else {
        context.read<JobBloc>().add(UpdateJob(job));
      }

      // Don't pop - stay on page and show toast
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job saved successfully!')),
      );
    }
  }

  void _deleteJob() {
    if (widget.job != null) {
      context.read<JobBloc>().add(DeleteJob(widget.job!.id));
      Navigator.pop(context);
    }
  }

  Future<void> _uploadResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true, // Important for Web
    );

    if (result != null) {
      final file = result.files.single;
      if (file.bytes != null) {
        final jobId = widget.job?.id ?? _tempJobId;

        context.read<JobBloc>().add(UploadResume(
              jobId: jobId,
              fileBytes: file.bytes!,
              fileName: file.name,
            ));
      }
    }
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isClosingDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isClosingDate ? (_closingDate ?? DateTime.now()) : _createdAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isClosingDate) {
          _closingDate = picked;
        } else {
          _createdAt = picked;
        }
      });
    }
  }

  Future<void> _generateCoverLetter() async {
    final job = Job(
      id: widget.job?.id ?? _tempJobId,
      title: _titleController.text,
      company: _companyController.text,
      source: _source,
      location: _locationController.text,
      payRange: _payRangeController.text,
      description: _descriptionController.text,
      status: _status,
      createdAt: _createdAt,
      closingDate: _closingDate,
      resumeUrl: _resumeUrl,
    );

    context.read<JobBloc>().add(GenerateCoverLetter(job));
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch ${url.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.job != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Job' : 'Add Job'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteJob,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveJob,
          ),
        ],
      ),
      body: BlocListener<JobBloc, JobState>(
        listener: (context, state) {
          if (state.lastUploadedResumeUrl != null) {
            setState(() {
              _resumeUrl = state.lastUploadedResumeUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resume uploaded successfully!')),
            );

            // Auto-save the job after resume upload
            _saveJob();
          }
          if (state.lastGeneratedCoverLetter != null) {
            setState(() {
              _coverLetter = state.lastGeneratedCoverLetter;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Cover Letter generated successfully!')),
            );
          }
          if (state.status == JobStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                return _buildDesktopLayout();
              } else {
                return _buildMobileLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FocusScope(
                  node: FocusScopeNode(
                    debugLabel: 'MyFormFocusScope',
                  ),
                  child: Column(
                    children: [
                      ..._buildInfoFields(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveJob,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Job'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 15,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Paste job description here...',
                  ),
                ),
                const SizedBox(height: 16),
                BlocBuilder<JobBloc, JobState>(
                  builder: (context, state) {
                    return OutlinedButton.icon(
                      onPressed: state.isUploading ? null : _uploadResume,
                      icon: state.isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(
                        state.isUploading
                            ? 'Uploading...'
                            : (_resumeUrl != null
                                ? 'Resume Uploaded'
                                : 'Upload Resume'),
                      ),
                    );
                  },
                ),
                if (_resumeUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Text(
                          'Resume linked',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            _launchUrl(Uri.parse(_resumeUrl!));
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Cover Letter',
                        style: Theme.of(context).textTheme.titleMedium),
                    Row(
                      children: [
                        if (_coverLetter != null && _coverLetter!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _coverLetter!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Cover letter copied to clipboard!')),
                              );
                            },
                            tooltip: 'Copy to clipboard',
                          ),
                        BlocBuilder<JobBloc, JobState>(
                          builder: (context, state) {
                            return FilledButton.icon(
                              onPressed: state.isGenerating
                                  ? null
                                  : _generateCoverLetter,
                              icon: state.isGenerating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.auto_awesome),
                              label: Text(state.isGenerating
                                  ? 'Generating...'
                                  : 'Generate'),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant),
                  ),
                  constraints: const BoxConstraints(minHeight: 300),
                  child: SelectableText(
                    _coverLetter ?? 'No cover letter generated yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ..._buildInfoFields(),
          const SizedBox(height: 24),
          TextFormField(
            controller: _descriptionController,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<JobBloc, JobState>(
            builder: (context, state) {
              return OutlinedButton.icon(
                onPressed: state.isUploading ? null : _uploadResume,
                icon: state.isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: Text(
                  state.isUploading
                      ? 'Uploading...'
                      : (_resumeUrl != null
                          ? 'Resume Uploaded'
                          : 'Upload Resume'),
                ),
              );
            },
          ),
          if (_resumeUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Text(
                    'Resume linked',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      _launchUrl(Uri.parse(_resumeUrl!));
                    },
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Cover Letter',
                  style: Theme.of(context).textTheme.titleMedium),
              Row(
                children: [
                  if (_coverLetter != null && _coverLetter!.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _coverLetter!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Cover letter copied to clipboard!')),
                        );
                      },
                      tooltip: 'Copy to clipboard',
                    ),
                  BlocBuilder<JobBloc, JobState>(
                    builder: (context, state) {
                      return FilledButton.icon(
                        onPressed:
                            state.isGenerating ? null : _generateCoverLetter,
                        icon: state.isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(
                            state.isGenerating ? 'Generating...' : 'Generate'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            _coverLetter ?? 'No cover letter generated yet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveJob,
              icon: const Icon(Icons.save),
              label: const Text('Save Job'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInfoFields() {
    return [
      TextFormField(
        focusNode: _titleFocusNode,
        controller: _titleController,
        decoration: const InputDecoration(labelText: 'Job Title'),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        focusNode: _companyFocusNode,
        controller: _companyController,
        decoration: const InputDecoration(labelText: 'Company'),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        focusNode: _sourceFocusNode,
        value: _source,
        decoration: const InputDecoration(labelText: 'Source'),
        items: _sources
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _source = value);
        },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        focusNode: _statusFocusNode,
        value: _status,
        decoration: const InputDecoration(labelText: 'Status'),
        items: _statuses
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _status = value);
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        focusNode: _locationFocusNode,
        controller: _locationController,
        decoration: const InputDecoration(labelText: 'Location'),
      ),
      const SizedBox(height: 16),
      TextFormField(
        focusNode: _payRangeFocusNode,
        controller: _payRangeController,
        decoration: const InputDecoration(labelText: 'Pay Range'),
      ),
      const SizedBox(height: 16),
      InkWell(
        focusNode: _closingDateFocusNode,
        onTap: () => _selectDate(context, isClosingDate: true),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Closing Date',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          child: Text(
            _closingDate != null
                ? "${_closingDate!.year}-${_closingDate!.month}-${_closingDate!.day}"
                : 'Select Date',
          ),
        ),
      ),
      const SizedBox(height: 16),
      InkWell(
        focusNode: _createdAtFocusNode,
        onTap: () => _selectDate(context, isClosingDate: false),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Created On',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          child: Text(
            "${_createdAt.year}-${_createdAt.month}-${_createdAt.day}",
          ),
        ),
      ),
    ];
  }
}
