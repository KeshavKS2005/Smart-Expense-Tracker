import 'package:flutter/material.dart';
import 'package:smart_expense_tracker/AddTransactions.dart';
import 'package:smart_expense_tracker/HomePage.dart';
import 'package:smart_expense_tracker/PersonalRecommendation.dart';
import 'package:smart_expense_tracker/DatabaseHelper.dart';
import 'UserRegistration.dart';
import 'ProfilePage.dart';
import 'UserLogin.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const UserLogin(),
    );
  }
}
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override 
  State<MainNavigation> createState() => _MainNavigationState();
}
class _MainNavigationState extends State<MainNavigation>{
  int selectedIndex= 0;
  final List<Widget> pages = [
    const HomePage(),
    const Addtransactions(),
    const Personalrecommendation(),
    ProfilePage()
  ];
  void onItemTapped(int index){
    setState(() {
      selectedIndex = index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.blueGrey,
        onTap: onItemTapped,
        items:[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ]),
    );
  }
}
