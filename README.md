# Ledgr

**The Financial Integrity Engine.** A local-first Flutter app that reconciles fragmented money sources (multiple bank balances, IOUs, future cash flow) into one True Liquidity number.

## Status

Modules **1 (Foundation/Core)** and **2 (Liquidity Vault)** are scaffolded. Frontend visual design is on hold pending the design language. Current screens are minimal functional scaffolds.

See the implementation plan: [`/Users/abdulwahab/.claude/plans/we-need-to-build-unified-puppy.md`](file:///Users/abdulwahab/.claude/plans/we-need-to-build-unified-puppy.md).

## Setup

The project is bootstrapped. Flutter SDK 3.41.8 is installed at `~/development/flutter`. Platform folders (`ios/`, `android/`, `macos/`) are generated, dependencies resolved, and all 30 tests pass.

To make `flutter` available in new terminals, add this to `~/.zshrc`:

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

Then, from this directory:

```bash
flutter test       # 30 tests
flutter analyze    # clean
flutter run        # launches the app on a connected device or simulator
```

`flutter doctor` reports Android toolchain and Xcode are not yet installed — required only when targeting those platforms. Web (Chrome) is ready.

Hive type adapters are hand-written, so `build_runner` is not required. If you later add `@HiveType` annotations, run `dart run build_runner build --delete-conflicting-outputs`.

## Architecture

- **Stack:** Flutter + Riverpod + Hive (encrypted, AES-256) + go_router.
- **Money:** all amounts are integer minor units (`Money` value object). No floats.
- **Security:** AES-256 encryption key generated on first launch and stored in the OS secure enclave via `flutter_secure_storage`. Biometric gate via `local_auth`.
- **Privacy Mode:** global "Ghost Toggle" — wraps any monetary `Text` in a `PrivacyMask`.
- **Layering:** `lib/core/` (cross-cutting), `lib/features/<feature>/{data,domain,presentation}/`.
