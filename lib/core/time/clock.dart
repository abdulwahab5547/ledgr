import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inject [Clock] anywhere a `DateTime.now()` would otherwise hide in code.
/// Tests override [clockProvider] to make recurrence and snapshot logic
/// deterministic.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());
