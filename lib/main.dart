import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const FishnetApp());
}

class FishnetApp extends StatelessWidget {
  const FishnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fishnet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class ErrorRecord {
  final String id;
  final String type;
  final String message;
  final String stackTrace;
  final DateTime timestamp;

  ErrorRecord({
    required this.id,
    required this.type,
    required this.message,
    required this.stackTrace,
    required this.timestamp,
  });

  factory ErrorRecord.fromJson(Map<String, dynamic> json) {
    return ErrorRecord(
      id: json['id'],
      type: json['type'],
      message: json['message'],
      stackTrace: json['stackTrace'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ErrorRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await ErrorStorage.loadRecords();
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  void _recordError(String type, String message, String stackTrace) {
    final record = ErrorRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      message: message,
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
    );
    ErrorStorage.saveRecord(record);
    setState(() {
      _records.insert(0, record);
    });
  }

  void _showErrorDialog(String title, String message, String stackTrace) {
    _recordError(title, message, stackTrace);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Message:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              Text('Stack Trace:', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(stackTrace, style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _triggerNullError() {
    try {
      String? nullableString;
      nullableString!.length;
    } catch (e, stack) {
      _showErrorDialog('Null Error', e.toString(), stack.toString());
    }
  }

  void _triggerRangeError() {
    try {
      final list = [1, 2, 3];
      final value = list[10];
      debugPrint('$value');
    } catch (e, stack) {
      _showErrorDialog('Range Error', e.toString(), stack.toString());
    }
  }

  void _triggerTypeError() {
    try {
      final dynamic value = 'string';
      final int number = value as int;
      debugPrint('$number');
    } catch (e, stack) {
      _showErrorDialog('Type Error', e.toString(), stack.toString());
    }
  }

  void _triggerFormatException() {
    try {
      final number = int.parse('not a number');
      debugPrint('$number');
    } catch (e, stack) {
      _showErrorDialog('Format Error', e.toString(), stack.toString());
    }
  }

  void _triggerStateError() {
    try {
      final controller = TextEditingController();
      controller.dispose();
      controller.text = 'This will fail';
    } catch (e, stack) {
      _showErrorDialog('State Error', e.toString(), stack.toString());
    }
  }

  void _triggerAssertionError() {
    try {
      assert(false, 'This assertion always fails');
    } catch (e, stack) {
      _showErrorDialog('Assertion Error', e.toString(), stack.toString());
    }
  }

  void _triggerUnsupportedError() {
    try {
      final list = [1, 2, 3];
      list.removeWhere((element) => false);
      throw UnsupportedError('This operation is not supported');
    } catch (e, stack) {
      _showErrorDialog('Unsupported Error', e.toString(), stack.toString());
    }
  }

  void _triggerTimeoutError() {
    try {
      throw TimeoutException('Operation timed out');
    } catch (e, stack) {
      _showErrorDialog('Timeout Error', e.toString(), stack.toString());
    }
  }

  void _triggerIOException() {
    try {
      throw const SocketException('Network connection failed');
    } catch (e, stack) {
      _showErrorDialog('IO Error', e.toString(), stack.toString());
    }
  }

  void _triggerCustomError() {
    try {
      throw Exception('This is a custom error message');
    } catch (e, stack) {
      _showErrorDialog('Custom Exception', e.toString(), stack.toString());
    }
  }

  void _triggerDivisionByZero() {
    try {
      final result = 1 ~/ 0;
      debugPrint('$result');
    } catch (e, stack) {
      _showErrorDialog('Integer Division By Zero', e.toString(), stack.toString());
    }
  }

  void _triggerStackOverflow() {
    try {
      void recursive() {
        recursive();
      }
      recursive();
    } catch (e, stack) {
      _showErrorDialog('Stack Overflow', e.toString(), stack.toString());
    }
  }

  void _clearHistory() {
    ErrorStorage.clearRecords();
    setState(() {
      _records.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History cleared')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fishnet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _records.isEmpty ? null : _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Trigger Errors',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildErrorButton('Null Error', _triggerNullError, Colors.red),
                        _buildErrorButton('Range Error', _triggerRangeError, Colors.orange),
                        _buildErrorButton('Type Error', _triggerTypeError, Colors.purple),
                        _buildErrorButton('Format Error', _triggerFormatException, Colors.blue),
                        _buildErrorButton('State Error', _triggerStateError, Colors.teal),
                        _buildErrorButton('Assertion', _triggerAssertionError, Colors.indigo),
                        _buildErrorButton('Unsupported', _triggerUnsupportedError, Colors.brown),
                        _buildErrorButton('Timeout', _triggerTimeoutError, Colors.cyan),
                        _buildErrorButton('IO Error', _triggerIOException, Colors.green),
                        _buildErrorButton('Custom', _triggerCustomError, Colors.pink),
                        _buildErrorButton('Div by Zero', _triggerDivisionByZero, Colors.amber),
                        _buildErrorButton('Stack Overflow', _triggerStackOverflow, Colors.grey),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Error History (${_records.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                  if (_records.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No errors recorded yet.\nTrigger some errors above!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return _buildErrorRecordTile(record);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildErrorButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }

  Widget _buildErrorRecordTile(ErrorRecord record) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return ExpansionTile(
      title: Text(
        record.type,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${dateFormat.format(record.timestamp)}\n${record.message.split('\n').first}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Error Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                record.message,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(
                record.stackTrace,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
