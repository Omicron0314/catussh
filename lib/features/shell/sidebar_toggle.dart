// The sidebar toggle that sits in the title bar.

import 'package:flutter/material.dart';

import '../../core/strings.dart';

class SidebarToggle extends StatelessWidget {
  const SidebarToggle({super.key, required this.visible, required this.onPressed});

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: visible ? S.l.hideSidebar : S.l.showSidebar,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(minimumSize: const Size(32, 32), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      icon: Icon(visible ? Icons.view_sidebar : Icons.view_sidebar_outlined),
      onPressed: onPressed,
    );
  }
}
