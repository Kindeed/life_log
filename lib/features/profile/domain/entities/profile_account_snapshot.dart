import 'package:equatable/equatable.dart';

final class ProfileAccountSnapshot extends Equatable {
  final bool isCloudConfigured;
  final String? userEmail;

  const ProfileAccountSnapshot({
    required this.isCloudConfigured,
    required this.userEmail,
  });

  bool get isLoggedIn => userEmail != null;

  String get userName {
    if (!isCloudConfigured) return '本地模式';
    return userEmail ?? '未登录';
  }

  @override
  List<Object?> get props => [isCloudConfigured, userEmail];
}
