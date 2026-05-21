import 'package:flutter/material.dart';

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
    this.scrollKey,
    this.scrollController,
    this.physics,
    this.trailingSliver,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;
  final PageStorageKey<String>? scrollKey;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;
  final Widget? trailingSliver;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 640;
    final horizontalPadding = compact ? 14.0 : 24.0;
    final topPadding = compact ? 14.0 : 20.0;
    return SafeArea(
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
        child: CustomScrollView(
          key: scrollKey ?? PageStorageKey<String>('page-$title'),
          controller: scrollController,
          clipBehavior: Clip.hardEdge,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics:
              physics ??
              const ClampingScrollPhysics(
                parent: RangeMaintainingScrollPhysics(),
              ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                8,
              ),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: action == null
                            ? double.infinity
                            : (width > 180 ? width - 120 : width),
                      ),
                      child: _PageTitle(
                        title: title,
                        subtitle: subtitle,
                        compact: compact,
                      ),
                    ),
                    if (action != null) action!,
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                8,
                horizontalPadding,
                trailingSliver == null ? 24 : 8,
              ),
              sliver: SliverList.list(children: children),
            ),
            if (trailingSliver != null)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  24,
                ),
                sliver: trailingSliver!,
              ),
          ],
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle({
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        SizedBox(height: compact ? 2 : 4),
        Text(
          title,
          style:
              (compact
                      ? Theme.of(context).textTheme.headlineSmall
                      : Theme.of(context).textTheme.headlineMedium)
                  ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
