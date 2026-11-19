// A live preview driven by a slider (the Backlights card's brightness): a drag fires
// onChanged far faster than the server and the LED board can follow, so the preview sends
// at most one value per [PreviewThrottle.interval], the newest one (latest wins), and on
// release the released value itself. Pure timers, so tests drive it on a fake clock.
import 'dart:async';

class PreviewThrottle<T> {
  PreviewThrottle(this._send, {this.interval = const Duration(milliseconds: 100)});

  /// Sends one value. Its errors are its own to show: the throttle swallows them so a
  /// failed preview never stops the next one.
  final Future<void> Function(T value) _send;
  final Duration interval;

  Timer? _quiet;
  bool _hasPending = false;
  T? _pending;
  bool _hasSent = false;
  T? _lastSent;

  // Every call runs after the one before it, so the released value lands last even when
  // an earlier call is still on its way.
  Future<void> _chain = Future<void>.value();

  /// A new value while dragging: sent at once when nothing was sent in the last
  /// [interval]; otherwise kept, replacing any value kept before, and sent when the
  /// interval is over.
  void add(T value) {
    if (_quiet != null) {
      _pending = value;
      _hasPending = true;
      return;
    }
    _sendNow(value);
    _quiet = Timer(interval, _onQuiet);
  }

  void _onQuiet() {
    _quiet = null;
    if (!_hasPending) return;
    final value = _pending as T;
    _hasPending = false;
    _pending = null;
    add(value);
  }

  void _sendNow(T value) {
    _hasSent = true;
    _lastSent = value;
    _chain = _chain.then((_) => _send(value)).catchError((Object _) {});
  }

  /// The release: drops the kept value and the interval, sends [value] at once unless it
  /// is null or the last value sent, and completes when every call sent so far is done.
  Future<void> flush(T? value) {
    _quiet?.cancel();
    _quiet = null;
    _hasPending = false;
    _pending = null;
    if (value != null && !(_hasSent && _lastSent == value)) _sendNow(value);
    return _chain;
  }

  /// Forgets what was sent, so the next [flush] sends its value even when it equals the
  /// last one (the output may have changed meanwhile).
  void forget() {
    _hasSent = false;
    _lastSent = null;
  }

  void dispose() {
    _quiet?.cancel();
    _quiet = null;
  }
}
