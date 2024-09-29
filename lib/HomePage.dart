import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_expense_tracker/DatabaseHelper.dart';
import 'package:smart_expense_tracker/ShimmerLoading.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePage();
}
class _HomePage extends State<HomePage> {
  String resultSelection = 'all';
  DateTime selectedDate = DateTime.now();
  final amountController = TextEditingController(text: "0");
  final incomeController = TextEditingController(text: "0");
  final expenseController = TextEditingController(text: "0");
  bool _isLoading = true;
  int dailyBudget = 500;
  Map<String, dynamic> streakData = {'streak': 0, 'todaySpent': 0, 'broken': false};
  final List<Color> categoryColors = [
    Colors.red,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.brown,
    Colors.green,
    Colors.black87
  ];
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
  List<dynamic> transactions = [];
  void showPicker() {
    showMonthPicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime.now())
        .then((DateTime? date) {
      if (date != null) {
        setState(() {
          selectedDate = date;
        });
        fetchData();
      }
    });
  }
  Future<void> fetchData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    dailyBudget = prefs.getInt('daily_budget') ?? 500;
    if (id == null) return;
    try {
      final db = DatabaseHelper.instance;
      List<Map<String, dynamic>> data;
      if (resultSelection == 'select month') {
        String firstDay = DateFormat('yyyy-MM-01').format(selectedDate);
        String lastDay = DateFormat('yyyy-MM-dd')
            .format(DateTime(selectedDate.year, selectedDate.month + 1, 0));
        data = await db.getTransactions(id, monthStart: firstDay, monthEnd: lastDay);
      } else {
        data = await db.getTransactions(id);
      }
      final streakInfo = await db.getStreakData(id, dailyBudget);
      setState(() {
        transactions = data;
        streakData = streakInfo;
      });
    } catch (err) {
      print(err);
    } finally {
      setState(() => _isLoading = false);
    }
  }
  Future<void> fetchAmount() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    if (id == null) return;
    try {
      final summary = await DatabaseHelper.instance.getIncomeExpenseSummary(id);
      setState(() {
        amountController.text = summary['balance'].toString();
      });
    } catch (err) {
      print(err);
    }
  }
  Future<void> fetchIncomeExpense() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    if (id == null) return;
    final summary = await DatabaseHelper.instance.getIncomeExpenseSummary(id);
    setState(() {
      incomeController.text = summary['income'].toString();
      expenseController.text = summary['expense'].toString();
    });
  }
  Future<void> deleteTransaction(dynamic item, int index) async {
    try {
      await DatabaseHelper.instance.deleteTransaction(item['id'] as int);
      fetchData();
      fetchAmount();
      fetchIncomeExpense();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Transaction deleted')));
      }
    } catch (err) {
      print(err);
    }
  }
  Map<String, double> getExpenseCategoryData() {
    Map<String, double> data = {};
    for (var item in transactions) {
      if (item['type'] == 'Expense') {
        String category = item['category'] ?? 'Other';
        double amount = (item['amount'] as num).toDouble();
        if (data.containsKey(category)) {
          data[category] = data[category]! + amount;
        } else {
          data[category] = amount;
        }
      }
    }
    return data;
  }
  @override
  void initState() {
    super.initState();
    fetchAmount();
    fetchIncomeExpense();
    fetchData();
  }
  @override
  Widget build(BuildContext context) {
    Map<String, double> categoryData = getExpenseCategoryData();
    List<PieChartSectionData> pieSections = [];
    categoryData.forEach((key, value) {
      int index = categories.indexOf(key);
      if (index == -1) index = categoryColors.length - 1;
      pieSections.add(PieChartSectionData(
        color: categoryColors[index % categoryColors.length],
        value: value,
        title: '${((value / (double.tryParse(expenseController.text) == 0 ? 1 : (double.tryParse(expenseController.text) ?? 1))) * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      ));
    });
    return Scaffold(
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
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              fetchData();
              fetchAmount();
              fetchIncomeExpense();
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome Back,",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "DASHBOARD",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          onPressed: () {
                            fetchData();
                            fetchAmount();
                            fetchIncomeExpense();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  if (!_isLoading && streakData['streak'] > 0)
                    Card(
                      elevation: 4,
                      color: streakData['broken'] ? Colors.orange.shade50 : Colors.green.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: Icon(
                          streakData['broken'] ? Icons.local_fire_department_outlined : Icons.local_fire_department,
                          color: streakData['broken'] ? Colors.orange : Colors.green,
                          size: 30,
                        ),
                        title: Text(
                          streakData['broken'] 
                            ? "Streak broken!" 
                            : "${streakData['streak']} Day Streak! 🔥",
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: streakData['broken'] ? Colors.orange[800] : Colors.green[800],
                          ),
                        ),
                        subtitle: Text(
                          streakData['broken']
                            ? "You spent ₹${streakData['todaySpent']} today (Budget: ₹$dailyBudget)"
                            : "You're under your ₹$dailyBudget daily budget.",
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ),
                    ),
                  if (!_isLoading && streakData['streak'] > 0)
                    const SizedBox(height: 15),
                  _isLoading 
                    ? const ShimmerCard() 
                    : Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const Text("Total Balance",
                                  style: TextStyle(color: Colors.grey, fontSize: 16)),
                              const SizedBox(height: 10),
                              Text(
                                amountController.text,
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: (int.tryParse(amountController.text) ?? 0) >= 0
                                      ? Colors.black87
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_upward,
                                              color: Colors.green, size: 20),
                                          SizedBox(width: 5),
                                          Text("INCOME",
                                              style: TextStyle(
                                                  color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        incomeController.text,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green),
                                      ),
                                    ],
                                  ),
                                  Container(
                                      height: 40, width: 1, color: Colors.grey[300]),
                                  Column(
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.arrow_downward,
                                              color: Colors.red, size: 20),
                                          SizedBox(width: 5),
                                          Text("EXPENSE",
                                              style: TextStyle(
                                                  color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        expenseController.text,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 25),
                  Center(
                    child: SegmentedButton(
                      style: ButtonStyle(
                        side: WidgetStateProperty.all(BorderSide(
                            color: Colors.white.withOpacity(0.5))),
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return Colors.red.shade800;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.red;
                            }
                            return Colors.white;
                          },
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                            value: 'select month',
                            label: Text('Month'),
                            icon: Icon(Icons.calendar_month)),
                        ButtonSegment(
                            value: 'all',
                            label: Text('All Time'),
                            icon: Icon(Icons.all_inclusive)),
                      ],
                      selected: {resultSelection},
                      onSelectionChanged: (newselection) {
                        setState(() {
                          resultSelection = newselection.first;
                        });
                        fetchData();
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Visibility(
                    visible: resultSelection != 'all',
                    child: Card(
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        title: const Text('Filtered Month'),
                        subtitle: Text(
                          DateFormat('MMMM yyyy').format(selectedDate),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        leading: const Icon(Icons.calendar_today, color: Colors.red),
                        trailing: const Icon(Icons.edit, color: Colors.grey),
                        onTap: showPicker,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  if (!_isLoading && pieSections.isNotEmpty) ...[
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text("Expense Breakdown",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: pieSections,
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: categoryData.keys.map((category) {
                                int index = categories.indexOf(category);
                                if (index == -1) index = categoryColors.length - 1;
                                return Chip(
                                  backgroundColor:
                                      categoryColors[index % categoryColors.length]
                                          .withOpacity(0.1),
                                  side: BorderSide.none,
                                  label: Text(category,
                                      style: const TextStyle(fontSize: 11)),
                                  avatar: CircleAvatar(
                                    backgroundColor: categoryColors[
                                        index % categoryColors.length],
                                    radius: 5,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (!_isLoading && (resultSelection != 'all' || transactions.isNotEmpty))
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: Text("No expenses to show in chart",
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                  const SizedBox(height: 25),
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const ShimmerTransactionList()
                  else if (transactions.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          Icon(Icons.receipt_long, size: 80, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(height: 15),
                          const Text(
                            "No transactions found.",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Add some expenses to get started!",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final item = transactions[index];
                        bool isExpense = item['type'] == 'Expense';
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isExpense
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isExpense
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                            title: Text(
                              item['category'] ?? 'Transaction',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(DateTime.parse(item['date'])),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "${isExpense ? '-' : '+'} ${item['amount']}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isExpense ? Colors.red : Colors.green,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => deleteTransaction(item, index),
                                  child: const Text(
                                    "Delete",
                                    style:
                                        TextStyle(color: Colors.grey, fontSize: 10),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 80), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
