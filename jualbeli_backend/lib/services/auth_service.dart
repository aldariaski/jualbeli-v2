import 'package:bcrypt/bcrypt.dart';

import '../database/database.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'jwt_service.dart';
import '../models/auth_result.dart';

class AuthService {
  final UserRepository _userRepository;
  final JwtService _jwtService;

  AuthService({UserRepository? userRepository, JwtService? jwtService})
    : _userRepository =
          userRepository ??
          UserRepository(database: DatabaseConnection.instance),
      _jwtService = jwtService ?? JwtService.instance;

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw Exception('Name is required.');
    }

    if (normalizedEmail.isEmpty) {
      throw Exception('Email is required.');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final existingUser = await _userRepository.findByEmail(normalizedEmail);

    if (existingUser != null) {
      throw Exception('An account with this email already exists.');
    }

    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    return await _userRepository.create(
      name: normalizedName,
      email: normalizedEmail,
      passwordHash: passwordHash,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    final user = await _userRepository.findByEmail(normalizedEmail);

    if (user == null) {
      throw Exception('Invalid email or password.');
    }

    final passwordValid = BCrypt.checkpw(password, user.passwordHash);

    if (!passwordValid) {
      throw Exception('Invalid email or password.');
    }

    if (user.id == null) {
      throw Exception('User ID is missing.');
    }

    final token = _jwtService.generateToken(
      userId: user.id!,
      email: user.email,
    );

    return AuthResult(user: user, token: token);
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      throw Exception('New password must be at least 6 characters.');
    }

    final user = await _userRepository.findByEmail(email);
    if (user == null || !BCrypt.checkpw(currentPassword, user.passwordHash)) {
      throw Exception('Current password is incorrect.');
    }

    final updated = await _userRepository.updatePassword(
      email: email,
      passwordHash: BCrypt.hashpw(newPassword, BCrypt.gensalt()),
    );

    if (!updated) {
      throw Exception('Unable to change password.');
    }
  }
}
