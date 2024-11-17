import 'package:flutter/material.dart';

/// A Tab bar that can be used as [Scaffold.appBar].
class TabBarAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  final Size preferredSize;
  final TabController controller;
  final Color? backgroundColor;
  final List<Widget> tabs;
  final double dividerHeight;

  const TabBarAppBar({
    super.key,
    required this.preferredSize,
    required this.controller,
    this.backgroundColor,
    required this.tabs,
    this.dividerHeight = 1,
  });

  @override
  Widget build(BuildContext context) {
    // Build a "look-alike" TabBar: a Container with a bottom border and
    // ColorScheme.outlineVariant color makes it look like TabBar with divider.
    // Putting TabBar in a Row makes it pack tab to left instead of spreading.
    // (We're removing TabBar's own divider because it looks weird when tabs
    // are packed to left.)

    final scaffold = Scaffold.maybeOf(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: dividerHeight,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        color: backgroundColor,
      ),
      child: Row(
        children: [
          TabBar(
            controller: controller,
            dividerHeight: 0,
            isScrollable: true,
            tabs: tabs,
          ),
          if (scaffold?.hasEndDrawer == true) ...[
            const Expanded(child: SizedBox()),
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: scaffold!.openEndDrawer,
            ),
          ],
        ],
      ),
    );
  }
}
