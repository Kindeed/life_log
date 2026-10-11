import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:life_log/common/layout/constrained_page.dart';
import 'package:life_log/common/widgets/app_card.dart';
import 'package:life_log/common/widgets/app_page_route.dart';
import 'package:life_log/common/widgets/app_settings.dart';
import 'developer_view.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  Future<String> _loadVersionText() async {
    final info = await PackageInfo.fromPlatform();
    return '版本 ${info.version}+${info.buildNumber}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('关于与诊断')),
      body: SafeArea(
        child: ConstrainedPage(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            child: Column(
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          Icons.calendar_month_rounded,
                          color: scheme.onPrimaryContainer,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('LifeLog', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: _loadVersionText(),
                        builder: (_, snapshot) => Text(
                          snapshot.data ?? '版本 --',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '记录工时、管理支出和订阅，保留项目现场的照片与凭证。',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const AppSettingsGroup(
                  title: '应用信息',
                  children: [
                    AppSettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: '开发者',
                      subtitle: '个人开发',
                    ),
                    AppSettingsTile(
                      icon: Icons.code_rounded,
                      title: '技术栈',
                      subtitle: 'Flutter + GoRouter',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                AppSettingsGroup(
                  title: '诊断',
                  children: [
                    AppSettingsTile(
                      icon: Icons.bug_report_outlined,
                      title: '开发者选项',
                      subtitle: '日志、调试、诊断信息',
                      onTap: () => Navigator.of(context).push<void>(
                        appPageRoute<void>(context, const DeveloperView()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '© ${DateTime.now().year} LifeLog',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
