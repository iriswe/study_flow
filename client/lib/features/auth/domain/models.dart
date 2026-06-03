import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;

  const User({required this.id, required this.username});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId'] as int,
      username: json['username'] as String,
    );
  }

  @override
  List<Object?> get props => [id, username];
}

class AuthResponse extends Equatable {
  final String token;
  final String tokenType;
  final int userId;
  final String username;

  const AuthResponse({
    required this.token,
    required this.tokenType,
    required this.userId,
    required this.username,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      tokenType: json['tokenType'] as String,
      userId: json['userId'] as int,
      username: json['username'] as String,
    );
  }

  @override
  List<Object?> get props => [token, tokenType, userId, username];
}