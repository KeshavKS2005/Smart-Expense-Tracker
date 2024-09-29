import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
class OCRservice {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  Future<Map<String, dynamic>> scanReceipt(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    String text = recognizedText.text;
    List<String> lines = text.split('\n');
    String merchant = _extractMerchant(lines);
    DateTime? detectedDate = _extractDate(text);
    double? totalAmount = _extractTotal(text, lines);
    return {
      'merchant': merchant,
      'merchantConfidence': merchant != 'Unknown Merchant' ? 'high' : 'low',
      'date': detectedDate ?? DateTime.now(),
      'dateConfidence': detectedDate != null ? 'high' : 'low',
      'total': totalAmount ?? 0.0,
      'totalConfidence': totalAmount != null ? 'high' : 'low',
      'rawText': text,
    };
  }
  String _extractMerchant(List<String> lines) {
    final junkPattern = RegExp(r'^[\d\s\-/\.\,\#\*\=\+]+$');
    final datePattern = RegExp(r'\d{1,4}[-/]\d{1,2}[-/]\d{1,4}');
    final phonePattern = RegExp(r'\d{10,}');
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length < 3) continue; 
      if (junkPattern.hasMatch(trimmed)) continue; 
      if (datePattern.hasMatch(trimmed)) continue; 
      if (phonePattern.hasMatch(trimmed)) continue; 
      return trimmed;
    }
    return 'Unknown Merchant';
  }
  DateTime? _extractDate(String text) {
    final dateRegExp = RegExp(r'\b(\d{1,4})[-/](\d{1,2})[-/](\d{1,4})\b');
    final matches = dateRegExp.allMatches(text);
    for (var match in matches) {
      String dateStr = match.group(0)!.replaceAll('-', '/');
      List<String> parts = dateStr.split('/');
      List<int> nums = parts.map((p) => int.tryParse(p) ?? 0).toList();
      if (nums.every((n) => n > 31)) continue;
      List<String> formats = ['d/M/yyyy', 'M/d/yyyy', 'yyyy/M/d'];
      for (String format in formats) {
        try {
          DateTime parsed = DateFormat(format).parseStrict(dateStr);
          if (parsed.isAfter(DateTime.now().add(const Duration(days: 1)))) {
            continue;
          }
          if (parsed.isBefore(DateTime(2000))) continue;
          return parsed;
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }
  double? _extractTotal(String text, List<String> lines) {
    final totalKeywords = RegExp(
        r'(total|grand\s*total|amount\s*due|net\s*amount|balance\s*due|payable)',
        caseSensitive: false);
    final amountRegExp = RegExp(r'[\d,]+\.?\d{0,2}');
    for (String line in lines) {
      if (totalKeywords.hasMatch(line)) {
        final amountMatches = amountRegExp.allMatches(line);
        for (var m in amountMatches) {
          double? val = _parseAmount(m.group(0)!);
          if (val != null && val > 0 && val < 1000000) return val;
        }
      }
    }
    final allAmounts = RegExp(r'\b[\d,]+\.\d{2}\b');
    final matches = allAmounts.allMatches(text);
    List<double> foundAmounts = [];
    for (var match in matches) {
      double? val = _parseAmount(match.group(0)!);
      if (val == null) continue;
      String raw = match.group(0)!.replaceAll(',', '').replaceAll('.', '');
      if (raw.length > 8) continue; 
      if (val > 500000) continue; 
      if (val < 1) continue; 
      foundAmounts.add(val);
    }
    if (foundAmounts.isEmpty) return null;
    return foundAmounts.reduce((a, b) => a > b ? a : b);
  }
  double? _parseAmount(String raw) {
    String cleaned = raw.replaceAll(',', '');
    return double.tryParse(cleaned);
  }
  void dispose() {
    _textRecognizer.close();
  }
}
