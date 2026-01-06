import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/blocs/resume_bloc.dart';
import '../../logic/blocs/resume_event.dart';
import '../../logic/blocs/resume_state.dart';

class ResumesDialog extends StatelessWidget {
  const ResumesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Load resumes when dialog opens
    context.read<ResumeBloc>().add(LoadResumes());

    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Resume',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<ResumeBloc, ResumeState>(
                builder: (context, state) {
                  if (state.status == ResumeStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == ResumeStatus.failure) {
                    return Center(child: Text('Error: ${state.errorMessage}'));
                  }

                  if (state.resumes.isEmpty) {
                    return const Center(
                      child: Text('No resumes found. Upload one below!'),
                    );
                  }

                  return ListView.separated(
                    itemCount: state.resumes.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final resume = state.resumes[index];
                      return ListTile(
                        leading: const Icon(Icons.description),
                        title: Text(resume.name),
                        subtitle: Text(
                            'Uploaded: ${resume.createdAt.toLocal().toString().split('.')[0]}'),
                        onTap: () {
                          // Return the resume URL to the caller
                          Navigator.pop(context, resume.url);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            // Confirm deletion
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Resume?'),
                                content:
                                    const Text('This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context
                                          .read<ResumeBloc>()
                                          .add(DeleteResume(resume.path));
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ResumeBloc, ResumeState>(
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isUploading
                        ? null
                        : () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx'],
                              withData: true,
                            );

                            if (result != null && context.mounted) {
                              final file = result.files.single;
                              if (file.bytes != null) {
                                context.read<ResumeBloc>().add(
                                      UploadResume(
                                          fileBytes: file.bytes!,
                                          fileName: file.name),
                                    );
                              }
                            }
                          },
                    icon: state.isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.upload_file),
                    label: Text(state.isUploading
                        ? 'Uploading...'
                        : 'Upload New Resume'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
