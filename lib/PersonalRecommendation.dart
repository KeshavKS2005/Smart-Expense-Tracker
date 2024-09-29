import 'package:flutter/material.dart';
import 'package:smart_expense_tracker/DatabaseHelper.dart';
import 'package:smart_expense_tracker/InsightsEngine.dart';
import 'package:shared_preferences/shared_preferences.dart';
class Personalrecommendation extends StatefulWidget {
  const Personalrecommendation({super.key});
  @override
  State<Personalrecommendation> createState() => _PersonalRecommendationState();
}
class _PersonalRecommendationState extends State<Personalrecommendation> {
  bool _isLoading = true;
  InsightsEngine? _insights;
  Map<String, dynamic>? _persona;
  List<Map<String, dynamic>> _anomalies = [];
  Map<String, dynamic>? _forecast;
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final dynamic rawId = prefs.get('id');
    final int? id = rawId is String ? int.tryParse(rawId) : rawId as int?;
    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login again')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }
    try {
      final db = DatabaseHelper.instance;
      final transactions = await db.getTransactions(id);
      _insights = InsightsEngine(transactions);
      _persona = _insights!.getSpendingPersona();
      _anomalies = _insights!.detectAnomalies();
      _forecast = _insights!.predictNextMonth();
    } catch (e) {
      print("Error loading insights: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "AI Insights",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.red.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD32F2F), Color.fromARGB(255, 236, 65, 49)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildPersonaCard(),
                    const SizedBox(height: 16),
                    _buildForecastCard(),
                    const SizedBox(height: 16),
                    _buildAnomaliesCard(),
                  ],
                ),
              ),
      ),
    );
  }
  Widget _buildPersonaCard() {
    if (_persona == null || _persona!['hasData'] == false) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.psychology, size: 40, color: Colors.grey),
          title: Text("Not Enough Data"),
          subtitle: Text("Add expenses for at least 3 days to get your persona."),
        ),
      );
    }
    Color color;
    switch (_persona!['color']) {
      case 'green':
        color = Colors.green;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'red':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _persona!['emoji'],
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _persona!['persona'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const Text(
                        "Your Spending Persona",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),
            Text(
              _persona!['description'],
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildForecastCard() {
    if (_forecast == null || _forecast!['hasData'] == false) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.trending_up, size: 40, color: Colors.grey),
          title: Text("No Forecast Available"),
          subtitle: Text("Need at least 2 months of data to predict trends."),
        ),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.query_stats, color: Colors.purple.shade400, size: 32),
                const SizedBox(width: 12),
                const Text(
                  "Next Month Forecast",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Predicted Spend", style: TextStyle(color: Colors.grey)),
                    Text(
                      "₹${_forecast!['predicted'].toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(_forecast!['trendEmoji'], style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        _forecast!['trend'].split(' ').first,
                        style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_forecast!['trend'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
  Widget _buildAnomaliesCard() {
    if (_anomalies.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green, size: 32),
          title: Text("No Anomalies Detected"),
          subtitle: Text("Your spending patterns look normal!"),
        ),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
                const SizedBox(width: 12),
                Text(
                  "Anomalies Detected (${_anomalies.length})",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _anomalies.length,
              itemBuilder: (context, index) {
                final a = _anomalies[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Icon(Icons.fiber_manual_record, size: 10, color: Colors.redAccent),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a['message'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
