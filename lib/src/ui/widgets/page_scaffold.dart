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
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;
  final PageStorageKey<String>? scrollKey;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        key: scrollKey ?? PageStorageKey<String>('page-$title'),
        controller: scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (action != null) action!,
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            sliver: SliverList.list(children: children),
          ),
        ],
      ),
    );
  }
}
