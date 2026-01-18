
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class FilesTab extends ConsumerWidget {
  final String groupId;

  const FilesTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(groupFilesProvider(groupId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _uploadFile(context, ref),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: filesAsync.when(
        data: (files) {
          if (files.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('No files shared yet'),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: files.length,
            itemBuilder: (context, index) {
              return _FileCard(file: files[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _uploadFile(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'mp4'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final user = ref.read(currentUserProvider);
        if (user == null) return;

        final newFile = FileModel(
          id: const Uuid().v4(),
          name: file.name,
          url: 'https://example.com/mock_url', // Mock URL
          type: file.extension ?? 'file',
          uploadedBy: user.id,
          uploadedByName: user.name,
          timestamp: DateTime.now(),
          sizeBytes: file.size,
        );

        await ref.read(repositoryProvider).uploadFile(groupId, newFile);
        
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    }
  }
}

class _FileCard extends StatelessWidget {
  final FileModel file;

  const _FileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (file.type.toLowerCase()) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        color = Colors.blue;
        break;
      case 'jpg':
      case 'png':
        icon = Icons.image;
        color = Colors.purple;
        break;
      case 'mp4':
        icon = Icons.movie;
        color = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Card(
      child: InkWell(
        onTap: () async {
          // In real app, launch URL
          final uri = Uri.parse(file.url);
          if (await canLaunchUrl(uri)) {
             await launchUrl(uri);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening mock file...')),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(icon, size: 48, color: color),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                file.name,
                style: Theme.of(context).textTheme.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    file.formattedSize,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    DateFormat('MM/dd').format(file.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'By ${file.uploadedByName}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
