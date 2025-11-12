import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/feature/authentication/data/repository/auth_repository.dart';
import 'package:frontend/feature/authentication/google_sign_in.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<FetchProfile>(_onFetchProfile);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onGoogleSignInRequested(
      GoogleSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final idToken = await AuthService().signInWithGoogle();
      final user = await _authRepository.signInWithGoogle(idToken!);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError('Failed to sign in'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onFetchProfile(
      FetchProfile event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.getProfile();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError('Failed to fetch profile: $e'));
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.signOut();
    emit(Unauthenticated());
  }
}
