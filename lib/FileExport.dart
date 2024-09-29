import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_expense_tracker/DatabaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
class FileExport extends StatefulWidget {
  const FileExport({super.key});
  @override
  State<FileExport> createState() => _FileExportState();
}
class _FileExportState extends State<FileExport> {
  bool _isLoading = false;
  Future<void> exportData() async {
    setState(() {
      _isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    if (id == null) {
      if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Login again")));
          setState(() {
            _isLoading = false;
          });
      }
      return;
    }
    print("Id is $id");
    try {
      final db = DatabaseHelper.instance;
      var data = await db.getTransactions(id);
      List<List<dynamic>> rows = [];
      rows.add([
        'id',
        'amount',
        'type',
        'category',
        'date',
        'description',
      ]);
      for (var element in data) {
        rows.add([
          element['id'],
          element['amount'],
          element['type'],
          element['category'],
          element['date'],
          element['description'] ?? '',
        ]);
      }
      String csv = const ListToCsvConverter().convert(rows);
      final directory = await getApplicationDocumentsDirectory();
      final File file = File('${directory.path}/transactions.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Exported Transactions',
      );
    } catch (e) {
      print(e);
      if(mounted){
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Export failed")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
         backgroundColor: Colors.redAccent,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: exportData,
                icon: const Icon(Icons.download),
                label: const Text("Export CSV"),
                style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
              ),
      ),
    );
  }
}
