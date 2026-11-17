
import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/database_service.dart';

class MonthlyChart extends StatefulWidget {
  const MonthlyChart({super.key});

  @override
  State<MonthlyChart> createState() => _MonthlyChartState();
}

class _MonthlyChartState extends State<MonthlyChart> {
  List<Map<String, dynamic>> monthlyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadMonthlyData();
  }

  Future<void> loadMonthlyData() async {
    try {
      final data = await DatabaseService.instance.getMonthlyTotals();

      if (!mounted) return;

      setState(() {
        monthlyData = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> getChartData() {
    final now = DateTime.now();

    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - 5 + index, 1);

      final key =
          '${month.year}-${month.month.toString().padLeft(2, '0')}';

      final record = monthlyData.where(
        (item) => item['month'] == key,
      );

      if (record.isEmpty) {
        return {
          'month': month,
          'gave': 0.0,
          'got': 0.0,
        };
      }

      return {
        'month': month,
        'gave': (record.first['gave_total'] as num).toDouble(),
        'got': (record.first['got_total'] as num).toDouble(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final data = getChartData();

    final maxAmount = data.fold<double>(
      0,
      (previous, item) {
        final gave = item['gave'] as double;
        final got = item['got'] as double;
        return [
          previous,
          gave,
          got,
        ].reduce((a, b) => a > b ? a : b);
      },
    );

    final chartMax = maxAmount == 0 ? 100.0 : maxAmount * 1.2;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('You Gave'),
                const SizedBox(width: 18),
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('You Got'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 230,
              child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(6, (index) {
                    final gave = data[index]['gave'] as double;
                    final got = data[index]['got'] as double;

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 5,
                      barRods: [
                        BarChartRodData(
                          toY: gave,
                          color: Colors.blue,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: got,
                          color: Colors.green,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value >= 1000
                                ? '${(value / 1000).toStringAsFixed(0)}k'
                                : value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 35,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }

                          final month =
                              data[index]['month'] as DateTime;

                          const months = [
                            'Jan', 'Feb', 'Mar', 'Apr',
                            'May', 'Jun', 'Jul', 'Aug',
                            'Sep', 'Oct', 'Nov', 'Dec'
                          ];

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              months[month.month - 1],
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true),
                  barTouchData: BarTouchData(
                    enabled: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
