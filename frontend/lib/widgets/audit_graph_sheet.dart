import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AuditGraphSheet extends StatelessWidget {
  final List<dynamic> testData;
  final String attackName; // Accepts dynamic attack name

  const AuditGraphSheet({super.key, required this.testData, required this.attackName});

  @override
  Widget build(BuildContext context) {
    List<FlSpot> ssimSpots = [];
    for (var item in testData) {
      double intensity = item['intensity'].toDouble(); // Now reading 'intensity'
      double ssim = item['ssim'].toDouble();
      ssimSpots.add(FlSpot(intensity, ssim));
    }

    ssimSpots.sort((a, b) => a.x.compareTo(b.x));

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.indigo, size: 28),
              const SizedBox(width: 10),
              Text(
                "$attackName Audit Graph",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Graph illustrates the structural decay (SSIM) of the image as the $attackName intensity increases.",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Divider(height: 30),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: true),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text("Attack Intensity / Severity (%)", style: TextStyle(fontWeight: FontWeight.bold)),
                    axisNameSize: 30,
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 20),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text("SSIM Score (1.0 = Perfect)", style: TextStyle(fontWeight: FontWeight.bold)),
                    axisNameSize: 30,
                    sideTitles: SideTitles(showTitles: true, interval: 0.1, reservedSize: 40),
                  ),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
                minX: 10,
                maxX: 90,
                minY: 0.0,
                maxY: 1.0,
                lineBarsData: [
                  LineChartBarData(
                    spots: ssimSpots,
                    isCurved: true,
                    color: Colors.indigo,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close Report"),
          )
        ],
      ),
    );
  }
}