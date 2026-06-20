import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';
import 'package:life_log/features/profile/application/load_profile_account.dart';
import 'package:life_log/features/profile/application/watch_profile_account.dart';
import 'package:life_log/features/profile/domain/entities/profile_account_snapshot.dart';

enum ProfileAccountStatus { initial, loading, ready, failure }

final class ProfileAccountState extends Equatable {
  final ProfileAccountStatus status;
  final ProfileAccountSnapshot snapshot;
  final AppFailure? failure;

  const ProfileAccountState({
    required this.status,
    required this.snapshot,
    this.failure,
  });

  factory ProfileAccountState.initial() {
    return const ProfileAccountState(
      status: ProfileAccountStatus.initial,
      snapshot: ProfileAccountSnapshot(
        isCloudConfigured: false,
        userEmail: null,
      ),
    );
  }

  bool get isCloudConfigured => snapshot.isCloudConfigured;

  bool get isLoggedIn => snapshot.isLoggedIn;

  String get userName => snapshot.userName;

  ProfileAccountState copyWith({
    ProfileAccountStatus? status,
    ProfileAccountSnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return ProfileAccountState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, failure];
}

final class ProfileAccountCubit extends Cubit<ProfileAccountState> {
  final LoadProfileAccount _loadAccount;
  final WatchProfileAccount _watchAccount;
  StreamSubscription<ProfileAccountSnapshot>? _accountSubscription;

  ProfileAccountCubit({
    required LoadProfileAccount loadAccount,
    required WatchProfileAccount watchAccount,
  }) : _loadAccount = loadAccount,
       _watchAccount = watchAccount,
       super(ProfileAccountState.initial());

  void start() {
    if (_accountSubscription != null) return;

    unawaited(loadAccount());
    _accountSubscription = _watchAccount().listen((snapshot) {
      if (isClosed) return;
      emit(
        ProfileAccountState(
          status: ProfileAccountStatus.ready,
          snapshot: snapshot,
        ),
      );
    });
  }

  Future<void> loadAccount() async {
    if (isClosed) return;
    emit(
      state.copyWith(status: ProfileAccountStatus.loading, clearFailure: true),
    );

    final result = await _loadAccount();
    if (isClosed) return;
    result.when(
      success: (snapshot) {
        emit(
          ProfileAccountState(
            status: ProfileAccountStatus.ready,
            snapshot: snapshot,
          ),
        );
      },
      failure: (failure) {
        emit(
          state.copyWith(
            status: ProfileAccountStatus.failure,
            failure: failure,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _accountSubscription?.cancel();
    return super.close();
  }
}
