import 'package:flutter/material.dart';
import 'package:life_log/common/theme/theme_extensions.dart';

import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

enum AppSheetPresentation { sheet, page }

class AppSheetScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? bottomBar;
  final double? height;
  final EdgeInsetsGeometry padding;
  final bool showGrabber;
  final bool scrollable;
  final AppSheetPresentation presentation;
  final bool hideBottomBarWhenKeyboardVisible;

  const AppSheetScaffold({
    super.key,
    this.title,
    required this.child,
    this.bottomBar,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    this.showGrabber = true,
    this.scrollable = false,
    this.presentation = AppSheetPresentation.sheet,
    this.hideBottomBarWhenKeyboardVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.semanticColors;
    final isPage = presentation == AppSheetPresentation.page;
    final view = View.of(context);
    final bottomInset = view.viewInsets.bottom / view.devicePixelRatio;
    final rootHeight = view.physicalSize.height / view.devicePixelRatio;
    final resizedByKeyboard = rootHeight - MediaQuery.sizeOf(context).height;
    final isKeyboardVisible = bottomInset > 0 || resizedByKeyboard > 120;
    final content = AnimatedPadding(
      duration: AppMotion.fast,
      curve: AppMotion.standardDecelerate,
      padding: EdgeInsets.only(
        bottom:
            (isPage ? 0.0 : bottomInset) +
            (bottomBar == null ? AppSpacing.xl : AppSpacing.lg),
      ),
      child: Padding(padding: padding, child: child),
    );
    final effectiveHeight = isPage ? double.infinity : height;
    final effectiveShowGrabber = !isPage && showGrabber;
    final maxScrollableHeight = MediaQuery.sizeOf(context).height * 0.72;
    final showBottomBar =
        bottomBar != null &&
        !(hideBottomBarWhenKeyboardVisible && isKeyboardVisible);

    final scaffold = Container(
      height: effectiveHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isPage ? theme.scaffoldBackgroundColor : theme.cardColor,
        borderRadius: isPage
            ? BorderRadius.zero
            : const BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
        border: isPage
            ? null
            : Border(top: BorderSide(color: semantic.border, width: 1)),
      ),
      child: Column(
        mainAxisSize: effectiveHeight == null
            ? MainAxisSize.min
            : MainAxisSize.max,
        children: [
          if (effectiveShowGrabber) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: semantic.border.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
          if (title != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _SheetTitle(title: title!, isPage: isPage),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (effectiveHeight == null)
            scrollable
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxScrollableHeight),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: content,
                    ),
                  )
                : content
          else
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: content,
                    )
                  : content,
            ),
          if (showBottomBar) bottomBar!,
        ],
      ),
    );

    return scaffold;
  }
}

class _SheetTitle extends StatelessWidget {
  final String title;
  final bool isPage;

  const _SheetTitle({required this.title, required this.isPage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = Text(
      title,
      textAlign: TextAlign.center,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );

    if (!isPage) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: titleText,
      );
    }

    final canPop = Navigator.canPop(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: titleText,
            ),
            if (canPop)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
