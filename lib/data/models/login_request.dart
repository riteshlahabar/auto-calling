// lib/data/models/login_request.dart
class LoginRequest {
  final String name;
  final String password;
  const LoginRequest({required this.name, required this.password});

  Map<String, dynamic> toJson() => {
    'name': name,
    'password': password,
  };
}
