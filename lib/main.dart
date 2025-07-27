
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART EXPENSE TRACKER',
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.red,
          foregroundColor: Colors.black,
          titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  int totalIncome = 0;

  final TextEditingController incomeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  @override
  void dispose() {
    incomeController.dispose();
    super.dispose();
  }

  Future<void> _loadIncomeData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
     
      totalIncome = prefs.getInt('totalIncome') ?? 0;
    });
  }

  Future<void> _saveIncomeData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalIncome', totalIncome);
  }

  void _addIncome() {
    int? income = int.tryParse(incomeController.text);
    if (income != null) {
      setState(() {
        totalIncome += income;
      });
      _saveIncomeData();
      incomeController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid number")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Smart Expense Tracker")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Enter Income",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: _addIncome,
              child: const Text("Add Income"),
            ),
            const SizedBox(height: 35),
            Text("Total Income: $totalIncome", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddingExpense()),
                );
              },
              child: const Text("Add Expense"),
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Gamification()));
              },
              child: const Text("Gamification"),
            )
          ],
        ),
      ),
    );
  }
}
class AddingExpense extends StatefulWidget {
  const AddingExpense({super.key});

  @override
  _AddingExpenseState createState() => _AddingExpenseState();
}
String selectedCategory = 'entertainment';

class _AddingExpenseState extends State<AddingExpense> {
  final TextEditingController itemName = TextEditingController();
  final TextEditingController itemPrice = TextEditingController();
  final TextEditingController category = TextEditingController();
  final TextEditingController payment = TextEditingController();
  final String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> expenseList = prefs.getStringList('expense') ?? [];
    setState(() {
      expenses = expenseList
          .map((expenStr) => jsonDecode(expenStr) as Map<String, dynamic>)
          .toList();
    });
  }

  @override
  void dispose() {
    itemName.dispose();
    itemPrice.dispose();
    category.dispose();
    payment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Expenses"),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Row for Item Name
              Row(
                children: [
                  const SizedBox(width: 100, child: Text("Item name")),
                  Expanded(
                    child: TextField(
                      controller: itemName,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 35),
              // Row for Item Price
              Row(
                children: [
                  const SizedBox(width: 100, child: Text("Item price")),
                  Expanded(
                    child: TextField(
                      controller: itemPrice,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 35),
            
              Row(
                children: [
                  const SizedBox(width: 100, child: Text("Category")),
                  Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'entertainment', child: Text('Entertainment')),
                      DropdownMenuItem(value: 'necessary', child: Text('Necessary')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                )
                                ],
              ),
              const SizedBox(height: 35),
           
              Row(
                children: [
                  const SizedBox(width: 100, child: Text("Payment")),
                  Expanded(
                    child: TextField(
                      controller: payment,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 35),
             
              Row(
                children: [
                  const SizedBox(width: 100, child: Text("Date")),
                  Text(formattedDate),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Padding(padding: const EdgeInsets.all(30),child: ElevatedButton(onPressed: ()async{
                    if(itemName.text.isEmpty ||itemPrice.text.isEmpty){
                      return ;
                    }
                    final newExpense = {
                      'name':itemName.text,
                      'price':itemPrice.text,
                      'category':selectedCategory,
                      'payment':payment.text,
                      'date':formattedDate,

                    };
                    final prefs = await SharedPreferences.getInstance();
                    final List<String> existingExpenses = prefs.getStringList('expense')??[];
                    existingExpenses.add(jsonEncode(newExpense));
                    await prefs.setStringList('expense', existingExpenses);
                    setState(() {
                       itemName.clear();
                      itemPrice.clear();
                      payment.clear();
                      selectedCategory = 'entertainment';
                    });
                  }, child: Text("Submit")))]
                
              ),
              const SizedBox(height: 35),
             
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: (

                        ) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder:(context)=>SpendingGraph()),
                      );
                    },
                    child: const Text("Spending graph"),
                  ),
                  const SizedBox(width: 29),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ViewSpending()),
                      );
                    },
                    child: const Text("View spending"),
                  ),
                ],
              ),
              const SizedBox(height: 35),
             
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                 
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  SpendingMonthlyBills()),
                      );
                    },
                    child: const Text("View Monthly bills"),
                  ),


                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum SortType { date, price, category }

class Tuple_Expense {
  final String date;
  final double price;
  final String category;


  Tuple_Expense({
    required this.date,
    required this.price,
    required this.category,
  });
}
class ViewSpending extends StatefulWidget {
  const ViewSpending({super.key});
  @override
  _ViewSpendingState createState() => _ViewSpendingState();
}

class _ViewSpendingState extends State<ViewSpending> {
  SortType selectedSort = SortType.price;
  List<Tuple_Expense> expenseList = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> expenseJson = prefs.getStringList('expense') ?? [];
    setState(() {
      expenseList = expenseJson.map((expenseStr) {
        final Map<String, dynamic> expMap = jsonDecode(expenseStr);
        return Tuple_Expense(
          date: expMap['date'] ?? '',
          price: double.tryParse(expMap['price'].toString()) ?? 0.0,
          category: expMap['category'] ?? '',
        );
      }).toList();
      sortItems(selectedSort);
    });
  }

  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> encodedExpenses = expenseList.map((exp) {
      return jsonEncode({
        'date': exp.date,
        'price': exp.price.toString(),
        'category': exp.category,
      });
    }).toList();
    await prefs.setStringList('expense', encodedExpenses);
  }

  void sortItems(SortType type) {
    setState(() {
      selectedSort = type;
      switch (type) {
        case SortType.date:
          expenseList.sort((a, b) => a.date.compareTo(b.date));
          break;
        case SortType.price:
          expenseList.sort((a, b) => a.price.compareTo(b.price));
          break;
        case SortType.category:
          expenseList.sort((a, b) => a.category.compareTo(b.category));
          break;
      }
    });
  }

  Future<void> addExpense(Tuple_Expense newExpense) async {
    setState(() {
      expenseList.add(newExpense);
    });
    await saveExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("View Spending"),
        backgroundColor: Colors.red,
        actions: [
          PopupMenuButton<SortType>(
            onSelected: sortItems,
            icon: const Icon(Icons.sort),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<SortType>>[
              const PopupMenuItem<SortType>(
                value: SortType.date,
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem<SortType>(
                value: SortType.price,
                child: Text('Sort by Price'),
              ),
              const PopupMenuItem<SortType>(
                value: SortType.category,
                child: Text('Sort by Category'),
              ),
            ],
          ),
        ],
      ),
      body: expenseList.isEmpty
          ? const Center(child: Text("No expenses available"))
          : ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: expenseList.length,
              itemBuilder: (context, index) {
                final expense = expenseList[index];
                return Card(
                  child: ListTile(
                    title: Text(
                        "Date: ${expense.date}  Price: ₹${expense.price.toStringAsFixed(2)}"),
                    subtitle: Text("Category: ${expense.category}"),
                  ),
                );
              },
            ),
      
    );
  }
}
enum TimeFrame { tenDays, oneMonth, sixMonths }

class SpendingGraph extends StatefulWidget {
  const SpendingGraph({super.key});
  @override
  _SpendingGraph createState() => _SpendingGraph();
}

class _SpendingGraph extends State<SpendingGraph> {
  TimeFrame _selectedTimeFrame = TimeFrame.tenDays;
  List<FlSpot> spots = [];

  @override
  void initState() {
    super.initState();
    _generateData();
  }

  void _onTimeFrameChanged(TimeFrame newTimeFrame) {
    setState(() {
      _selectedTimeFrame = newTimeFrame;
    });
    _generateData();
  }

  Future<void> _generateData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> expenseJson = prefs.getStringList('expense') ?? [];

    final now = DateTime.now();
    Duration duration;
    switch (_selectedTimeFrame) {
      case TimeFrame.tenDays:
        duration = const Duration(days: 10);
        break;
      case TimeFrame.oneMonth:
        duration = const Duration(days: 30);
        break;
      case TimeFrame.sixMonths:
        duration = const Duration(days: 180);
        break;
    }

    DateTime startDate = now.subtract(duration);

    List<Tuple_Expense> expenses = expenseJson.map((expenseStr) {
      final expMap = jsonDecode(expenseStr);
      return Tuple_Expense(
        date: expMap['date'] ?? '',
        price: double.tryParse(expMap['price'].toString()) ?? 0.0,
        category: expMap['category'] ?? '',
      );
    }).where((exp) {
      DateTime expDate = DateTime.tryParse(exp.date) ?? now;
      return expDate.isAfter(startDate) && expDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();

    Map<String, double> dailyTotals = {};
    for (var exp in expenses) {
      dailyTotals[exp.date] = (dailyTotals[exp.date] ?? 0) + exp.price;
    }

    List<String> sortedDates = dailyTotals.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    List<FlSpot> dataSpots = [];
    for (int i = 0; i < sortedDates.length; i++) {
      dataSpots.add(FlSpot(i.toDouble(), dailyTotals[sortedDates[i]]!));
    }

    setState(() {
      spots = dataSpots;
    });
  }

  @override
  Widget build(BuildContext context) {
    double xInterval;
    switch (_selectedTimeFrame) {
      case TimeFrame.tenDays:
        xInterval = 1;
        break;
      case TimeFrame.oneMonth:
        xInterval = 5;
        break;
      case TimeFrame.sixMonths:
        xInterval = 30;
        break;
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Spending Graph"), backgroundColor: Colors.red),
      body: Column(
        children: [
          const SizedBox(height: 10),
          DropdownButton<TimeFrame>(
            value: _selectedTimeFrame,
            onChanged: (TimeFrame? newValue) {
              if (newValue != null) {
                _onTimeFrameChanged(newValue);
              }
            },
            items: const [
              DropdownMenuItem(value: TimeFrame.tenDays, child: Text("10 Days")),
              DropdownMenuItem(value: TimeFrame.oneMonth, child: Text("1 Month")),
              DropdownMenuItem(value: TimeFrame.sixMonths, child: Text("6 Months")),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(),
                      bottom: BorderSide(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < spots.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text("Day ${value.toInt() + 1}",
                                  style: const TextStyle(fontSize: 12)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) => Text(
                          "Rs.${value.toInt()}",
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      color: Colors.blueAccent,
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot spot) {
                          return LineTooltipItem(
                            "Day ${spot.x.toInt() + 1}: Rs.${spot.y.toStringAsFixed(2)}",
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
class Gamification extends StatefulWidget {
  const Gamification({super.key});

  @override
  _GamificationState createState() => _GamificationState();
}

class _GamificationState extends State<Gamification> {
  int monthlyPoints = 0;
  int lifetimePoints = 0;
  double monthlyBudget = 0.0;
  double entertainmentBudget = 0.0;
  double entertainmentSpending = 0.0;

  final TextEditingController monthlyController = TextEditingController();
  final TextEditingController entertainmentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndExpenses();
  }

  Future<void> _loadPreferencesAndExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    monthlyBudget = prefs.getDouble('monthlyBudget') ?? 0.0;
    entertainmentBudget = prefs.getDouble('entertainmentBudget') ?? 0.0;
    lifetimePoints = prefs.getInt('lifetimePoints') ?? 0;
    final List<String> expenseJson = prefs.getStringList('expense') ?? [];
    double entertainmentTotal = 0.0;

    for (String item in expenseJson) {
      final expense = jsonDecode(item);
      if (expense['category']?.toLowerCase() == 'entertainment') {
        entertainmentTotal += double.tryParse(expense['price'].toString()) ?? 0.0;
      }
    }

    setState(() {
      entertainmentSpending = entertainmentTotal;
      _calculatePoints();
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('monthlyBudget', monthlyBudget);
    await prefs.setDouble('entertainmentBudget', entertainmentBudget);
    await prefs.setInt('lifetimePoints', lifetimePoints);
  }

  void _calculatePoints() {
    int tempMonthly = 0;

    if (monthlyBudget > 0) tempMonthly += 50;
    if (entertainmentSpending < entertainmentBudget) tempMonthly += 30;
    else if (entertainmentSpending > entertainmentBudget * 1.25) tempMonthly -= 30;
    else if (entertainmentSpending > entertainmentBudget * 1.10) tempMonthly -= 10;

    setState(() {
      monthlyPoints = tempMonthly;
      lifetimePoints += tempMonthly;
    });

    _savePreferences();
  }

  void _updateBudgets() {
    setState(() {
      monthlyBudget = double.tryParse(monthlyController.text) ?? 0.0;
      entertainmentBudget = double.tryParse(entertainmentController.text) ?? 0.0;
    });

    _loadPreferencesAndExpenses(); // Recalculate points using updated values
  }

  void _resetBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      monthlyPoints = 0;
      lifetimePoints = 0;
      monthlyBudget = 0.0;
      entertainmentBudget = 0.0;
      entertainmentSpending = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Points Arena"),
        centerTitle: true,
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text("Your Points", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSimpleCard("Monthly Points", monthlyPoints),
                  _buildSimpleCard("Lifetime Points", lifetimePoints),
                ],
              ),
              const SizedBox(height: 30),
              const Text("Set Budgets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildInputField("Monthly Budget", monthlyController),
              _buildInputField("Entertainment Budget", entertainmentController),
              const SizedBox(height: 10),
              Text("Total Spent on Entertainment: ₹${entertainmentSpending.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _updateBudgets,
                child: const Text("Save and Calculate"),
              ),
              TextButton(
                onPressed: _resetBudgets,
                child: const Text("Reset All"),
              ),
              const SizedBox(height: 20),
              const Text("Point Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildBudgetRow("Monthly Budget set and achieved", "+50"),
              _buildBudgetRow("Spent less than entertainment budget", "+30"),
              _buildBudgetRow("Spent 10% more", "-10"),
              _buildBudgetRow("Spent 25% and more", "-30"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleCard(String title, int points) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(points.toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBudgetRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
class SpendingMonthlyBills extends StatefulWidget {
  const SpendingMonthlyBills({super.key});

  @override
  SpendingMonthlyBillsState createState() => SpendingMonthlyBillsState();
}

class SpendingMonthlyBillsState extends State<SpendingMonthlyBills> {
  List<List<String>> spend = [];

  @override
  void initState() {
    super.initState();
    loadSpendList();
  }
  Future<void> loadSpendList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? spendStringList = prefs.getStringList('spend_list');

    if (spendStringList == null) {
      spend = [
        ['rishabs', '10000', '29-02-2020'],
        ['anita', '8500', '15-08-2021'],
        ['karan', '9200', '01-01-2022'],
      ];
    } else {
      spend = spendStringList.map((e) => e.split('|')).toList();
    }
    setState(() {});
  }
  Future<void> saveSpendList() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> spendStringList = spend.map((bill) => bill.join('|')).toList();
    await prefs.setStringList('spend_list', spendStringList);
  }
  void deleteItem(int index) {
    setState(() {
      spend.removeAt(index);
    });
    saveSpendList();
  }
  void addNewBill(List<String> newBill) {
    setState(() {
      spend.add(newBill);
    });
    saveSpendList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Monthly Bills",
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'itemName',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'duedate',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(width: 48),
            ],
          ),
          const Divider(),

          ...spend.asMap().entries.map((entry) {
            int index = entry.key;
            List<String> bill = entry.value;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(bill[0], style: const TextStyle(fontSize: 16)),
                  Text(bill[1], style: const TextStyle(fontSize: 16)),
                  Text(bill[2], style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteItem(index),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push<List<String>>(
                context,
                MaterialPageRoute(builder: (context) => const AddingMonthlyPage()),
              );

              if (result != null && result.length == 3) {
                addNewBill(result);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class AddingMonthlyPage extends StatefulWidget {
  const AddingMonthlyPage({super.key});

  @override
  _AddingMonthlyPageState createState() => _AddingMonthlyPageState();
}

class _AddingMonthlyPageState extends State<AddingMonthlyPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    amountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void submit() {
    final name = nameController.text.trim();
    final amount = amountController.text.trim();
    final date = dateController.text.trim();

    if (name.isEmpty || amount.isEmpty || date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    Navigator.pop(context, [name, amount, date]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Add",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Payment Name:    ',
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Payment Amount: ',
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    controller: amountController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Payment Date:       ',
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: TextField(
                    controller: dateController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submit,
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}