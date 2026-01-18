
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../data/repository.dart';

// Theme Mode Provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light; // Default to light mode

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// Repository Provider
final repositoryProvider = Provider<Repository>((ref) => FirebaseRepository());

// Auth State
class AuthNotifier extends Notifier<UserModel?> {
  
  @override
  UserModel? build() {
    // Don't block app startup - check user asynchronously
    Future.microtask(() => _checkUserAsync());
    return null;
  }

  Future<void> _checkUserAsync() async {
    try {
      final repo = ref.read(repositoryProvider);
      state = await repo.getCurrentUser();
    } catch (_) {
      // Silently fail to not block UI
    }
  }

  Future<void> checkUser() async {
    final repo = ref.read(repositoryProvider);
    state = await repo.getCurrentUser();
  }

  Future<void> signIn() async {
    final repo = ref.read(repositoryProvider);
    state = await repo.signInWithGoogle();
  }

  Future<void> signInWithEmail(String email, String password) async {
    final repo = ref.read(repositoryProvider);
    state = await repo.signInWithEmail(email, password);
  }

  Future<void> signUpWithEmail(String email, String password, String displayName) async {
    final repo = ref.read(repositoryProvider);
    state = await repo.signUpWithEmail(email, password, displayName);
  }

  Future<void> signOut() async {
    final repo = ref.read(repositoryProvider);
    await repo.signOut();
    state = null;
  }
}

final currentUserProvider = NotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

// Local cached groups (optimistic additions when Firestore is slow/unavailable)
final cachedGroupsProvider = StateProvider<List<GroupModel>>((ref) => []);

// Groups List Provider
final userGroupsProvider = FutureProvider<List<GroupModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(repositoryProvider);
  if (user == null) return [];
  final remote = await repo.getUserGroups(user.id);
  final cached = ref.read(cachedGroupsProvider);

  // Merge remote and cached by id (cached wins for latest local additions)
  final map = <String, GroupModel>{
    for (final g in remote) g.id: g,
    for (final g in cached) g.id: g,
  };
  return map.values.toList();
});

// Selected Group Provider
class CurrentGroupNotifier extends Notifier<GroupModel?> {
  @override
  GroupModel? build() => null;

  void setGroup(GroupModel? group) {
    state = group;
  }
}

final currentGroupProvider = NotifierProvider<CurrentGroupNotifier, GroupModel?>(CurrentGroupNotifier.new);

// Group Data Providers (Family providers to accept groupId)

final groupMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, groupId) {
  final repo = ref.watch(repositoryProvider);
  return repo.getGroupMessages(groupId);
});

final groupFilesProvider = StreamProvider.family<List<FileModel>, String>((ref, groupId) {
  final repo = ref.watch(repositoryProvider);
  return repo.getGroupFiles(groupId);
});

final groupTodosProvider = StreamProvider.family<List<TodoModel>, String>((ref, groupId) {
  final repo = ref.watch(repositoryProvider);
  return repo.getGroupTodos(groupId);
});

final groupEventsProvider = StreamProvider.family<List<EventModel>, String>((ref, groupId) {
  final repo = ref.watch(repositoryProvider);
  return repo.getGroupEvents(groupId);
});
