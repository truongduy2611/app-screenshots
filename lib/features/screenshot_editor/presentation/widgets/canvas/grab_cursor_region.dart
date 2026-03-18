import 'package:flutter/material.dart';

/// Wraps a child with grab/grabbing cursor behavior.
///
/// Shows [SystemMouseCursors.grab] on hover and switches to
/// [SystemMouseCursors.grabbing] while the pointer is pressed.
class GrabCursorRegion extends StatefulWidget {
  const GrabCursorRegion({super.key, required this.child});
  final Widget child;

  @override
  State<GrabCursorRegion> createState() => _GrabCursorRegionState();
}

class _GrabCursorRegionState extends State<GrabCursorRegion> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: _isDragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,
      child: Listener(
        onPointerDown: (_) => setState(() => _isDragging = true),
        onPointerUp: (_) => setState(() => _isDragging = false),
        onPointerCancel: (_) => setState(() => _isDragging = false),
        child: widget.child,
      ),
    );
  }
}
