import 'package:equatable/equatable.dart';

class AccountRequest extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final DateTime createdAt;
  final String status;

  const AccountRequest({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.status = 'pending',
  });

  factory AccountRequest.fromJson(Map<String, dynamic> json) {
    return AccountRequest(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  @override
  List<Object?> get props => [id, name, phone, email, createdAt, status];
}
