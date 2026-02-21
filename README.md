# Fishnet

A Flutter application for triggering various types of errors and viewing detailed crash reports.

## Features

- **8 Error Categories**: Null Errors, Type Errors, Range Errors, State Errors, Network Errors, Logic Errors, Async Errors, Custom Errors
- **60+ Error Types**: Comprehensive collection of common Dart/Flutter errors
- **Thread System**: 10 worker threads (Alpha-Juliet) with unique roles for error simulation
- **Thread Last Words**: 160+ dramatic English phrases displayed when a thread is terminated
- **Detailed Crash Reports**: APK info, device info, formatted stack traces, and thread information
- **Material Design 3**: Modern UI with automatic light/dark theme support
- **Error History**: Persistent storage of crash records using SharedPreferences
- **Export Reports**: Copy full crash reports to clipboard

## Thread Roles

| Thread | Role |
|--------|------|
| Alpha | UI Renderer |
| Bravo | Network Handler |
| Charlie | Database Worker |
| Delta | File Manager |
| Echo | Cache Controller |
| Foxtrot | Event Dispatcher |
| Golf | Task Scheduler |
| Hotel | Memory Monitor |
| India | Log Collector |
| Juliet | Backup Agent |

## Error Categories

### Null Errors
- Null Pointer, Null Method Call, Null Check Operator, Null Property Access, Null Iterable

### Type Errors
- Type Cast, Type Mismatch, Wrong Type Method, List Type Mismatch, Map Type Cast, DateTime Parse, JSON Decode, Double Parse, BigInt Parse, Format Parse

### Range Errors
- Index Out of Range, Negative Index, Range Error, List Empty Error, List Single Error, String Range, Set Range, Map Key Not Found

### State Errors
- Disposed Controller, Animation After Dispose, Stream After Close, Late Initialization, Closed Stream Listen, Ticker Inactive, Concurrent Modification

### Network Errors
- Socket Exception, Http Exception, Handshake Exception, DNS Lookup Failed, Connection Refused, Connection Timeout, SSL Certificate Error, WebSocket Exception

### Async Errors
- Timeout, Async Error, Future Error, Async Timeout, Future Wait Error, Stream Error, Completer Error, Isolate Spawn Error

### Logic Errors
- Assertion Failure, Unimplemented, Unsupported Operation, Division by Zero, Modulo by Zero, Stack Overflow, Integer Overflow, Negative Shift, Format Exception, Cyclic Error, Not Found Error, Buffer Overflow

### Custom Errors
- Argument Error, Range Error Custom, State Error, Custom Exception, Process Exception, File System Exception, Expando Error, Uri Parse Error, RegExp Error, Base64 Decode Error, Ascii Decode Error, Latin1 Decode Error, Unsupported Encoding

## Crash Report Format

Each error generates a detailed crash report containing:

```
****** Fishnet crash report 1.0.0 ******

Log type: Dart

APK info:
    Package: 'com.example.fishnet'
    Version: '1.0.0' (1)
    Build: 'debug'

Device info:
    Model: 'RMX5200'
    Brand: 'realme'
    Fingerprint: 'realme/RMX5200/RE6030L1:16/...'
    SDK: 36
    ABI: 'arm64'
    Is Physical Device: true
    Locale: 'zh-CN'

Timestamp: 2026-02-21 18:01:54.897461368+0800

Thread info:
    Thread ID: 3
    Thread Name: Delta
    Thread Role: File Manager
    Thread Status: TERMINATED
    Thread Last Word: "I have a wife and kids waiting for me..."

Error info:
    Error type: Null Pointer
    Category: Null Errors
    Message: Null check operator used on a null value

Stack trace:
    #00 main.dart:158:22 (String Function() trigger)
    #01 main.dart:606:6 (void _triggerError)
    ...

Dart runtime:
    Platform: android 16
    Dart version: 3.10.8
    Number of processors: 8

--- END OF CRASH REPORT ---
```

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
- Creates a GitHub Release with detailed release notes

Artifacts are available for download from the Releases page.

## Download

Download the latest release from: https://github.com/ChidcGithub/Fishnet/releases

## Dependencies

- shared_preferences - Persistent storage
- intl - Date formatting
- device_info_plus - Device information
- package_info_plus - App information

## License

Apache License 2.0
