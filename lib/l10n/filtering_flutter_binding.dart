import 'package:flutter/material.dart';

class FilteringFlutterBinding extends WidgetsFlutterBinding {
  @override
  void handlePointerEvent(PointerEvent event) {
    if (event.position == Offset.zero) {
      return;
    }
    super.handlePointerEvent(event);
  }
}
