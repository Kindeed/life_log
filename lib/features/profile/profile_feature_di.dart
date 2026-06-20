import 'package:get_it/get_it.dart';
import 'package:life_log/common/services/auth_service.dart';
import 'package:life_log/common/services/cloud_config_service.dart';
import 'package:life_log/common/services/sync_service.dart';
import 'package:life_log/core/di/service_locator.dart';
import 'package:life_log/features/profile/application/load_profile_account.dart';
import 'package:life_log/features/profile/application/sign_in_profile_account.dart';
import 'package:life_log/features/profile/application/sign_out_profile_account.dart';
import 'package:life_log/features/profile/application/sign_up_profile_account.dart';
import 'package:life_log/features/profile/application/sync_profile_data.dart';
import 'package:life_log/features/profile/application/watch_profile_account.dart';
import 'package:life_log/features/profile/data/legacy_profile_account_adapter.dart';
import 'package:life_log/features/profile/domain/repositories/profile_account_repository_port.dart';
import 'package:life_log/features/profile/presentation/login_cubit.dart';
import 'package:life_log/features/profile/presentation/profile_account_cubit.dart';

GetIt configureProfileFeatureDependencies({
  GetIt? locator,
  ProfileAccountRepositoryPort? repository,
}) {
  final activeLocator = locator ?? serviceLocator;

  if (!activeLocator.isRegistered<ProfileAccountRepositoryPort>()) {
    activeLocator.registerLazySingleton<ProfileAccountRepositoryPort>(
      () =>
          repository ??
          LegacyProfileAccountAdapter(
            cloudConfig: activeLocator<CloudConfigService>(),
            authService: activeLocator.isRegistered<AuthService>()
                ? activeLocator<AuthService>()
                : null,
            syncService: activeLocator.isRegistered<SyncService>()
                ? activeLocator<SyncService>()
                : null,
          ),
    );
  }

  if (!activeLocator.isRegistered<LoadProfileAccount>()) {
    activeLocator.registerLazySingleton<LoadProfileAccount>(
      () => LoadProfileAccount(activeLocator<ProfileAccountRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<WatchProfileAccount>()) {
    activeLocator.registerLazySingleton<WatchProfileAccount>(
      () => WatchProfileAccount(activeLocator<ProfileAccountRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SignInProfileAccount>()) {
    activeLocator.registerLazySingleton<SignInProfileAccount>(
      () => SignInProfileAccount(activeLocator<ProfileAccountRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SignUpProfileAccount>()) {
    activeLocator.registerLazySingleton<SignUpProfileAccount>(
      () => SignUpProfileAccount(activeLocator<ProfileAccountRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SignOutProfileAccount>()) {
    activeLocator.registerLazySingleton<SignOutProfileAccount>(
      () =>
          SignOutProfileAccount(activeLocator<ProfileAccountRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<SyncProfileData>()) {
    activeLocator.registerLazySingleton<SyncProfileData>(
      () => SyncProfileData(activeLocator<ProfileAccountRepositoryPort>()),
    );
  }

  if (!activeLocator.isRegistered<ProfileAccountCubit>()) {
    activeLocator.registerFactory<ProfileAccountCubit>(
      () => ProfileAccountCubit(
        loadAccount: activeLocator<LoadProfileAccount>(),
        watchAccount: activeLocator<WatchProfileAccount>(),
      ),
    );
  }

  if (!activeLocator.isRegistered<LoginCubit>()) {
    activeLocator.registerFactory<LoginCubit>(
      () => LoginCubit(
        signIn: activeLocator<SignInProfileAccount>(),
        signUp: activeLocator<SignUpProfileAccount>(),
        isCloudAvailable:
            activeLocator<ProfileAccountRepositoryPort>().isCloudAvailable,
      ),
    );
  }

  return activeLocator;
}
