import 'package:hive_ce/hive_ce.dart';

/// Registers a [TypeAdapter] only if its typeId isn't already registered.
///
/// The `<T>` here is load-bearing, not decoration: hive_ce's
/// `registerAdapter` needs an explicit type argument to bind an adapter to
/// its actual model type. If this helper took a bare (non-generic)
/// `TypeAdapter` parameter, Dart would infer `T` as `dynamic` at the call
/// to `Hive.registerAdapter` below, and hive_ce would register every
/// adapter "for `dynamic`" instead of for its real type — each new
/// registration then silently overwrites the previous one, and whichever
/// adapter got registered last ends up handling every write, corrupting
/// unrelated types. Declaring the parameter as `TypeAdapter<T>` (not plain
/// `TypeAdapter`) is what lets Dart infer the real `T` from whatever
/// concrete adapter instance gets passed in (e.g. `StudentProfileAdapter`
/// implies `T = StudentProfile`), and `registerAdapter<T>(adapter)` below
/// then passes that real type through explicitly instead of leaving it to
/// chance.
///
/// Hive's adapter registry is process/isolate-wide, not per-Hive-instance
/// — `hive_ce_test`'s `tearDownTestHive()` resets boxes and on-disk
/// storage between tests, but does NOT clear previously registered
/// adapters. Since `flutter_test` runs every `test(...)` in a file inside
/// the same isolate, calling `Hive.registerAdapter(...)` again from
/// `setUp()` on the 2nd+ test in a file throws `HiveError: There is
/// already a TypeAdapter for typeId N` — hence the `isAdapterRegistered`
/// guard.
///
/// Used from both `initHive()` (production/app startup — defensive, in
/// case anything ever calls it more than once, e.g. a future integration
/// test) and every `hive_ce_test`-based round-trip test's `setUp()`.
void registerAdapterIfNeeded<T>(TypeAdapter<T> adapter) {
  if (!Hive.isAdapterRegistered(adapter.typeId)) {
    Hive.registerAdapter<T>(adapter);
  }
}
