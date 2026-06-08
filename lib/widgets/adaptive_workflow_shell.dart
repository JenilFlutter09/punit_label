import 'package:flutter/material.dart';

import '../constants/app_layout.dart';

class AdaptiveWorkflowShell extends StatelessWidget {
  const AdaptiveWorkflowShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.compactContent,
    this.leftPanel,
    this.rightPanel,
    this.primaryAction,
    this.result,
    this.topWidgets = const [],
    this.headerBadge,
  });

  final String title;
  final String subtitle;
  final Widget compactContent;
  final Widget? leftPanel;
  final Widget? rightPanel;
  final Widget? primaryAction;
  final Widget? result;
  final List<Widget> topWidgets;
  final String? headerBadge;

  @override
  Widget build(BuildContext context) {
    final layout = context.layoutSpec;
    final content = <Widget>[
      // _AdaptiveWorkflowHeader(
      //   title: title,
      //   subtitle: subtitle,
      //   badge: headerBadge,
      //   layout: layout,
      // ),
      if (topWidgets.isNotEmpty) ...[
        SizedBox(height: layout.sectionSpacing),
        ...topWidgets,
      ],
      SizedBox(height: layout.sectionSpacing),
      if (layout.isExpandedTablet && leftPanel != null && rightPanel != null)
        Row(
          key: const Key('adaptive_workflow_split_row'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 10, child: leftPanel!),
            SizedBox(width: layout.panelSpacing),
            Expanded(flex: 11, child: rightPanel!),
          ],
        )
      else
        KeyedSubtree(
          key: const Key('adaptive_workflow_compact_body'),
          child: compactContent,
        ),
      if (primaryAction != null) ...[
        SizedBox(height: layout.sectionSpacing),
        primaryAction!,
      ],
      if (result != null) ...[SizedBox(height: layout.sectionSpacing), result!],
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.contentMaxWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            layout.pageHorizontalPadding,
            layout.pageVerticalPadding,
            layout.pageHorizontalPadding,
            layout.pageHorizontalPadding,
          ),
          children: content,
        ),
      ),
    );
  }
}

class AdaptiveSectionCard extends StatelessWidget {
  const AdaptiveSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = context.layoutSpec;

    return Card(
      color: Colors.white,
      margin: margin,
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: padding ?? EdgeInsets.all(layout.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null || subtitle != null || trailing != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            if (title != null || subtitle != null || trailing != null)
              SizedBox(height: layout.sectionSpacing - 6),
            child,
          ],
        ),
      ),
    );
  }
}

class _AdaptiveWorkflowHeader extends StatelessWidget {
  const _AdaptiveWorkflowHeader({
    required this.title,
    required this.subtitle,
    required this.layout,
    this.badge,
  });

  final String title;
  final String subtitle;
  final String? badge;
  final AppLayoutSpec layout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.cardPadding,
        vertical: layout.isExpandedTablet ? 20 : 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            theme.colorScheme.primary.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D163A66),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: layout.isExpandedTablet ? 56 : 48,
            height: layout.isExpandedTablet ? 56 : 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.space_dashboard_rounded,
              color: theme.colorScheme.primary,
              size: layout.isExpandedTablet ? 30 : 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null && badge!.trim().isNotEmpty) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge!,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
