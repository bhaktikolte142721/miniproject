// Web implementation using dart:js to trigger browser printing
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Triggers the browser's native window.print() dialog to print or save PDF.
void triggerWebPrint() {
  try {
    js.context.callMethod('print', []);
  } catch (_) {}
}
