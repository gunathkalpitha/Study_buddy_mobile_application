


// Note: Since we are using mock data initially, we treat Timestamp as DateTime in some places
// or convert logic. But the requested schema uses Firestore types.
// I will use DateTime for the models to be independent of Firestore for the mock,
// but add helper methods to convert if needed later.

class UserModel {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final List<String> groupIds;
  final DateTime createdAt;
  final double studyHours;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.groupIds,
    required this.createdAt,
    this.studyHours = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'groupIds': groupIds,
      'createdAt': createdAt.toIso8601String(),
      'studyHours': studyHours,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      groupIds: List<String>.from(map['groupIds'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
      studyHours: (map['studyHours'] ?? 0.0).toDouble(),
    );
  }
}

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String adminId;
  final List<String> memberIds;
  final String inviteCode;
  final DateTime createdAt;
  final String subject;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.adminId,
    required this.memberIds,
    required this.inviteCode,
    required this.createdAt,
    required this.subject,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adminId': adminId,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'subject': subject,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      adminId: map['adminId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      inviteCode: map['inviteCode'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now(),
      subject: map['subject'] ?? '',
    );
  }
}

enum MessageType { text, image, system }

class MessageModel {
  final String id;
  final String text;
  final String senderId;
  final String senderName;
  final DateTime timestamp;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderName,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MessageType.text,
      ),
    );
  }
}

class FileModel {
  final String id;
  final String name;
  final String url;
  final String type; // pdf, doc, jpg, etc.
  final String uploadedBy;
  final String uploadedByName;
  final DateTime timestamp;
  final int sizeBytes;

  FileModel({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.uploadedBy,
    required this.uploadedByName,
    required this.timestamp,
    required this.sizeBytes,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'uploadedBy': uploadedBy,
      'uploadedByName': uploadedByName,
      'timestamp': timestamp.toIso8601String(),
      'sizeBytes': sizeBytes,
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      type: map['type'] ?? '',
      uploadedBy: map['uploadedBy'] ?? '',
      uploadedByName: map['uploadedByName'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
      sizeBytes: map['sizeBytes'] ?? 0,
    );
  }
}

enum PriorityLevel { low, medium, high }

class TodoModel {
  final String id;
  final String task;
  final bool completed;
  final String createdBy;
  final String assignedTo;
  final DateTime? dueDate;
  final PriorityLevel priority;

  TodoModel({
    required this.id,
    required this.task,
    this.completed = false,
    required this.createdBy,
    this.assignedTo = '',
    this.dueDate,
    this.priority = PriorityLevel.medium,
  });

  TodoModel copyWith({bool? completed}) {
    return TodoModel(
      id: id,
      task: task,
      completed: completed ?? this.completed,
      createdBy: createdBy,
      assignedTo: assignedTo,
      dueDate: dueDate,
      priority: priority,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'completed': completed,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.toString(),
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] ?? '',
      task: map['task'] ?? '',
      completed: map['completed'] ?? false,
      createdBy: map['createdBy'] ?? '',
      assignedTo: map['assignedTo'] ?? '',
      dueDate: map['dueDate'] != null ? DateTime.tryParse(map['dueDate']) : null,
      priority: PriorityLevel.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => PriorityLevel.medium,
      ),
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String type; // study, exam, assignment
  final String createdBy;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.type,
    required this.createdBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'type': type,
      'createdBy': createdBy,
    };
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.tryParse(map['date'].toString()) ?? DateTime.now(),
      type: map['type'] ?? 'study',
      createdBy: map['createdBy'] ?? '',
    );
  }
}

enum NotificationType { message, todo, reminder, group, system }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime timestamp;
  final bool read;
  final String? groupId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.read = false,
    this.groupId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'read': read,
      'groupId': groupId,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'system'),
        orElse: () => NotificationType.system,
      ),
      timestamp: DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now(),
      read: map['read'] ?? false,
      groupId: map['groupId'],
    );
  }
}
