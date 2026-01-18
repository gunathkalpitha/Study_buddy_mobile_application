
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_providers.dart';
import '../theme.dart';
import '../models/models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final groupsAsync = ref.watch(userGroupsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Buddy'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread = ref.watch(unreadNotificationsCountProvider);
              return IconButton(
                icon: Badge(
                  isLabelVisible: unread > 0,
                  backgroundColor: Colors.red,
                  label: Text(unread.toString()),
                  child: const Icon(Icons.notifications_outlined),
                ),
                onPressed: () => _showNotificationsSheet(context, ref),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: user?.photoUrl != null && user!.photoUrl.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: NetworkImage(user.photoUrl),
                    radius: 16,
                  )
                : CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user?.name != null && user!.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_off_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No study groups yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create or join a group to start collaborating!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _showCreateGroupDialog(context, ref),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Group'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: () => _showJoinGroupDialog(context, ref),
                        icon: const Icon(Icons.login),
                        label: const Text('Join Group'),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn().scale(),
            );
          }

          return ListView(
            padding: AppSpacing.paddingMd,
            children: [
              Text(
                'Your Groups',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ...groups.map((group) => _GroupCard(group: group).animate().fadeIn().slideX()),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join_group_fab',
            onPressed: () => _showJoinGroupDialog(context, ref),
            icon: const Icon(Icons.login),
            label: const Text('Join Group'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'create_group_fab',
            onPressed: () => _showCreateGroupDialog(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('New Group'),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Study Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Group Name', hintText: 'e.g. Calculus 101'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: 'Subject', hintText: 'e.g. Math'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description', hintText: 'Short goal of the group'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final user = ref.read(currentUserProvider);
                if (user != null) {
                  try {
                    final newGroup = await ref.read(repositoryProvider).createGroup(
                          nameController.text,
                          descriptionController.text,
                          subjectController.text,
                          user.id,
                        );
                    // Optimistically add to cached groups so list shows immediately
                    ref.read(cachedGroupsProvider.notifier).update((groups) {
                      final map = {for (final g in groups) g.id: g};
                      map[newGroup.id] = newGroup;
                      return map.values.toList();
                    });

                    if (context.mounted) {
                      await _showSuccessDialog(context, 'Group created successfully');
                      // ignore: use_build_context_synchronously
                      context.pop();
                      ref.read(currentGroupProvider.notifier).setGroup(newGroup);
                      // ignore: use_build_context_synchronously
                      context.push('/group/${newGroup.id}');
                      // Refresh groups in background (non-blocking)
                      Future.delayed(const Duration(milliseconds: 500), () {
                        ref.invalidate(userGroupsProvider);
                      });
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating group: $e')),
                      );
                    }
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 900), () {
          if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final notificationsAsync = ref.watch(userNotificationsProvider);
          return notificationsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No notifications yet')),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final n = items[index];
                  return ListTile(
                    leading: Icon(
                      _iconForNotification(n.type),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(n.title),
                    subtitle: Text(n.body),
                    trailing: n.read
                        ? null
                        : Chip(
                            label: const Text('New'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          ),
                    onTap: () async {
                      final user = ref.read(currentUserProvider);
                      if (user != null) {
                        await ref.read(repositoryProvider).markNotificationRead(user.id, n.id);
                      }
                      if (n.groupId != null) {
                        ref.read(currentGroupProvider.notifier).setGroup(null);
                        if (context.mounted) {
                          context.push('/group/${n.groupId}');
                        }
                      }
                    },
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Error loading notifications: $err'),
            ),
          );
        },
      ),
    );
  }

  IconData _iconForNotification(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.todo:
        return Icons.check_circle_outline;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.group:
        return Icons.group_outlined;
      case NotificationType.system:
        return Icons.notifications_outlined;
    }
  }

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Join Study Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                enabled: !isLoading,
                textCapitalization: TextCapitalization.characters,
                maxLength: 8,
                decoration: InputDecoration(
                  labelText: 'Invite Code',
                  hintText: 'ABC12345',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste),
                    tooltip: 'Paste from clipboard',
                    onPressed: isLoading ? null : () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        codeController.text = data!.text!.trim().toUpperCase();
                      }
                    },
                  ),
                ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading ? null : () async {
                final code = codeController.text.trim().toUpperCase();
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an invite code')),
                  );
                  return;
                }

                setState(() => isLoading = true);

                try {
                  final user = ref.read(currentUserProvider);
                  if (user == null) {
                    throw Exception('User not logged in');
                  }

                  final group = await ref.read(repositoryProvider).joinGroup(code, user.id);
                  
                  if (group != null) {
                    // Add to cached groups for instant display
                    ref.read(cachedGroupsProvider.notifier).update((groups) {
                      final map = {for (final g in groups) g.id: g};
                      map[group.id] = group;
                      return map.values.toList();
                    });
                    
                    // Invalidate to refresh from server
                    ref.invalidate(userGroupsProvider);
                    
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Successfully joined "${group.name}"!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      
                      // Navigate to group
                      ref.read(currentGroupProvider.notifier).setGroup(group);
                      context.push('/group/${group.id}');
                    }
                  } else {
                    setState(() => isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Invalid or expired invite code. Please check and try again.'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  setState(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends ConsumerWidget {
  final GroupModel group;

  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          ref.read(currentGroupProvider.notifier).setGroup(group);
          context.push('/group/${group.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Chip(
                    label: Text(group.subject),
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text('${group.memberIds.length} members'),
                  const Spacer(),
                  Text(
                    'Since ${group.createdAt.toString().split(' ')[0]}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
