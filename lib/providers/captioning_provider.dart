import 'package:flutter/widgets.dart';

import '../controllers/captioning_controller.dart';

class CaptioningProvider extends InheritedNotifier<CaptioningController> {
  const CaptioningProvider({
    super.key,
    required CaptioningController controller,
    required super.child,
  }) : super(notifier: controller);

  static CaptioningController of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<CaptioningProvider>();
    assert(provider != null, 'CaptioningProvider not found in widget tree.');
    return provider!.notifier!;
  }
}
