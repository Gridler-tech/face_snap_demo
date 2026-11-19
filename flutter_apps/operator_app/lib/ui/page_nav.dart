import 'package:flutter/foundation.dart';

/// The navigation rail's label of the Column page.
const columnPageLabel = 'Column';

/// A page asks the shell to show another page (the ● marks' "open the Column page"
/// link); HomeShell listens.
class PageNav {
  PageNav._();

  static final ValueNotifier<String?> request = ValueNotifier(null);

  /// Show the page with this rail label.
  static void open(String label) {
    request.value = null; // the same page asked twice still notifies
    request.value = label;
  }
}
