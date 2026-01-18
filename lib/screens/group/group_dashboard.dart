
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:study_buddy/providers/app_providers.dart';
import 'package:study_buddy/screens/group/calendar_tab.dart';
import 'package:study_buddy/screens/group/chat_tab.dart';
import 'package:study_buddy/screens/group/files_tab.dart';
import 'package:study_buddy/screens/group/todo_tab.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/models.dart';

class GroupDashboard extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDashboard({super.key, required this.groupId});

  @override
  ConsumerState<GroupDashboard> createState() => _GroupDashboardState();
}

class _GroupDashboardState extends ConsumerState<GroupDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // First check if we have the group in currentGroupProvider (e.g., from home_screen)
    final currentGroup = ref.watch(currentGroupProvider);
    
    // If currentGroup exists and matches our groupId, use it (fast path for newly created groups)
    if (currentGroup != null && currentGroup.id == widget.groupId) {
      final group = currentGroup;
      return _buildGroupScaffold(context, group);
    }
    
    // Fallback: fetch from userGroupsProvider
    final groupsAsync = ref.watch(userGroupsProvider);
    
    return groupsAsync.when(
      data: (groups) {
        GroupModel? group;
        for (final g in groups) {
          if (g.id == widget.groupId) {
            group = g;
            break;
          }
        }

        if (group == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Not Found')),
            body: const Center(child: Text('Group not found')),
          );
        }
        
        return _buildGroupScaffold(context, group);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildGroupScaffold(BuildContext context, GroupModel group) {
    final tabs = [
      ChatTab(groupId: group.id),
      FilesTab(groupId: group.id),
      TodoTab(groupId: group.id),
      CalendarTab(groupId: group.id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              '${group.memberIds.length} members • ${group.subject}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () => _launchVideoCall(),
            tooltip: 'Video Call',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showGroupInfo(context, group),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
        ],
      ),
    );
  }

  void _launchVideoCall() async {
    // In a real app, this would be a dynamic link or integration
    const url = 'https://zoom.us/join';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch video call')),
        );
      }
    }
  }

  void _showGroupInfo(BuildContext context, GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Group Info',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _InfoRow(icon: Icons.vpn_key, label: 'Invite Code', value: group.inviteCode, isCopyable: true),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.subject, label: 'Subject', value: group.subject),
              const SizedBox(height: 16),
              _InfoRow(icon: Icons.description, label: 'Description', value: group.description),
              const SizedBox(height: 24),
              Text(
                'Members (${group.memberIds.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              // In real app, we'd fetch member details. Here we just show IDs or mocked names
              ...group.memberIds.map((id) => ListTile(
                    leading: CircleAvatar(child: Text(id.substring(0, 1).toUpperCase())),
                    title: Text(id == group.adminId ? 'Admin ($id)' : 'Member ($id)'),
                    trailing: id == group.adminId
                        ? const Chip(label: Text('Admin'), visualDensity: VisualDensity.compact)
                        : null,
                  )),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {
                  // Leave group logic
                  if (context.mounted) {
                    context.pop();
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                },
                icon: const Icon(Icons.exit_to_app, color: Colors.red),
                label: const Text('Leave Group', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isCopyable;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isCopyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
        if (isCopyable)
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invite code copied')), // quick feedback
              );
              }
            },
          ),
      ],
    );
  }
}
