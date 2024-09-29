import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_expense_tracker/DatabaseHelper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_expense_tracker/OCRservice.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
class Addtransactions extends StatefulWidget {
  const Addtransactions({super.key});
  @override
  State<Addtransactions> createState() => _AddTransactions();
}
class _AddTransactions extends State<Addtransactions> {
  final OCRservice _ocrService = OCRservice();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String transactionType = 'Expense';
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }
  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            String text = val.recognizedWords;
            if (val.finalResult) {
                setState(() => _isListening = false);
                _showVoiceConfirmation(text);
            }
          },
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Speech recognition not available")));
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }
   int? _extractAmountFromText(String text) {
     final digitMatches = RegExp(r'\d+').allMatches(text);
    if (digitMatches.isNotEmpty) {
      List<int> numbers = digitMatches.map((m) => int.parse(m.group(0)!)).toList();
      numbers.sort();
      return numbers.last;
    }
     String lower = text.toLowerCase();
    final wordNumbers = {
      'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5,
      'six': 6, 'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10,
      'eleven': 11, 'twelve': 12, 'thirteen': 13, 'fourteen': 14,
      'fifteen': 15, 'sixteen': 16, 'seventeen': 17, 'eighteen': 18,
      'nineteen': 19, 'twenty': 20, 'thirty': 30, 'forty': 40,
      'fifty': 50, 'sixty': 60, 'seventy': 70, 'eighty': 80, 'ninety': 90,
    };
    final multipliers = {'hundred': 100, 'thousand': 1000, 'lakh': 100000};
    int total = 0;
    int current = 0;
    for (String word in lower.split(RegExp(r'\s+'))) {
      if (wordNumbers.containsKey(word)) {
        current += wordNumbers[word]!;
      } else if (multipliers.containsKey(word)) {
        if (current == 0) current = 1;
        current *= multipliers[word]!;
        if (word == 'thousand' || word == 'lakh') {
          total += current;
          current = 0;
        }
      }
    }
    total += current;
    return total > 0 ? total : null;
  }
  String _detectCategory(String text) {
    String lowerText = text.toLowerCase();
    Map<String, List<String>> keywords = {
      'Food': ['food', 'burger', 'pizza', 'lunch', 'dinner', 'breakfast',
               'coffee', 'cafe', 'restaurant', 'groceries', 'snack', 'tea',
               'biryani', 'shawarma', 'meal', 'eat', 'ate', 'dine'],
      'Entertainment': ['movie', 'cinema', 'game', 'netflix', 'fun', 'party',
                        'concert', 'show', 'spotify', 'music', 'youtube'],
      'Emergency': ['hospital', 'doctor', 'medicine', 'medical', 'emergency',
                    'pharmacy', 'health', 'accident'],
      'Education': ['book', 'course', 'tuition', 'school', 'college',
                    'university', 'class', 'exam', 'study', 'udemy'],
      'Side hustle': ['freelance', 'gig', 'side hustle', 'client', 'project'],
      'Salary': ['salary', 'income', 'wage', 'pay', 'stipend'],
      'Business': ['business', 'investment', 'stock', 'trading'],
    };
    for (var entry in keywords.entries) {
      for (var keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          return categories.contains(entry.key) ? entry.key : 'others';
        }
      }
    }
    return 'others';
  }
  void _showVoiceConfirmation(String rawText) {
    int? amount = _extractAmountFromText(rawText);
    String category = _detectCategory(rawText);
    final confirmAmountCtrl = TextEditingController(text: amount?.toString() ?? '');
    final confirmDescCtrl = TextEditingController(text: rawText);
    String confirmCategory = category;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.green),
                      const SizedBox(width: 10),
                      const Text("Voice Input — Confirm",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text("\"$rawText\"",
                      style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                  const Divider(height: 25),
                  TextField(
                    controller: confirmAmountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount",
                      prefixIcon: const Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: amount == null,
                      fillColor: amount == null ? Colors.orange.shade50 : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: confirmCategory,
                    decoration: InputDecoration(
                      labelText: "Category",
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) => setSheetState(() => confirmCategory = val ?? 'others'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmDescCtrl,
                    decoration: InputDecoration(
                      labelText: "Description",
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _amountController.text = confirmAmountCtrl.text;
                          selectedValue = confirmCategory;
                          descriptionController.text = confirmDescCtrl.text;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text("CONFIRM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Future<void> _scanReceipt() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _ocrService.scanReceipt(File(image.path));
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showOCRConfirmation(data);
    } catch (e) {
      print("OCR Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to scan receipt")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  void _showOCRConfirmation(Map<String, dynamic> data) {
    final confirmAmountCtrl = TextEditingController(
        text: data['total'] != null && data['total'] != 0.0
            ? data['total'].toString()
            : '');
    final confirmMerchantCtrl = TextEditingController(text: data['merchant'] ?? '');
    final confirmDateCtrl = TextEditingController(
        text: DateFormat('yyyy-MM-dd').format(data['date']));
    bool amountLow = data['totalConfidence'] == 'low';
    bool dateLow = data['dateConfidence'] == 'low';
    bool merchantLow = data['merchantConfidence'] == 'low';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.document_scanner, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  const Text("Receipt Scanned — Verify",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (amountLow || dateLow || merchantLow) ...[
                const SizedBox(height: 5),
                Text("⚠ Orange fields had low detection confidence — please verify.",
                    style: TextStyle(color: Colors.orange[700], fontSize: 12)),
              ],
              const Divider(height: 25),
              TextField(
                controller: confirmAmountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Amount",
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: amountLow,
                  fillColor: amountLow ? Colors.orange.shade50 : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmMerchantCtrl,
                decoration: InputDecoration(
                  labelText: "Merchant / Description",
                  prefixIcon: const Icon(Icons.store),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: merchantLow,
                  fillColor: merchantLow ? Colors.orange.shade50 : null,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmDateCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Date",
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: dateLow,
                  fillColor: dateLow ? Colors.orange.shade50 : null,
                ),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: ctx,
                    initialDate: data['date'],
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    confirmDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    setState(() {
                      _amountController.text = confirmAmountCtrl.text;
                      dateController.text = confirmDateCtrl.text;
                      descriptionController.text = confirmMerchantCtrl.text;
                      transactionType = 'Expense';
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("CONFIRM", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  bool _isLoading = false;
  final _amountController = TextEditingController();
  final dateController = TextEditingController();
  final descriptionController = TextEditingController();
  final List<String> categories = [
    'Food',
    'Entertainment',
    'Emergency',
    'Education',
    'Side hustle',
    'Salary',
    'Business',
    'assets',
    'others'
  ];
  String selectedValue = 'others';
  @override
  void dispose() {
    _amountController.dispose();
    dateController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
  Future<void> selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }
  Future<void> add() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login again')),
      );
      return;
    }
    final income = _amountController.text.trim();
    final intamount = int.tryParse(income);
    if (intamount == null || intamount <= 0 || dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid input')),
      );
      return; 
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final db = DatabaseHelper.instance;
      await db.insertTransaction({
        'date': dateController.text,
        'amount': intamount,
        'type': transactionType,
        'category': selectedValue,
        'description': descriptionController.text,
        'userid': id
      });
      _amountController.clear();
      descriptionController.clear();
      setState(() {
        selectedValue = 'others';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added')),
      );
    } catch (err) {
      print(err);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding transaction')),
      );
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
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : Colors.green,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFD32F2F), 
              Color.fromARGB(255, 236, 65, 49),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.receipt_long,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  "ADD TRANSACTION",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _scanReceipt,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Scan Receipt"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Column(
                      children: [
                        const Text(
                          "New Entry",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'Income',
                                label: Text('Income'),
                                icon: Icon(Icons.arrow_downward)),
                            ButtonSegment(
                                value: 'Expense',
                                label: Text('Expense'),
                                icon: Icon(Icons.arrow_upward)),
                          ],
                          selected: {transactionType},
                          onSelectionChanged: (newSelection) {
                            setState(() {
                              transactionType = newSelection.first;
                            });
                          },
                          style: ButtonStyle(
                            side: MaterialStateProperty.all(
                                BorderSide(color: Colors.red.shade200)),
                          ),
                        ),
                        const SizedBox(height: 25),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Amount",
                            prefixIcon: const Icon(Icons.currency_rupee),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedValue,
                          decoration: InputDecoration(
                            labelText: "Category",
                            prefixIcon: const Icon(Icons.category_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          items: categories.map((String category) {
                            return DropdownMenuItem(
                                value: category, child: Text(category));
                          }).toList(),
                          onChanged: (String? newvalue) {
                            setState(() {
                              selectedValue = newvalue ?? 'others';
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Select Date',
                            prefixIcon: const Icon(Icons.calendar_today),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onTap: selectDate,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 3,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: 'Enter details...',
                            labelText: 'Description',
                            alignLabelWithHint: true,
                            prefixIcon: const Icon(Icons.description_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : add,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'ADD TRANSACTION',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
