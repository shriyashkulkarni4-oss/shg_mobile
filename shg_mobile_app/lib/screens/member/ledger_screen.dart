import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final double totalContributed = 12500;
  final double totalSavings = 50000;
  final double loanBalance = 5000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export Statement coming soon')),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildCharts(),
            const SizedBox(height: 24),
            _buildTransactionHistory(),
            const SizedBox(height: 24),
            _buildBlockchainRepayments(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard("Total Contributed", "₹${totalContributed.toStringAsFixed(0)}", Colors.black87)),
            const SizedBox(width: 16),
            Expanded(child: _buildSummaryCard("Group Savings", "₹${totalSavings.toStringAsFixed(0)}", Colors.teal)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: _buildSummaryCard("Loan Balance", "₹${loanBalance.toStringAsFixed(0)}", Colors.blue),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Financial Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Distribution of your contributions", style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: const Color(0xFF14B8A6),
                      value: 65,
                      title: '65%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: const Color(0xFF3B82F6),
                      value: 35,
                      title: '35%',
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem("Monthly Savings", const Color(0xFF14B8A6)),
                const SizedBox(width: 16),
                _buildLegendItem("Loan Repayments", const Color(0xFF3B82F6)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTransactionHistory() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Transaction History", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Complete record of all your transactions", style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            _buildHistoryTile("Mar 15, 2024", "Monthly Contribution", "Savings", 500, true),
            const Divider(),
            _buildHistoryTile("Mar 10, 2024", "Loan EMI Payment", "Loan", 1200, true),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(String date, String type, String category, double amount, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              Text("₹${amount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(type, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(category, style: const TextStyle(fontSize: 10)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green[50] : Colors.yellow[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isVerified ? "Verified" : "Pending",
                  style: TextStyle(
                    fontSize: 10,
                    color: isVerified ? Colors.green[700] : Colors.yellow[800],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBlockchainRepayments() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Blockchain Repayments", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Text("Immutable on-chain loan repayment records", style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 16),
            const Text("No blockchain repayments found", style: TextStyle(color: Colors.black54, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
