import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  ErrorRecord({
    required this.id,
    required this.type,
    required this.category,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
  });

  factory ErrorRecord.fromJson(Map<String, dynamic> json) {
    return ErrorRecord(
      id: json['id'],
      type: json['type'],
      category: json['category'] ?? 'Unknown',
      message: json['message'],
      stackTrace: json['stackTrace'],
      timestamp: DateTime.parse(json['timestamp']),
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
    };
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
];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    final records = await ErrorStorage.loadRecords();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  void _recordError(String type, String category, String message, String stackTrace) {
    final record = ErrorRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      category: category,
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
    ErrorStorage.saveRecord(record);
    setState(() {
      _records.insert(0, record);
    });
  }

  void _triggerError(ErrorDefinition errorDef) {
    try {
      errorDef.trigger();
    } catch (e, stack) {
      _recordError(errorDef.name, errorDef.category.label, e.toString(), stack.toString());
      _showErrorDialog(errorDef, e.toString(), stack.toString());
    }
  }

  void _showErrorDialog(ErrorDefinition errorDef, String message, String stackTrace) {
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
                constraints: const BoxConstraints(maxHeight: 200),
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
            ],
          ),
        ),
        actions: [
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
                      constraints: const BoxConstraints(maxHeight: 200),
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
