import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_log/core/errors/app_failure.dart';

enum AppBootstrapStatus { bootstrapping, ready, localModeWarning, failed }

final class AppBootstrapState extends Equatable {
  final AppBootstrapStatus status;
  final String? warningMessage;
  final AppFailure? failure;

  const AppBootstrapState._({
    required this.status,
    this.warningMessage,
    this.failure,
  });

  const AppBootstrapState.bootstrapping()
    : this._(status: AppBootstrapStatus.bootstrapping);

  const AppBootstrapState.ready() : this._(status: AppBootstrapStatus.ready);

  const AppBootstrapState.localModeWarning(String warningMessage)
    : this._(
        status: AppBootstrapStatus.localModeWarning,
        warningMessage: warningMessage,
      );

  const AppBootstrapState.failed(AppFailure failure)
    : this._(status: AppBootstrapStatus.failed, failure: failure);

  @override
  List<Object?> get props => [status, warningMessage, failure];
}

final class AppBootstrapCubit extends Cubit<AppBootstrapState> {
  AppBootstrapCubit() : super(const AppBootstrapState.bootstrapping());

  void markReady() {
    emit(const AppBootstrapState.ready());
  }

  void showLocalModeWarning(String message) {
    emit(AppBootstrapState.localModeWarning(message));
  }

  void markFailed(AppFailure failure) {
    emit(AppBootstrapState.failed(failure));
  }
}
