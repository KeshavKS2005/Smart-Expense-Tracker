import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expense_tracker/DatabaseHelper.dart';
import 'package:smart_expense_tracker/FileExport.dart';
import 'package:intl/intl.dart';
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}
class _ProfilePageState extends State<ProfilePage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _budgetController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchDetails();
  }
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _budgetController.dispose();
    super.dispose();
  }
  Future<void> fetchDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    _budgetController.text = (prefs.getInt('daily_budget') ?? 500).toString();
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login again')),
      );
      return;
    }
    try {
      final data = await DatabaseHelper.instance.getUserById(id);
      if (data == null) return;
      _emailController.text = data['email'] ?? '';
      _usernameController.text = data['username'] ?? '';
      _passwordController.text = ''; 
    } catch (e) {
      print("Fetch profile error: $e");
    }
  }
  Future<void> updateForm() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final budgetStr = _budgetController.text.trim();
    if (username.isEmpty || budgetStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fields cannot be empty')),
      );
      return;
    }
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    int budget = int.tryParse(budgetStr) ?? 500;
    await prefs.setInt('daily_budget', budget);
    if (id == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      Map<String, dynamic> updateData = {'username': username};
      if (password.isNotEmpty) {
        updateData['password'] = password;
      }
      await DatabaseHelper.instance.updateUser(id, updateData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully updated profile and budget')),
      );
    } catch (e) {
      print("Update error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error happened')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Future<void> _archiveData() async {
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    if (id == null) return;
    String cutoff = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 180)));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Archive Old Data?"),
        content: const Text(
            "This will compress expenses older than 6 months into monthly summaries. You will save space and keep your exact balance, but individual old items will be hidden."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final res = await DatabaseHelper.instance.archiveOldTransactions(id, cutoff);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        "Archived ${res['archived']} old transactions into ${res['summariesCreated']} summaries!"),
                  ));
                }
              } catch (e) {
                print("Archive error:");
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("ARCHIVE NOW", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.person, size: 80, color: Colors.white),
                const SizedBox(height: 30),
                const Text(
                  'PROFILE',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Update Details',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_outlined),
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_outline),
                            labelText: "Username",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                            ),
                            labelText: "New Password (Optional)",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.track_changes),
                            labelText: "Daily Target Budget (₹)",
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
                            onPressed: _isLoading ? null : updateForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'UPDATE',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: _archiveData,
                            icon: const Icon(Icons.archive),
                            label: const Text(
                              'ARCHIVE OLD DATA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange[800],
                              side: BorderSide(color: Colors.orange[800]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const FileExport()),
                              );
                            },
                            icon: const Icon(Icons.file_download),
                            label: const Text(
                              'EXPORT DATA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
