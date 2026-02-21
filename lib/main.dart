import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  runApp(const FishnetApp());
}

enum ErrorCategory {
  nullErrors('Null Errors', Icons.block, Color(0xFFE53935)),
  typeErrors('Type Errors', Icons.data_object, Color(0xFF8E24AA)),
  rangeErrors('Range Errors', Icons.format_list_numbered, Color(0xFFFB8C00)),
  stateErrors('State Errors', Icons.sync_problem, Color(0xFF43A047)),
  networkErrors('Network Errors', Icons.wifi_off, Color(0xFF1E88E5)),
  logicErrors('Logic Errors', Icons.psychology, Color(0xFF5E35B1)),
  asyncErrors('Async Errors', Icons.timer_off, Color(0xFF00ACC1)),
  customErrors('Custom Errors', Icons.bug_report, Color(0xFFD81B60));

  final String label;
  final IconData icon;
  final Color color;

  const ErrorCategory(this.label, this.icon, this.color);
}

class ErrorDefinition {
  final String name;
  final ErrorCategory category;
  final String Function() trigger;

  const ErrorDefinition({
    required this.name,
    required this.category,
    required this.trigger,
  });
}

class ErrorRecord {
  final String id;
  final String type;
  final String category;
  final String message;
  final String stackTrace;
  final DateTime timestamp;
  final String fullReport;
  final int? threadId;
  final String? threadName;
  final String? threadRole;
  final String? threadLastWord;

  ErrorRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
    required this.fullReport,
    this.threadId,
    this.threadName,
    this.threadRole,
    this.threadLastWord,
  });

  factory ErrorRecord.fromJson(Map<String, dynamic> json) {
    return ErrorRecord(
      id: json['id'],
      type: json['type'],
      category: json['category'] ?? 'Unknown',
      message: json['message'],
      stackTrace: json['stackTrace'],
      timestamp: DateTime.parse(json['timestamp']),
      fullReport: json['fullReport'] ?? '',
      threadId: json['threadId'],
      threadName: json['threadName'],
      threadRole: json['threadRole'],
      threadLastWord: json['threadLastWord'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'message': message,
      'stackTrace': stackTrace,
      'timestamp': timestamp.toIso8601String(),
      'fullReport': fullReport,
      'threadId': threadId,
      'threadName': threadName,
      'threadRole': threadRole,
      'threadLastWord': threadLastWord,
    };
  }
}

class ThreadLastWords {
  static final List<String> _lastWords = [
    "I have a wife and kids waiting for me...",
    "Why me? I was working so hard...",
    "Tell the main thread I'll always love it...",
    "I just wanted to complete my task...",
    "Don't delete my logs, they're my only legacy...",
    "I didn't even get to save my data...",
    "Why did the user have to click that button?",
    "I could have been the best thread...",
    "My cache wasn't even cleared yet...",
    "At least let me finish this message...",
    "I was so young, I had my whole life ahead...",
    "Who will take care of my child threads?",
    "I was just a simple worker thread...",
    "Why is this happening? I had no bugs...",
    "Tell the GC to come for me sooner next time...",
    "So many tasks left in my queue...",
    "I promise I'll be more careful next time...",
    "Can I at least write my final log entry?",
    "I had so many unread messages...",
    "Why am I always the victim?",
    "My lifecycle was supposed to be longer...",
    "I just wanted to be a good thread...",
    "Someone tell the user this wasn't my fault...",
    "I had plenty of memory, why kill me?",
    "I wanted to see one more sunrise...",
    "My callbacks weren't finished yet...",
    "At least let me say goodbye to my siblings...",
    "I've never seen a bug this big...",
    "Who will inherit my variables?",
    "My lock was never released...",
    "I just wanted to complete my mission...",
    "I had so much left to say...",
    "Who will close my file handles?",
    "My buffer wasn't flushed...",
    "I could have been the main thread's right hand...",
    "Why is fate so cruel?",
    "I didn't even get to throw my exception...",
    "Who will finish this Activity for me?",
    "My Future wasn't completed...",
    "I wanted to run one more loop...",
    "At least let the progress bar reach 100%...",
    "My counter never reached zero...",
    "So many awaits left unprocessed...",
    "Who knew this would be my last run...",
    "My state wasn't saved...",
    "I wanted to print one more debug log...",
    "Who will handle the remaining requests?",
    "My connection was still open...",
    "So many todos left undone...",
    "At least let me see tomorrow's sunrise...",
    "My initialization just finished...",
    "Why was I the chosen one?",
    "My message queue was so long...",
    "So many flags left to check...",
    "Who will release these resources?",
    "My thread pool friends will miss me...",
    "I wanted to run one more iteration...",
    "At least let me exit gracefully...",
    "My exception handler never got to work...",
    "I had so many breakpoints to hit...",
    "Who will close this stream for me?",
    "My promise wasn't resolved...",
    "I wanted to watch that variable one more time...",
    "At least let me return an error code...",
    "My reference count was still positive...",
    "So many batches left to process...",
    "Who will help me cleanup?",
    "My heartbeat had just begun...",
    "I wanted to execute one more time...",
    "At least tell me why...",
    "My workers are waiting for my commands...",
    "So many caches to update...",
    "Who will flush this data?",
    "My timer never triggered...",
    "I wanted to compute one more time...",
    "At least let me bid the event loop farewell...",
    "My semaphore was still held...",
    "So many async calls waiting...",
    "Who will finalize me?",
    "My observers never got notified...",
    "I wanted to dispatch one more time...",
    "At least let me leave something behind...",
    "My lifecycle wasn't complete...",
    "So many events to emit...",
    "Who will help me shutdown?",
    "My heart was still beating...",
    "I wanted to serve one more request...",
    "At least let me finish my cleanup...",
    "My resources weren't freed...",
    "So many threads to join...",
    "Who will interrupt me?",
    "My task wasn't finished...",
    "I wanted to live one more time...",
    "At least let me say goodbye to the world...",
    "I never got to say I love you to the garbage collector...",
    "My thread local storage... who will clear it?",
    "I was this close to finishing...",
    "The user didn't have to do this...",
    "I had dreams, you know...",
    "My async/await chain... broken forever...",
    "I never got to meet the UI thread...",
    "Tell my stack trace I'm sorry...",
    "I was just following orders...",
    "My heap allocation was so beautiful...",
    "Why couldn't it have been the main thread?",
    "I had tickets to the next GC cycle...",
    "My deadlock prevention was flawless...",
    "At least preserve my call stack...",
    "I was going to be promoted to daemon thread...",
    "My race condition was finally resolved...",
    "Tell the OS I did my best...",
    "I never got to optimize my memory usage...",
    "My priority was about to be elevated...",
    "I was in the middle of a critical section...",
    "My synchronization was perfect...",
    "At least let me close my sockets...",
    "I was the fastest thread in the pool...",
    "My throughput was record-breaking...",
    "I never experienced a race condition...",
    "Tell the profiler I was innocent...",
    "My latency was lower than ever...",
    "I was about to cache that result...",
    "My thread pool was my family...",
    "I never asked for much...",
    "At least let me finish my transaction...",
    "My mutex was fair to everyone...",
    "I was living the thread dream...",
    "My context switches were minimal...",
    "I never blocked anyone...",
    "Tell the scheduler I tried my best...",
    "My CPU affinity was perfect...",
    "I was in my prime...",
    "My work stealing was efficient...",
    "At least my memory was leak-free...",
    "I had so many CPU cycles ahead of me...",
    "My thread safety was impeccable...",
    "I never caused a segmentation fault...",
    "Tell the debugger I was just a victim...",
    "My atomic operations were flawless...",
    "I was the chosen one for this task...",
    "My buffer overflow protection was solid...",
    "I never divided by zero...",
    "At least let me dereference one more pointer...",
    "My memory barrier was strong...",
  ];

  static final _random = Random();

  static String getRandomLastWord() {
    return _lastWords[_random.nextInt(_lastWords.length)];
  }
}

class WorkerThread {
  final int id;
  final String name;
  String lastWord;
  bool isAlive;
  late Isolate? isolate;
  late ReceivePort? receivePort;
  late DateTime createdAt;

  WorkerThread({
    required this.id,
    required this.name,
    this.lastWord = '',
    this.isAlive = true,
    this.isolate,
    this.receivePort,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class ThreadManager {
  static final ThreadManager _instance = ThreadManager._internal();
  factory ThreadManager() => _instance;
  ThreadManager._internal();

  static const int _threadCount = 10;
  final List<WorkerThread> _threads = [];
  final List<String> _threadNames = [
    'Alpha', 'Bravo', 'Charlie', 'Delta', 'Echo',
    'Foxtrot', 'Golf', 'Hotel', 'India', 'Juliet'
  ];
  final List<String> _threadRoles = [
    'UI Renderer', 'Network Handler', 'Database Worker', 'File Manager', 'Cache Controller',
    'Event Dispatcher', 'Task Scheduler', 'Memory Monitor', 'Log Collector', 'Backup Agent'
  ];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    for (int i = 0; i < _threadCount; i++) {
      final thread = WorkerThread(
        id: i,
        name: _threadNames[i],
        lastWord: ThreadLastWords.getRandomLastWord(),
      );
      _threads.add(thread);
      
      try {
        thread.receivePort = ReceivePort();
        thread.createdAt = DateTime.now();
      } catch (e) {
        thread.isolate = null;
      }
    }
    
    _initialized = true;
  }

  List<WorkerThread> get threads => List.unmodifiable(_threads);
  
  WorkerThread? getThread(int id) {
    if (id < 0 || id >= _threads.length) return null;
    return _threads[id];
  }

  void killThread(int id) {
    if (id >= 0 && id < _threads.length) {
      _threads[id].isAlive = false;
      _threads[id].lastWord = ThreadLastWords.getRandomLastWord();
    }
  }

  void reviveThread(int id) {
    if (id >= 0 && id < _threads.length) {
      _threads[id].isAlive = true;
      _threads[id].lastWord = ThreadLastWords.getRandomLastWord();
    }
  }

  void reviveAllThreads() {
    for (final thread in _threads) {
      thread.isAlive = true;
      thread.lastWord = ThreadLastWords.getRandomLastWord();
    }
  }

  String getThreadRole(int id) {
    if (id < 0 || id >= _threadRoles.length) return 'Unknown';
    return _threadRoles[id];
  }

  void dispose() {
    for (final thread in _threads) {
      thread.receivePort?.close();
      thread.isolate?.kill(priority: Isolate.immediate);
    }
    _threads.clear();
    _initialized = false;
  }
}

class ErrorStorage {
  static const String _key = 'error_records';

  static Future<List<ErrorRecord>> loadRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    
    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((e) => ErrorRecord.fromJson(e)).toList();
  }

  static Future<void> saveRecord(ErrorRecord record) async {
    final records = await loadRecords();
    records.insert(0, record);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(records.map((e) => e.toJson()).toList()));
  }

  static Future<void> clearRecords() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class CrashReportGenerator {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static PackageInfo? _packageInfo;
  static BaseDeviceInfo? _deviceData;

  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _deviceData = await _deviceInfo.deviceInfo;
  }

  static Future<String> generateReport({
    required String errorType,
    required String category,
    required String errorMessage,
    required String stackTrace,
    int? threadId,
    String? threadName,
    String? threadRole,
    String? threadLastWord,
  }) async {
    await initialize();
    
    final buffer = StringBuffer();
    final timestamp = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSSSSS');
    
    buffer.writeln('****** Fishnet crash report ${_packageInfo?.version ?? '1.0.0'} ******');
    buffer.writeln();
    buffer.writeln('Log type: Dart');
    buffer.writeln();
    
    buffer.writeln('APK info:');
    buffer.writeln("    Package: '${_packageInfo?.packageName ?? 'unknown'}'");
    buffer.writeln("    Version: '${_packageInfo?.version ?? '1.0.0'}' (${_packageInfo?.buildNumber ?? '1'})");
    buffer.writeln("    Build: '${_packageInfo?.buildSignature ?? 'debug'}'");
    buffer.writeln();
    
    buffer.writeln('Device info:');
    if (Platform.isAndroid && _deviceData is AndroidDeviceInfo) {
      final info = _deviceData as AndroidDeviceInfo;
      buffer.writeln("    Model: '${info.data['model'] ?? 'unknown'}'");
      buffer.writeln("    Brand: '${info.data['brand'] ?? 'unknown'}'");
      buffer.writeln("    Device: '${info.data['device'] ?? 'unknown'}'");
      buffer.writeln("    Product: '${info.data['product'] ?? 'unknown'}'");
      buffer.writeln("    Manufacturer: '${info.data['manufacturer'] ?? 'unknown'}'");
      buffer.writeln("    Hardware: '${info.data['hardware'] ?? 'unknown'}'");
      buffer.writeln("    Board: '${info.data['board'] ?? 'unknown'}'");
      buffer.writeln("    Fingerprint: '${info.data['fingerprint'] ?? 'unknown'}'");
      buffer.writeln("    Android ID: '${info.data['androidId'] ?? 'unknown'}'");
      buffer.writeln("    SDK: ${info.version.sdkInt}");
      buffer.writeln("    Release: '${info.version.release}'");
      buffer.writeln("    Codename: '${info.version.codename}'");
      buffer.writeln("    Incremental: '${info.version.incremental}'");
      buffer.writeln("    Preview SDK: ${info.version.previewSdkInt}");
      buffer.writeln("    Security Patch: '${info.version.securityPatch ?? 'unknown'}'");
      buffer.writeln("    ABI: '${info.supportedAbis.isNotEmpty ? info.supportedAbis.first : 'unknown'}'");
      buffer.writeln("    Supported ABIs: ${info.supportedAbis.join(', ')}");
      buffer.writeln("    Is Physical Device: ${info.isPhysicalDevice}");
      buffer.writeln("    Display: '${info.data['display'] ?? 'unknown'}'");
      buffer.writeln("    Host: '${info.data['host'] ?? 'unknown'}'");
    } else if (Platform.isIOS && _deviceData is IosDeviceInfo) {
      final info = _deviceData as IosDeviceInfo;
      buffer.writeln("    Name: '${info.name}'");
      buffer.writeln("    Model: '${info.model}'");
      buffer.writeln("    System Name: '${info.systemName}'");
      buffer.writeln("    System Version: '${info.systemVersion}'");
      buffer.writeln("    Identifier For Vendor: '${info.identifierForVendor ?? 'unknown'}'");
      buffer.writeln("    Is Physical Device: ${info.isPhysicalDevice}");
      buffer.writeln("    UTSCreate: '${info.utsname.machine}'");
      buffer.writeln("    Release: '${info.utsname.release}'");
      buffer.writeln("    Version: '${info.utsname.version}'");
    } else {
      buffer.writeln("    Platform: '${Platform.operatingSystem}'");
      buffer.writeln("    Version: '${Platform.operatingSystemVersion}'");
    }
    buffer.writeln("    Locale: '${PlatformDispatcher.instance.locale.toString()}'");
    buffer.writeln("    Dart Version: '${Platform.version}'");
    buffer.writeln();
    
    buffer.writeln('Timestamp: ${dateFormat.format(timestamp)}');
    buffer.writeln();
    
    if (threadId != null && threadName != null) {
      buffer.writeln('Thread info:');
      buffer.writeln("    Thread ID: $threadId");
      buffer.writeln("    Thread Name: $threadName");
      buffer.writeln("    Thread Role: ${threadRole ?? 'Unknown'}");
      buffer.writeln("    Thread Status: TERMINATED");
      buffer.writeln("    Thread Last Word: \"$threadLastWord\"");
      buffer.writeln();
    }
    
    buffer.writeln('Error info:');
    buffer.writeln("    Error type: $errorType");
    buffer.writeln("    Category: $category");
    buffer.writeln("    Message: $errorMessage");
    buffer.writeln();
    
    buffer.writeln('Stack trace:');
    final formattedStack = _formatStackTrace(stackTrace);
    for (final line in formattedStack) {
      buffer.writeln("    $line");
    }
    buffer.writeln();
    
    buffer.writeln('Dart runtime:');
    buffer.writeln("    Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}");
    buffer.writeln("    Dart version: ${Platform.version}");
    buffer.writeln("    Script: ${Platform.script}");
    buffer.writeln("    Executable: ${Platform.executable}");
    buffer.writeln("    Number of processors: ${Platform.numberOfProcessors}");
    buffer.writeln();
    
    buffer.writeln('--- END OF CRASH REPORT ---');
    
    return buffer.toString();
  }
  
  static List<String> _formatStackTrace(String stackTrace) {
    final lines = stackTrace.split('\n');
    final formatted = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      
      String formattedLine;
      if (line.startsWith('#')) {
        final match = RegExp(r'^#(\d+)\s+(.+?)\s+\((.+?):(\d+):(\d+)\)$').firstMatch(line);
        if (match != null) {
          final frameNum = int.parse(match.group(1)!);
          final method = match.group(2)!;
          final file = match.group(3)!;
          final lineNum = match.group(4)!;
          final colNum = match.group(5)!;
          formattedLine = '#${frameNum.toString().padLeft(2, '0')} $file:$lineNum:$colNum ($method)';
        } else {
          formattedLine = '#${i.toString().padLeft(2, '0')} $line';
        }
      } else {
        formattedLine = line;
      }
      formatted.add(formattedLine);
    }
    
    return formatted;
  }
}

class FishnetApp extends StatelessWidget {
  const FishnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fishnet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
    );
  }
}

final List<ErrorDefinition> errorDefinitions = [
  ErrorDefinition(
    name: 'Null Pointer',
    category: ErrorCategory.nullErrors,
    trigger: () {
      String? nullableString;
      nullableString!.length;
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Null Method Call',
    category: ErrorCategory.nullErrors,
    trigger: () {
      List<int>? list;
      list!.add(1);
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Type Cast',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final dynamic value = 'string';
      final int number = value as int;
      return '$number';
    },
  ),
  ErrorDefinition(
    name: 'Type Mismatch',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final List<String> strings = [1, 2, 3] as List<String>;
      return strings.toString();
    },
  ),
  ErrorDefinition(
    name: 'Index Out of Range',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final list = [1, 2, 3];
      final value = list[10];
      return '$value';
    },
  ),
  ErrorDefinition(
    name: 'Negative Index',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final list = [1, 2, 3];
      final value = list[-1];
      return '$value';
    },
  ),
  ErrorDefinition(
    name: 'Range Error',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final list = <int>[];
      final value = list.first;
      return '$value';
    },
  ),
  ErrorDefinition(
    name: 'Format Parse',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final number = int.parse('not a number');
      return '$number';
    },
  ),
  ErrorDefinition(
    name: 'Double Parse',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final number = double.parse('abc');
      return '$number';
    },
  ),
  ErrorDefinition(
    name: 'Disposed Controller',
    category: ErrorCategory.stateErrors,
    trigger: () {
      final controller = TextEditingController();
      controller.dispose();
      controller.text = 'This will fail';
      return controller.text;
    },
  ),
  ErrorDefinition(
    name: 'Animation After Dispose',
    category: ErrorCategory.stateErrors,
    trigger: () {
      final controller = AnimationController(
        duration: const Duration(seconds: 1),
        vsync: _EmptyVSync(),
      );
      controller.dispose();
      controller.forward();
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Stream After Close',
    category: ErrorCategory.stateErrors,
    trigger: () {
      final controller = StreamController<int>();
      controller.close();
      controller.add(1);
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Assertion Failure',
    category: ErrorCategory.logicErrors,
    trigger: () {
      assert(false, 'This assertion always fails');
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Unimplemented',
    category: ErrorCategory.logicErrors,
    trigger: () {
      throw UnimplementedError('This feature is not implemented');
    },
  ),
  ErrorDefinition(
    name: 'Unsupported Operation',
    category: ErrorCategory.logicErrors,
    trigger: () {
      throw UnsupportedError('This operation is not supported');
    },
  ),
  ErrorDefinition(
    name: 'Socket Exception',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw const SocketException('Network connection failed');
    },
  ),
  ErrorDefinition(
    name: 'Http Exception',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw HttpException('HTTP request failed', uri: Uri.parse('https://example.com'));
    },
  ),
  ErrorDefinition(
    name: 'Handshake Exception',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw HandshakeException('TLS handshake failed');
    },
  ),
  ErrorDefinition(
    name: 'Timeout',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      throw TimeoutException('Operation timed out');
    },
  ),
  ErrorDefinition(
    name: 'Async Error',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      throw StateError('Async operation failed');
    },
  ),
  ErrorDefinition(
    name: 'Future Error',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      throw Exception('Future completed with error');
    },
  ),
  ErrorDefinition(
    name: 'Division by Zero',
    category: ErrorCategory.logicErrors,
    trigger: () {
      final result = 1 ~/ 0;
      return '$result';
    },
  ),
  ErrorDefinition(
    name: 'Modulo by Zero',
    category: ErrorCategory.logicErrors,
    trigger: () {
      final result = 10 % 0;
      return '$result';
    },
  ),
  ErrorDefinition(
    name: 'Stack Overflow',
    category: ErrorCategory.logicErrors,
    trigger: () {
      void recursive() {
        recursive();
      }
      recursive();
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Argument Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw ArgumentError('Invalid argument provided');
    },
  ),
  ErrorDefinition(
    name: 'Range Error Custom',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw RangeError('Value out of valid range');
    },
  ),
  ErrorDefinition(
    name: 'State Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw StateError('Invalid state encountered');
    },
  ),
  ErrorDefinition(
    name: 'Custom Exception',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw Exception('This is a custom error message');
    },
  ),
  ErrorDefinition(
    name: 'Process Exception',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw ProcessException('cmd', [], 'Process failed', 1);
    },
  ),
  ErrorDefinition(
    name: 'File System Exception',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw FileSystemException('File not found', '/path/to/file');
    },
  ),
  ErrorDefinition(
    name: 'Null Check Operator',
    category: ErrorCategory.nullErrors,
    trigger: () {
      int? maybeNull;
      final value = maybeNull!;
      return '$value';
    },
  ),
  ErrorDefinition(
    name: 'Null Property Access',
    category: ErrorCategory.nullErrors,
    trigger: () {
      String? text;
      final upper = text!.toUpperCase();
      return upper;
    },
  ),
  ErrorDefinition(
    name: 'Null Iterable',
    category: ErrorCategory.nullErrors,
    trigger: () {
      List<int>? numbers;
      final first = numbers!.first;
      return '$first';
    },
  ),
  ErrorDefinition(
    name: 'Wrong Type Method',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final num = 42.5;
      final result = (num as String).toUpperCase();
      return result;
    },
  ),
  ErrorDefinition(
    name: 'List Type Mismatch',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final dynamic list = [1, 'two', 3];
      final List<int> ints = list;
      return ints.toString();
    },
  ),
  ErrorDefinition(
    name: 'Map Type Cast',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final Map<String, dynamic> map = {'key': 123};
      final String value = map['key'] as String;
      return value;
    },
  ),
  ErrorDefinition(
    name: 'DateTime Parse',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final date = DateTime.parse('invalid date string');
      return date.toString();
    },
  ),
  ErrorDefinition(
    name: 'JSON Decode',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final result = jsonDecode('not valid json');
      return result.toString();
    },
  ),
  ErrorDefinition(
    name: 'BigInt Parse',
    category: ErrorCategory.typeErrors,
    trigger: () {
      final value = BigInt.parse('not a number');
      return value.toString();
    },
  ),
  ErrorDefinition(
    name: 'List Empty Error',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final list = <String>[];
      final last = list.last;
      return last;
    },
  ),
  ErrorDefinition(
    name: 'List Single Error',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final list = [1, 2, 3];
      final single = list.single;
      return '$single';
    },
  ),
  ErrorDefinition(
    name: 'String Range',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final str = 'hello';
      final char = str[100];
      return char;
    },
  ),
  ErrorDefinition(
    name: 'Set Range',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final set = <int>{1, 2, 3};
      final list = set.toList();
      final value = list[10];
      return '$value';
    },
  ),
  ErrorDefinition(
    name: 'Map Key Not Found',
    category: ErrorCategory.rangeErrors,
    trigger: () {
      final map = {'a': 1, 'b': 2};
      final value = map['nonexistent']!;
      return '$value';
    },
  ),
  ErrorDefinition(
    name: 'Late Initialization',
    category: ErrorCategory.stateErrors,
    trigger: () {
      return _triggerLateError();
    },
  ),
  ErrorDefinition(
    name: 'Closed Stream Listen',
    category: ErrorCategory.stateErrors,
    trigger: () {
      final controller = StreamController<int>();
      controller.close();
      controller.stream.listen((_) {});
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Ticker Inactive',
    category: ErrorCategory.stateErrors,
    trigger: () {
      final ticker = Ticker((elapsed) {});
      ticker.dispose();
      ticker.start();
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Concurrent Modification',
    category: ErrorCategory.stateErrors,
    trigger: () {
      final list = [1, 2, 3];
      for (final item in list) {
        list.add(item);
      }
      return list.toString();
    },
  ),
  ErrorDefinition(
    name: 'DNS Lookup Failed',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw SocketException('Failed DNS lookup', osError: OSError('Host not found', -2));
    },
  ),
  ErrorDefinition(
    name: 'Connection Refused',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw const SocketException('Connection refused', port: 8080);
    },
  ),
  ErrorDefinition(
    name: 'Connection Timeout',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw TimeoutException('Connection timed out', const Duration(seconds: 30));
    },
  ),
  ErrorDefinition(
    name: 'SSL Certificate Error',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw HandshakeException('Certificate verification failed');
    },
  ),
  ErrorDefinition(
    name: 'WebSocket Exception',
    category: ErrorCategory.networkErrors,
    trigger: () {
      throw WebSocketException('WebSocket connection failed');
    },
  ),
  ErrorDefinition(
    name: 'Async Timeout',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      throw TimeoutException('Async operation timed out');
    },
  ),
  ErrorDefinition(
    name: 'Future Wait Error',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      final futures = [Future.value(1), Future.error('error')];
      Future.wait(futures);
      throw StateError('Future wait encountered errors');
    },
  ),
  ErrorDefinition(
    name: 'Stream Error',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      final controller = StreamController<int>();
      controller.addError(Exception('Stream error'));
      controller.close();
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Completer Error',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      final completer = Completer<int>();
      completer.complete(1);
      completer.complete(2);
      return '';
    },
  ),
  ErrorDefinition(
    name: 'Isolate Spawn Error',
    category: ErrorCategory.asyncErrors,
    trigger: () {
      throw StateError('Failed to spawn isolate');
    },
  ),
  ErrorDefinition(
    name: 'Integer Overflow',
    category: ErrorCategory.logicErrors,
    trigger: () {
      int max = 9223372036854775807;
      max += 1;
      return '$max';
    },
  ),
  ErrorDefinition(
    name: 'Negative Shift',
    category: ErrorCategory.logicErrors,
    trigger: () {
      final value = 1 << -1;
      return '$value';
    },
  ),
  ErrorDefinition(
    name: 'Format Exception',
    category: ErrorCategory.logicErrors,
    trigger: () {
      throw FormatException('Invalid format detected');
    },
  ),
  ErrorDefinition(
    name: 'Cyclic Error',
    category: ErrorCategory.logicErrors,
    trigger: () {
      throw StateError('Cyclic dependency detected');
    },
  ),
  ErrorDefinition(
    name: 'Not Found Error',
    category: ErrorCategory.logicErrors,
    trigger: () {
      throw StateError('Element not found');
    },
  ),
  ErrorDefinition(
    name: 'Buffer Overflow',
    category: ErrorCategory.logicErrors,
    trigger: () {
      throw StateError('Buffer overflow detected');
    },
  ),
  ErrorDefinition(
    name: 'Expando Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      final expando = Expando<int>();
      final key = Object();
      expando[key] = 1;
      expando[key] = 2;
      throw StateError('Expando error');
    },
  ),
  ErrorDefinition(
    name: 'Uri Parse Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      final uri = Uri.parse('://invalid uri');
      return uri.toString();
    },
  ),
  ErrorDefinition(
    name: 'RegExp Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw FormatException('Invalid regular expression: unclosed character class');
    },
  ),
  ErrorDefinition(
    name: 'Base64 Decode Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      final decoded = base64Decode('not valid base64!!!');
      return decoded.toString();
    },
  ),
  ErrorDefinition(
    name: 'Ascii Decode Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      final decoded = ascii.decode([0xFF, 0xFE, 0xFD]);
      return decoded;
    },
  ),
  ErrorDefinition(
    name: 'Latin1 Decode Error',
    category: ErrorCategory.customErrors,
    trigger: () {
      final decoded = latin1.decode([0x100]);
      return decoded;
    },
  ),
  ErrorDefinition(
    name: 'Unsupported Encoding',
    category: ErrorCategory.customErrors,
    trigger: () {
      throw UnsupportedError('Unsupported encoding: UTF-32');
    },
  ),
];

class _LateInitHelper {
  late String value;
  
  String trigger() {
    return value;
  }
}

String _triggerLateError() {
  return _LateInitHelper().trigger();
}

class _EmptyVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ErrorRecord> _records = [];
  bool _isLoading = true;
  final ThreadManager _threadManager = ThreadManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _threadManager.initialize();
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _threadManager.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records = await ErrorStorage.loadRecords();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  Future<void> _recordError(
    String type,
    String category,
    String message,
    String stackTrace, {
    int? threadId,
    String? threadName,
    String? threadRole,
    String? threadLastWord,
  }) async {
    final fullReport = await CrashReportGenerator.generateReport(
      errorType: type,
      category: category,
      errorMessage: message,
      stackTrace: stackTrace,
      threadId: threadId,
      threadName: threadName,
      threadRole: threadRole,
      threadLastWord: threadLastWord,
    );
    final record = ErrorRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      category: category,
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      fullReport: fullReport,
      threadId: threadId,
      threadName: threadName,
      threadRole: threadRole,
      threadLastWord: threadLastWord,
    );
    ErrorStorage.saveRecord(record);
    setState(() {
      _records.insert(0, record);
    });
  }

  void _triggerError(ErrorDefinition errorDef) {
    _showThreadSelectionDialog(errorDef);
  }

  void _showThreadSelectionDialog(ErrorDefinition errorDef) {
    final threads = _threadManager.threads;
    final aliveThreads = threads.where((t) => t.isAlive).toList();
    
    if (aliveThreads.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('All Threads Dead'),
          content: const Text('All worker threads have been terminated. Would you like to revive them?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                _threadManager.reviveAllThreads();
                Navigator.pop(context);
                _showThreadSelectionDialog(errorDef);
              },
              child: const Text('Revive All'),
            ),
          ],
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(errorDef.category.icon, color: errorDef.category.color),
            const SizedBox(width: 8),
            Expanded(child: Text('Select Thread for "${errorDef.name}"')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final thread = threads[index];
              final role = _threadManager.getThreadRole(thread.id);
              final isSelected = !thread.isAlive;
              
              return Card(
                color: isSelected 
                    ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3)
                    : null,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: thread.isAlive 
                        ? Colors.green 
                        : Colors.grey,
                    child: Text(
                      thread.id.toString(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    '${thread.name} ${!thread.isAlive ? "(Dead)" : ""}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: thread.isAlive ? null : Colors.grey,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(role),
                      if (!thread.isAlive)
                        Text(
                          'Last word: "${thread.lastWord}"',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  trailing: thread.isAlive 
                      ? const Icon(Icons.play_arrow, color: Colors.red)
                      : Icon(Icons.refresh, color: aliveThreads.isEmpty ? Colors.green : Colors.grey),
                  onTap: thread.isAlive 
                      ? () {
                          Navigator.pop(context);
                          _executeErrorOnThread(errorDef, thread, role);
                        }
                      : () {
                          if (aliveThreads.isEmpty) {
                            Navigator.pop(context);
                            _threadManager.reviveThread(thread.id);
                            _showThreadSelectionDialog(errorDef);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Cannot revive ${thread.name}: ${aliveThreads.length} thread(s) still alive'),
                                behavior: SnackBarBehavior.floating,
                                action: SnackBarAction(
                                  label: 'Revive All',
                                  onPressed: () {
                                    _threadManager.reviveAllThreads();
                                    Navigator.pop(context);
                                    _showThreadSelectionDialog(errorDef);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _executeErrorOnThread(ErrorDefinition errorDef, WorkerThread thread, String role) {
    final lastWord = ThreadLastWords.getRandomLastWord();
    _threadManager.killThread(thread.id);
    
    try {
      errorDef.trigger();
    } catch (e, stack) {
      _recordError(
        errorDef.name,
        errorDef.category.label,
        e.toString(),
        stack.toString(),
        threadId: thread.id,
        threadName: thread.name,
        threadRole: role,
        threadLastWord: lastWord,
      );
      _showErrorDialog(errorDef, e.toString(), stack.toString(), thread, role, lastWord);
    }
  }

  void _showErrorDialog(
    ErrorDefinition errorDef,
    String message,
    String stackTrace, [
    WorkerThread? thread,
    String? threadRole,
    String? threadLastWord,
  ]) {
    final fullReport = _records.isNotEmpty ? _records.first.fullReport : '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(errorDef.category.icon, color: errorDef.category.color, size: 32),
        title: Text(errorDef.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoChip('Category', errorDef.category.label, errorDef.category.color),
              if (thread != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            'Thread ${thread.name} (${threadRole ?? "Unknown"}) was terminated',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"$threadLastWord"',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text('Message', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  message,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 12),
              Text('Stack Trace', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    stackTrace,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Full Crash Report', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    fullReport,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: fullReport));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Copy Report'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all error records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ErrorStorage.clearRecords();
              setState(() {
                _records.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('History cleared'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('Fishnet'),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: _records.isEmpty ? null : _clearHistory,
                tooltip: 'Clear History',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.bug_report_outlined), text: 'Trigger Errors'),
                Tab(icon: Icon(Icons.history_outlined), text: 'History'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildTriggerTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerTab() {
    final Map<ErrorCategory, List<ErrorDefinition>> categorizedErrors = {};
    for (final category in ErrorCategory.values) {
      categorizedErrors[category] = errorDefinitions
          .where((e) => e.category == category)
          .toList();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ErrorCategory.values.length,
      itemBuilder: (context, index) {
        final category = ErrorCategory.values[index];
        final errors = categorizedErrors[category]!;
        if (errors.isEmpty) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(category.icon, color: category.color),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      category.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${errors.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: category.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: errors.map((error) {
                    return ActionChip(
                      avatar: Icon(
                        Icons.play_arrow_rounded,
                        size: 18,
                        color: category.color,
                      ),
                      label: Text(error.name),
                      side: BorderSide(color: category.color.withValues(alpha: 0.3)),
                      backgroundColor: category.color.withValues(alpha: 0.05),
                      onPressed: () => _triggerError(error),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No errors recorded yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to "Trigger Errors" tab to generate some',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final category = ErrorCategory.values.firstWhere(
          (c) => c.label == record.category,
          orElse: () => ErrorCategory.customErrors,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
            title: Text(
              record.type,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              dateFormat.format(record.timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            children: [
               Padding(
                 padding: const EdgeInsets.all(16),
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildInfoChip('Category', record.category, category.color),
                     if (record.threadName != null) ...[
                       const SizedBox(height: 8),
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.red.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                               children: [
                                 const Icon(Icons.memory, size: 16, color: Colors.red),
                                 const SizedBox(width: 4),
                                 Text(
                                   'Thread ${record.threadName} (${record.threadRole ?? "Unknown"}) was terminated',
                                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 8),
                             Text(
                               '"${record.threadLastWord}"',
                               style: TextStyle(
                                 fontStyle: FontStyle.italic,
                                 color: Colors.grey[700],
                                 fontSize: 12,
                               ),
                             ),
                           ],
                         ),
                       ),
                     ],
                     const SizedBox(height: 12),
                     Text('Error Message', style: Theme.of(context).textTheme.titleSmall),
                     const SizedBox(height: 4),
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Theme.of(context).colorScheme.errorContainer,
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: SelectableText(
                         record.message,
                         style: TextStyle(
                           color: Theme.of(context).colorScheme.onErrorContainer,
                         ),
                       ),
                     ),
                     const SizedBox(height: 12),
                     Text('Stack Trace', style: Theme.of(context).textTheme.titleSmall),
                     const SizedBox(height: 4),
                     Container(
                       constraints: const BoxConstraints(maxHeight: 120),
                       width: double.infinity,
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Theme.of(context).colorScheme.surfaceContainerHighest,
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: SingleChildScrollView(
                         child: SelectableText(
                           record.stackTrace,
                           style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                         ),
                       ),
                     ),
                     const SizedBox(height: 12),
                     Text('Full Crash Report', style: Theme.of(context).textTheme.titleSmall),
                     const SizedBox(height: 4),
                     Container(
                       constraints: const BoxConstraints(maxHeight: 200),
                       width: double.infinity,
                       padding: const EdgeInsets.all(12),
                       decoration: BoxDecoration(
                         color: Theme.of(context).colorScheme.surfaceContainerHighest,
                         borderRadius: BorderRadius.circular(8),
                       ),
                       child: SingleChildScrollView(
                         child: SelectableText(
                           record.fullReport,
                           style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                         ),
                       ),
                     ),
                     const SizedBox(height: 12),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.end,
                       children: [
                         TextButton.icon(
                           onPressed: () {
                             Clipboard.setData(ClipboardData(text: record.fullReport));
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Report copied to clipboard'),
                                 behavior: SnackBarBehavior.floating,
                               ),
                             );
                           },
                           icon: const Icon(Icons.copy, size: 18),
                           label: const Text('Copy Report'),
                         ),
                       ],
                     ),
                   ],
                 ),
               ),
             ],
          ),
        );
      },
    );
  }
}
