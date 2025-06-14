import 'package:cloud_firestore/cloud_firestore.dart';

class Worker {
  final String id;
  final String name;
  final String email;
  final String companyId;
  final DateTime createdAt;
  final bool isActive;

  Worker({
    required this.id,
    required this.name,
    required this.email,
    required this.companyId,
    required this.createdAt,
    required this.isActive,
  });

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      companyId: map['companyId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'companyId': companyId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
} 