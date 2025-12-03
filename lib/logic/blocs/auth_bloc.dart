import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  StreamSubscription? _authSubscription;

  AuthBloc({required this.authRepository}) : super(const AuthInitialState()) {
    // Listen to auth state changes
    _authSubscription = authRepository.authStateChanges().listen((user) {
      add(AuthUserChanged(user));
    });

    on<AuthInitialized>(_initialState);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthGuestModeRequested>(_onGuestModeRequested);
    on<AuthAccountRequestSubmitted>(_onAccountRequestSubmitted);
  }

  Future<void> _initialState(
    AuthInitialized event,
    Emitter<AuthState> emit,
  ) async {
    final currentUser = authRepository.getCurrentUser();
    if (currentUser != null) {
      emit(Authenticated(currentUser));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.signIn(event.email, event.password);
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Sign in failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.signOut();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(Authenticated(event.user!));
    } else {
      // Only emit unauthenticated if not in guest mode
      if (state is! GuestMode) {
        emit(const Unauthenticated());
      }
    }
  }

  void _onGuestModeRequested(
    AuthGuestModeRequested event,
    Emitter<AuthState> emit,
  ) {
    emit(const GuestMode());
  }

  Future<void> _onAccountRequestSubmitted(
    AuthAccountRequestSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await authRepository.submitAccountRequest(
        event.name,
        event.phone,
        event.email,
      );
      emit(const AccountRequestSubmitted());
      // Return to guest mode after submission
      await Future.delayed(const Duration(seconds: 2));
      emit(const GuestMode());
    } catch (e) {
      emit(AuthError('Failed to submit request: ${e.toString()}'));
      // Return to guest mode even on error
      await Future.delayed(const Duration(seconds: 2));
      emit(const GuestMode());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
