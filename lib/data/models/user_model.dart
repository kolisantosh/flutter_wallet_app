import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String password;
  final String name;
  final DateTime createdAt;

  const UserModel({required this.id, required this.email, required this.password, required this.name, required this.createdAt});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'password': password, 'name': name, 'created_at': createdAt.toIso8601String()};
  }

  @override
  List<Object?> get props => [id, email, password, name, createdAt];
}
