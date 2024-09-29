import 'dart:math';
class InsightsEngine {
  final List<Map<String, dynamic>> transactions;
  InsightsEngine(this.transactions);
  Map<String, dynamic> getSpendingPersona() {
    final dailyTotals = _getDailyExpenseTotals();
    if (dailyTotals.length < 3) {
      return {
        'persona': 'Not Enough Data',
        'emoji': '📊',
        'color': 'grey',
        'description': 'Add expenses for at least 3 different days to get your persona.',
        'hasData': false,
      };
    }
    dailyTotals.sort();
    final p25 = _percentile(dailyTotals, 25);
    final p50 = _percentile(dailyTotals, 50);
    final p75 = _percentile(dailyTotals, 75);
    final recentAvg = _getRecentDailyAverage(7);
    final overallAvg = dailyTotals.reduce((a, b) => a + b) / dailyTotals.length;
    String persona;
    String emoji;
    String color;
    String description;
    if (recentAvg <= p25) {
      persona = 'Ultra Saver';
      emoji = '🟢';
      color = 'green';
      description =
          'Your recent spending (₹${recentAvg.toStringAsFixed(0)}/day) is in your lowest 25%. Excellent discipline!';
    } else if (recentAvg <= p50) {
      persona = 'Smart Spender';
      emoji = '🔵';
      color = 'blue';
      description =
          'Your recent spending (₹${recentAvg.toStringAsFixed(0)}/day) is below your median of ₹${p50.toStringAsFixed(0)}/day. Good balance!';
    } else if (recentAvg <= p75) {
      persona = 'Watch Out';
      emoji = '🟡';
      color = 'orange';
      description =
          'Your recent spending (₹${recentAvg.toStringAsFixed(0)}/day) is above your median. Consider cutting back.';
    } else {
      persona = 'Overspending';
      emoji = '🔴';
      color = 'red';
      description =
          'Your recent spending (₹${recentAvg.toStringAsFixed(0)}/day) is in your highest 25%. Your average is ₹${overallAvg.toStringAsFixed(0)}/day.';
    }
    return {
      'persona': persona,
      'emoji': emoji,
      'color': color,
      'description': description,
      'recentAvg': recentAvg,
      'overallAvg': overallAvg,
      'p25': p25,
      'p50': p50,
      'p75': p75,
      'hasData': true,
    };
  }
  List<Map<String, dynamic>> detectAnomalies() {
    Map<String, List<double>> categoryAmounts = {};
    Map<String, List<Map<String, dynamic>>> categoryTransactions = {};
    for (var txn in transactions) {
      if (txn['type'] != 'Expense') continue;
      String category = txn['category'] ?? 'others';
      double amount = (txn['amount'] as num).toDouble();
      categoryAmounts.putIfAbsent(category, () => []);
      categoryAmounts[category]!.add(amount);
      categoryTransactions.putIfAbsent(category, () => []);
      categoryTransactions[category]!.add(txn);
    }
    List<Map<String, dynamic>> anomalies = [];
    for (var category in categoryAmounts.keys) {
      final amounts = categoryAmounts[category]!;
      if (amounts.length < 3) continue;  
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      final variance =
          amounts.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
              amounts.length;
      final stdDev = sqrt(variance);
      if (stdDev == 0) continue; 
      final txns = categoryTransactions[category]!;
      for (int i = 0; i < txns.length; i++) {
        double amount = (txns[i]['amount'] as num).toDouble();
        double zScore = (amount - mean).abs() / stdDev;
        if (zScore > 2.0) {
          anomalies.add({
            'transaction': txns[i],
            'category': category,
            'amount': amount,
            'mean': mean,
            'zScore': zScore,
            'multiplier': (amount / mean),
            'message':
                '₹${amount.toStringAsFixed(0)} on $category is ${(amount / mean).toStringAsFixed(1)}x your average of ₹${mean.toStringAsFixed(0)}',
          });
        }
      }
    }
    anomalies.sort(
        (a, b) => (b['zScore'] as double).compareTo(a['zScore'] as double));
    return anomalies;
  }
  Map<String, dynamic> predictNextMonth() {
    Map<String, double> monthlyTotals = {};
    for (var txn in transactions) {
      if (txn['type'] != 'Expense') continue;
      String date = txn['date'] as String;
      String monthKey = date.substring(0, 7); 
      double amount = (txn['amount'] as num).toDouble();
      monthlyTotals[monthKey] = (monthlyTotals[monthKey] ?? 0) + amount;
    }
    if (monthlyTotals.length < 2) {
      return {
        'hasData': false,
        'message': 'Need at least 2 months of data for forecasting.',
      };
    }
    final sortedMonths = monthlyTotals.keys.toList()..sort();
    List<double> xValues = [];  
    List<double> yValues = [];  
    for (int i = 0; i < sortedMonths.length; i++) {
      xValues.add(i.toDouble());
      yValues.add(monthlyTotals[sortedMonths[i]]!);
    }
    int n = xValues.length;
    double sumX = xValues.reduce((a, b) => a + b);
    double sumY = yValues.reduce((a, b) => a + b);
    double sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumXY += xValues[i] * yValues[i];
      sumX2 += xValues[i] * xValues[i];
    }
    double denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) {
      return {
        'hasData': false,
        'message': 'Cannot compute trend with current data.',
      };
    }
    double slope = (n * sumXY - sumX * sumY) / denominator;
    double intercept = (sumY - slope * sumX) / n;
    double nextMonthIndex = n.toDouble();
    double predicted = slope * nextMonthIndex + intercept;
    if (predicted < 0) predicted = 0; 
    String trend;
    String trendEmoji;
    if (slope > 50) {
      trend = 'Spending is increasing by ~₹${slope.toStringAsFixed(0)}/month';
      trendEmoji = '📈';
    } else if (slope < -50) {
      trend =
          'Spending is decreasing by ~₹${slope.abs().toStringAsFixed(0)}/month';
      trendEmoji = '📉';
    } else {
      trend = 'Spending is relatively stable';
      trendEmoji = '➡️';
    }
    List<Map<String, dynamic>> history = [];
    for (int i = 0; i < sortedMonths.length; i++) {
      history.add({
        'month': sortedMonths[i],
        'actual': yValues[i],
        'predicted': slope * xValues[i] + intercept,
      });
    }
    return {
      'hasData': true,
      'predicted': predicted,
      'slope': slope,
      'intercept': intercept,
      'trend': trend,
      'trendEmoji': trendEmoji,
      'history': history,
      'lastMonth': sortedMonths.last,
      'lastMonthTotal': yValues.last,
    };
  }
  List<Map<String, dynamic>> getCategoryInsights() {
    Map<String, double> categoryTotals = {};
    double totalExpense = 0;
    for (var txn in transactions) {
      if (txn['type'] != 'Expense') continue;
      String category = txn['category'] ?? 'others';
      double amount = (txn['amount'] as num).toDouble();
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      totalExpense += amount;
    }
    if (totalExpense == 0) return [];
    var sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((entry) {
      double percentage = (entry.value / totalExpense) * 100;
      return {
        'category': entry.key,
        'total': entry.value,
        'percentage': percentage,
        'label':
            '${entry.key}: ₹${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(1)}%)',
      };
    }).toList();
  }
  List<double> _getDailyExpenseTotals() {
    Map<String, double> dailyTotals = {};
    for (var txn in transactions) {
      if (txn['type'] != 'Expense') continue;
      String date = txn['date'] as String;
      double amount = (txn['amount'] as num).toDouble();
      dailyTotals[date] = (dailyTotals[date] ?? 0) + amount;
    }
    return dailyTotals.values.toList();
  }
  double _getRecentDailyAverage(int days) {
    Map<String, double> dailyTotals = {};
    for (var txn in transactions) {
      if (txn['type'] != 'Expense') continue;
      String date = txn['date'] as String;
      double amount = (txn['amount'] as num).toDouble();
      dailyTotals[date] = (dailyTotals[date] ?? 0) + amount;
    }
    if (dailyTotals.isEmpty) return 0;
    var sortedDates = dailyTotals.keys.toList()..sort();
    var recentDates = sortedDates.length > days
        ? sortedDates.sublist(sortedDates.length - days)
        : sortedDates;
    double total = 0;
    for (var date in recentDates) {
      total += dailyTotals[date]!;
    }
    return total / recentDates.length;
  }
  double _percentile(List<double> sorted, int p) {
    if (sorted.isEmpty) return 0;
    double index = (p / 100) * (sorted.length - 1);
    int lower = index.floor();
    int upper = index.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] + (sorted[upper] - sorted[lower]) * (index - lower);
  }
}
