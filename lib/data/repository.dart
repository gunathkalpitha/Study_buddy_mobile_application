
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

abstract class Repository {
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInWithEmail(String email, String password);
  Future<UserModel?> signUpWithEmail(String email, String password, String displayName);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> sendEmailVerification();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updateUserProfile(String userId, {String? displayName, String? photoUrl});
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> deleteAccount(String userId);
  Future<List<GroupModel>> getUserGroups(String userId);
  Future<GroupModel> createGroup(String name, String description, String subject, String userId);
  Future<GroupModel?> joinGroup(String inviteCode, String userId);
  
  Stream<List<MessageModel>> getGroupMessages(String groupId);
  Future<void> sendMessage(String groupId, MessageModel message);
  
  Stream<List<FileModel>> getGroupFiles(String groupId);
  Future<void> uploadFile(String groupId, FileModel file);
  Future<void> deleteFile(String groupId, String fileId);
  
  Stream<List<TodoModel>> getGroupTodos(String groupId);
  Future<void> addTodo(String groupId, TodoModel todo);
  Future<void> toggleTodo(String groupId, String todoId, bool completed);
  Future<void> deleteTodo(String groupId, String todoId);
  
  Stream<List<EventModel>> getGroupEvents(String groupId);
  Future<void> addEvent(String groupId, EventModel event);

  // Notifications
  Stream<List<NotificationModel>> getUserNotifications(String userId);
  Future<void> markNotificationRead(String userId, String notificationId);
}

class FirebaseRepository implements Repository {
  final _uuid = const Uuid();
  final _firestore = FirebaseFirestore.instance;
  final _auth = fb_auth.FirebaseAuth.instance;

  Future<DocumentSnapshot<Map<String, dynamic>>?> _safeUserDoc(String uid) async {
    try {
      return await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 1)); // Reduced to 1 second for faster startup
    } on TimeoutException {
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return null;
      rethrow;
    }
  }

  UserModel _fromAuth(fb_auth.User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? 'User',
      email: user.email ?? '',
      photoUrl: user.photoURL ?? '',
      groupIds: const [],
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  UserModel _fromFirestoreDoc(fb_auth.User user, Map<String, dynamic> data) {
    return UserModel(
      id: user.uid,
      name: data['name'] ?? user.displayName ?? 'User',
      email: data['email'] ?? user.email ?? '',
      photoUrl: data['photoUrl'] ?? user.photoURL ?? '',
      groupIds: List<String>.from(data['groupIds'] ?? []),
      createdAt: DateTime.parse(data['createdAt'] ?? user.metadata.creationTime?.toIso8601String() ?? DateTime.now().toIso8601String()),
      studyHours: (data['studyHours'] ?? 0.0).toDouble(),
    );
  }

  Future<void> _seedDemoData(String userId, String userName, String email) async {
    try {
      final groupId = _uuid.v4();
      final inviteCode = _uuid.v4().substring(0, 8).toUpperCase();
      final now = DateTime.now();

      final batch = _firestore.batch();
      final groupRef = _firestore.collection('groups').doc(groupId);
      final userRef = _firestore.collection('users').doc(userId);

      batch.set(groupRef, {
        'name': 'Welcome Group',
        'description': 'Getting started with Study Buddy',
        'adminId': userId,
        'memberIds': [userId],
        'inviteCode': inviteCode,
        'createdAt': now.toIso8601String(),
        'subject': 'Onboarding',
      });

      batch.update(userRef, {
        'groupIds': FieldValue.arrayUnion([groupId]),
      });

      final messageRef = groupRef.collection('messages').doc();
      batch.set(messageRef, {
        'text': 'Welcome to your first group, $userName! 🎉',
        'senderId': userId,
        'senderName': userName,
        'timestamp': now.toIso8601String(),
        'type': MessageType.text.name,
      });

      final todoRef = groupRef.collection('todos').doc();
      batch.set(todoRef, {
        'task': 'Add your first study note',
        'completed': false,
        'createdBy': userId,
        'priority': PriorityLevel.medium.name,
        'dueDate': now.add(const Duration(days: 2)).toIso8601String(),
        'createdAt': now.toIso8601String(),
      });

      final eventRef = groupRef.collection('events').doc();
      batch.set(eventRef, {
        'title': 'Kickoff session',
        'description': 'Meet and plan your study schedule',
        'date': now.add(const Duration(days: 1)).toIso8601String(),
        'type': 'meet',
        'createdBy': userId,
      });

      final fileRef = groupRef.collection('files').doc();
      batch.set(fileRef, {
        'name': 'Welcome.pdf',
        'url': 'https://example.com/welcome.pdf',
        'type': 'pdf',
        'uploadedBy': userId,
        'uploadedByName': userName,
        'timestamp': now.toIso8601String(),
        'sizeBytes': 1024,
      });

      await batch.commit();
    } catch (_) {
      // Best-effort seed; ignore failures to keep signup fast
    }
  }

  @override
  Future<UserModel?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    final doc = await _safeUserDoc(user.uid);
    if (doc != null && doc.exists) {
      return _fromFirestoreDoc(user, doc.data()!);
    }

    // User doc doesn't exist, create it
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'id': user.uid,
        'name': user.displayName ?? 'User',
        'email': email,
        'photoUrl': user.photoURL ?? '',
        'groupIds': [],
        'emailVerified': user.emailVerified,
        'createdAt': DateTime.now().toIso8601String(),
        'studyHours': 0.0,
      }, SetOptions(merge: true));
      
      // Fetch the newly created doc
      final newDoc = await _safeUserDoc(user.uid);
      if (newDoc != null && newDoc.exists) {
        return _fromFirestoreDoc(user, newDoc.data()!);
      }
    } catch (_) {
      // Ignore failures to keep sign-in fast
    }

    return _fromAuth(user);
  }

  @override
  Future<UserModel?> signUpWithEmail(String email, String password, String displayName) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) return null;

    await user.updateDisplayName(displayName);
    await user.reload();

    // Send email verification
    try {
      await user.sendEmailVerification();
    } catch (e) {
      if (kDebugMode) {
        print('Error sending verification email: $e');
      }
    }

    // Write user doc, but don't block sign-up success if Firestore is slow/unavailable
    unawaited(() async {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'name': displayName,
          'email': email,
          'photoUrl': '',
          'groupIds': [],
          'emailVerified': false,
          'createdAt': DateTime.now().toIso8601String(),
          'studyHours': 0.0,
        }, SetOptions(merge: true));

        await _seedDemoData(user.uid, displayName, email);
      } on FirebaseException catch (_) {
        // ignore: best-effort write
      }
    }());

    return UserModel(
      id: user.uid,
      name: displayName,
      email: email,
      photoUrl: '',
      groupIds: const [],
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    fb_auth.UserCredential credential;

    if (kIsWeb) {
      final provider = fb_auth.GoogleAuthProvider();
      credential = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final oauthCredential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      credential = await _auth.signInWithCredential(oauthCredential);
    }

    final user = credential.user;
    if (user == null) return null;

    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();
    
    // Create or update user document
    await userDoc.set({
      'id': user.uid,
      'name': user.displayName ?? 'User',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'groupIds': docSnapshot.exists ? (docSnapshot.data()?['groupIds'] ?? []) : [],
      'emailVerified': user.emailVerified,
      'createdAt': docSnapshot.exists ? (docSnapshot.data()?['createdAt'] ?? DateTime.now().toIso8601String()) : DateTime.now().toIso8601String(),
      'studyHours': docSnapshot.exists ? (docSnapshot.data()?['studyHours'] ?? 0.0) : 0.0,
    }, SetOptions(merge: true));

    final freshDoc = await userDoc.get();
    final data = freshDoc.data()!;
    
    return UserModel(
      id: user.uid,
      name: data['name'] ?? user.displayName ?? 'User',
      email: data['email'] ?? user.email ?? '',
      photoUrl: data['photoUrl'] ?? user.photoURL ?? '',
      groupIds: List<String>.from(data['groupIds'] ?? []),
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
      studyHours: (data['studyHours'] ?? 0.0).toDouble(),
    );
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending email verification: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No account found with this email');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending password reset email: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfile(String userId, {String? displayName, String? photoUrl}) async {
    try {
      final user = _auth.currentUser;
      if (user != null && displayName != null) {
        await user.updateDisplayName(displayName);
      }
      
      await _firestore.collection('users').doc(userId).set(
        {
          if (displayName != null) 'name': displayName,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
        SetOptions(merge: true),
      );

      if (user != null) {
        await user.reload();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated or email not available');
      }

      // Re-authenticate with current password
      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw Exception('Current password is incorrect');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error changing password: $e');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Delete user data from Firestore first
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete user from Firebase Auth
      await user.delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      rethrow;
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _safeUserDoc(user.uid);
      if (userDoc != null && userDoc.exists) {
        return _fromFirestoreDoc(user, userDoc.data()!);
      }
    } catch (_) {
      // fall through to auth-only data
    }

    return _fromAuth(user);
  }

  @override
  Future<List<GroupModel>> getUserGroups(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(const Duration(seconds: 3));
      
      if (!userDoc.exists) return [];
      
      final groupIds = List<String>.from(userDoc.data()?['groupIds'] ?? []);
      if (groupIds.isEmpty) return [];

      final groups = await _firestore
          .collection('groups')
          .where(FieldPath.documentId, whereIn: groupIds)
          .get()
          .timeout(const Duration(seconds: 3));

      return groups.docs.map((doc) {
        final data = doc.data();
        return GroupModel(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          adminId: data['adminId'] ?? '',
          memberIds: List<String>.from(data['memberIds'] ?? []),
          inviteCode: data['inviteCode'] ?? '',
          createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
          subject: data['subject'] ?? '',
        );
      }).toList();
    } on TimeoutException {
      return [];
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return [];
      rethrow;
    }
  }

  @override
  Future<GroupModel> createGroup(String name, String description, String subject, String userId) async {
    final groupId = _uuid.v4();
    final inviteCode = _uuid.v4().substring(0, 8).toUpperCase();
    final now = DateTime.now();
    final inviteExpiry = now.add(const Duration(days: 7)); // Invite expires in 7 days

    final groupData = {
      'name': name,
      'description': description,
      'adminId': userId,
      'memberIds': [userId],
      'inviteCode': inviteCode,
      'inviteExpiry': inviteExpiry.toIso8601String(),
      'createdAt': now.toIso8601String(),
      'subject': subject,
    };

    // Write group data to Firestore
    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .set(groupData)
          .timeout(const Duration(seconds: 10));
      
      // Update user's groupIds - use set with merge to create doc if it doesn't exist
      await _firestore
          .collection('users')
          .doc(userId)
          .set(
            {'groupIds': FieldValue.arrayUnion([groupId])},
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (kDebugMode) {
        print('ERROR creating group in Firestore: $e');
      }
      rethrow; // Let the caller handle the error
    }

    return GroupModel(
      id: groupId,
      name: name,
      description: description,
      adminId: userId,
      memberIds: [userId],
      inviteCode: inviteCode,
      createdAt: now,
      subject: subject,
    );
  }

  @override
  Future<GroupModel?> joinGroup(String inviteCode, String userId) async {
    try {
      // Normalize invite code
      final normalizedCode = inviteCode.trim().toUpperCase();
      
      final groups = await _firestore
          .collection('groups')
          .where('inviteCode', isEqualTo: normalizedCode)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8)); // Increased timeout for reliability

      if (groups.docs.isEmpty) {
        if (kDebugMode) {
          print('No group found with invite code: $normalizedCode');
        }
        return null;
      }

      final groupDoc = groups.docs.first;
      final data = groupDoc.data();
      
      // Check if invite link has expired
      final inviteExpiryStr = data['inviteExpiry'] as String?;
      if (inviteExpiryStr != null) {
        final inviteExpiry = DateTime.parse(inviteExpiryStr);
        if (DateTime.now().isAfter(inviteExpiry)) {
          if (kDebugMode) {
            print('Invite code has expired: $normalizedCode');
          }
          return null; // Invite link has expired
        }
      }
      
      final memberIds = List<String>.from(data['memberIds'] ?? []);

      // Check if user is already a member
      if (memberIds.contains(userId)) {
        // Already a member, just return the group
        return GroupModel(
          id: groupDoc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          adminId: data['adminId'] ?? '',
          memberIds: memberIds,
          inviteCode: data['inviteCode'] ?? '',
          createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
          subject: data['subject'] ?? '',
        );
      }

      // Add user to group
      await groupDoc.reference
          .update({'memberIds': FieldValue.arrayUnion([userId])})
          .timeout(const Duration(seconds: 8));

      // Add group to user's groupIds
      await _firestore
          .collection('users')
          .doc(userId)
          .set(
            {'groupIds': FieldValue.arrayUnion([groupDoc.id])},
            SetOptions(merge: true),
          )
          .timeout(const Duration(seconds: 8));

      memberIds.add(userId);

      return GroupModel(
        id: groupDoc.id,
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        adminId: data['adminId'] ?? '',
        memberIds: memberIds,
        inviteCode: data['inviteCode'] ?? '',
        createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
        subject: data['subject'] ?? '',
      );
    } on TimeoutException {
      if (kDebugMode) {
        print('Timeout while joining group with code: $inviteCode');
      }
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return null;
      rethrow;
    }
  }

  @override
  Stream<List<MessageModel>> getGroupMessages(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) {
            print('ERROR fetching messages for group $groupId: $error');
          }
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return MessageModel(
                id: doc.id,
                text: data['text'] ?? '',
                senderId: data['senderId'] ?? '',
                senderName: data['senderName'] ?? '',
                timestamp: data['timestamp'] != null 
                    ? DateTime.parse(data['timestamp'])
                    : DateTime.now(),
                type: MessageType.values.firstWhere(
                  (e) => e.name == (data['type'] ?? 'text'),
                  orElse: () => MessageType.text,
                ),
              );
            }).toList();
          } catch (e) {
            if (kDebugMode) {
              print('ERROR parsing messages: $e');
            }
            rethrow;
          }
        });
  }

  @override
  Future<void> sendMessage(String groupId, MessageModel message) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('messages')
        .add({
      'text': message.text,
      'senderId': message.senderId,
      'senderName': message.senderName,
      'timestamp': message.timestamp.toIso8601String(),
      'type': message.type.name,
    }).timeout(const Duration(seconds: 5));
  }

  @override
  Stream<List<FileModel>> getGroupFiles(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('files')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) {
            print('ERROR fetching files for group $groupId: $error');
          }
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return FileModel(
                id: doc.id,
                name: data['name'] ?? '',
                url: data['url'] ?? '',
                type: data['type'] ?? '',
                uploadedBy: data['uploadedBy'] ?? '',
                uploadedByName: data['uploadedByName'] ?? '',
                timestamp: data['timestamp'] != null 
                    ? DateTime.parse(data['timestamp'])
                    : DateTime.now(),
                sizeBytes: data['sizeBytes'] ?? 0,
              );
            }).toList();
          } catch (e) {
            if (kDebugMode) {
              print('ERROR parsing files: $e');
            }
            return [];
          }
        });
  }

  @override
  Future<void> uploadFile(String groupId, FileModel file) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('files')
        .add({
      'name': file.name,
      'url': file.url,
      'type': file.type,
      'uploadedBy': file.uploadedBy,
      'uploadedByName': file.uploadedByName,
      'timestamp': file.timestamp.toIso8601String(),
      'sizeBytes': file.sizeBytes,
    }).timeout(const Duration(seconds: 5));
  }

  @override
  Future<void> deleteFile(String groupId, String fileId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('files')
        .doc(fileId)
        .delete()
        .timeout(const Duration(seconds: 5));
  }

  @override
  Stream<List<TodoModel>> getGroupTodos(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('todos')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) {
            print('ERROR fetching todos for group $groupId: $error');
          }
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return TodoModel(
                id: doc.id,
                task: data['task'] ?? '',
                completed: data['completed'] ?? false,
                createdBy: data['createdBy'] ?? '',
                priority: PriorityLevel.values.firstWhere(
                  (e) => e.name == (data['priority'] ?? 'low'),
                  orElse: () => PriorityLevel.low,
                ),
                dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
              );
            }).toList();
          } catch (e) {
            if (kDebugMode) {
              print('ERROR parsing todos: $e');
            }
            return [];
          }
        });
  }

  @override
  Future<void> addTodo(String groupId, TodoModel todo) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('todos')
        .add({
      'task': todo.task,
      'completed': todo.completed,
      'createdBy': todo.createdBy,
      'priority': todo.priority.name,
      'dueDate': todo.dueDate?.toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    }).timeout(const Duration(seconds: 5));
  }

  @override
  Future<void> toggleTodo(String groupId, String todoId, bool completed) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('todos')
        .doc(todoId)
        .update({'completed': completed})
        .timeout(const Duration(seconds: 5));
  }

  @override
  Future<void> deleteTodo(String groupId, String todoId) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('todos')
        .doc(todoId)
        .delete()
        .timeout(const Duration(seconds: 5));
  }

  @override
  Stream<List<EventModel>> getGroupEvents(String groupId) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) {
            print('ERROR fetching events for group $groupId: $error');
          }
        })
        .map((snapshot) {
          try {
            return snapshot.docs.map((doc) {
              final data = doc.data();
              return EventModel(
                id: doc.id,
                title: data['title'] ?? '',
                description: data['description'] ?? '',
                date: data['date'] != null
                    ? DateTime.parse(data['date'])
                    : DateTime.now(),
                type: data['type'] ?? '',
                createdBy: data['createdBy'] ?? '',
              );
            }).toList();
          } catch (e) {
            if (kDebugMode) {
              print('ERROR parsing events: $e');
            }
            return [];
          }
        });
  }

  // Notifications -----------------------------------------------------

  @override
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          if (kDebugMode) {
            print('ERROR fetching notifications for user $userId: $error');
          }
        })
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
                .toList();
          } catch (e) {
            if (kDebugMode) {
              print('ERROR parsing notifications: $e');
            }
            return <NotificationModel>[];
          }
        });
  }

  @override
  Future<void> markNotificationRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .set({'read': true}, SetOptions(merge: true))
        .timeout(const Duration(seconds: 5));
  }

  @override
  Future<void> addEvent(String groupId, EventModel event) async {
    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('events')
        .add({
      'title': event.title,
      'description': event.description,
      'date': event.date.toIso8601String(),
      'type': event.type,
      'createdBy': event.createdBy,
    }).timeout(const Duration(seconds: 5));
  }
}
