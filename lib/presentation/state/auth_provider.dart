import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { anonymous, authenticated }

class AuthState {
  final AuthStatus status;
  final String username;
  final String email;

  const AuthState({
    required this.status,
    required this.username,
    required this.email,
  });

  factory AuthState.anonymous() => const AuthState(
        status: AuthStatus.anonymous,
        username: 'AETHER GUEST',
        email: '',
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.anonymous());

  void login() {
    state = const AuthState(
      status: AuthStatus.authenticated,
      username: 'FLUX ARCHITECT',
      email: 'admin@kerlyss.io',
    );
  }

  void logout() {
    state = AuthState.anonymous();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
