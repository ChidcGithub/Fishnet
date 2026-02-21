# Fishnet

A Flutter application for testing and recording various types of errors.

## Features

- Trigger different types of errors intentionally
- View error history with timestamps
- Error records persist after app restart
- Clear error history

## Supported Error Types

- Null Error
- Range Error
- Type Error
- Format Error
- State Error
- Assertion Error
- Unsupported Error
- Timeout Error
- IO Error
- Custom Exception
- Division By Zero
- Stack Overflow

## Building

### Prerequisites

- Flutter SDK 3.38.9 or later
- Java 17
- Android SDK

### Build APK

```bash
flutter pub get
flutter build apk --release
```

### Build App Bundle

```bash
flutter build appbundle --release
```

## CI/CD

This project uses GitHub Actions for automated builds. On every push to main/master branch:
- Runs Flutter analyze
- Runs tests
- Builds release APK
- Builds release App Bundle

Artifacts are available for download from the workflow run.

## License

Apache License 2.0
