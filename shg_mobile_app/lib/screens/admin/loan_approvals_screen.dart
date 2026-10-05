import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoanApprovalsScreen extends StatefulWidget {
  const LoanApprovalsScreen({super.key});

  @override
  State<LoanApprovalsScreen> createState() => _LoanApprovalsScreenState();
}

class _LoanApprovalsScreenState extends State<LoanApprovalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shgId = context.watch<AuthProvider>().shgId;

    if (shgId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Pending Approvals', icon: Icon(Icons.pending_actions)),
            Tab(text: 'All Loans', icon: Icon(Icons.list)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLoanList(shgId, filterStatus: 'PENDING'),
          _buildLoanList(shgId),
        ],
      ),
    );
  }

  Widget _buildLoanList(String shgId, {String? filterStatus}) {
    Query query = FirebaseFirestore.instance
        .collection('ShgGroups')
        .doc(shgId)
        .collection('loans');

    if (filterStatus != null) {
      query = query.where('status', isEqualTo: filterStatus);
    }

    query = query.orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  filterStatus == 'PENDING'
                      ? Icons.check_circle_outline
                      : Icons.account_balance_wallet_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  filterStatus == 'PENDING'
                      ? 'No pending loan requests'
                      : 'No loans found',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildLoanCard(shgId, doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildLoanCard(String shgId, String loanId, Map<String, dynamic> data) {
    final String status = data['status'] ?? 'PENDING';
    final double amount = (data['amount'] ?? data['principalAmount'] ?? 0).toDouble();
    final double remaining = (data['remainingAmount'] ?? data['remaining'] ?? amount).toDouble();
    final double emi = (data['emi'] ?? data['emiAmount'] ?? 0).toDouble();
    final String purpose = data['purpose'] ?? 'General Loan';
    final String memberId = data['memberId'] ?? '';
    final int tenure = data['tenureMonths'] ?? 12;

    final bool isPending = status == 'PENDING';
    final bool isApproved = status == 'APPROVED';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'APPROVED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'COMPLETED':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPending
            ? const BorderSide(color: Colors.orange, width: 1.5)
            : BorderSide.none,
      ),
      elevation: isPending ? 3 : 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.blue, size: 20),
                    const SizedBox(width: 6),
                    Text(purpose,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(status,
                          style: TextStyle(
                              color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Member ID
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text("Member: $memberId",
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 10),
            // Loan details grid
            Row(
              children: [
                _infoChip("Principal", "₹${amount.toInt()}", Colors.blue),
                const SizedBox(width: 8),
                _infoChip("EMI", "₹${emi.toInt()}/mo", Colors.purple),
                const SizedBox(width: 8),
                _infoChip("Tenure", "$tenure months", Colors.teal),
              ],
            ),
            if (isApproved) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip("Remaining", "₹${remaining.toInt()}", Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${((1 - remaining / amount.clamp(1, double.infinity)) * 100).toInt()}% repaid",
                          style: const TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: amount > 0 ? (1 - remaining / amount).clamp(0, 1) : 0,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.green,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateLoanStatus(shgId, loanId, 'REJECTED'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text("Reject"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateLoanStatus(shgId, loanId, 'APPROVED'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color)),
          Text(value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Future<void> _updateLoanStatus(String shgId, String loanId, String newStatus) async {
    try {
      final Map<String, dynamic> updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newStatus == 'APPROVED') {
        // Set next due date to 1 month from today
        final nextDue = DateTime.now().add(const Duration(days: 30));
        updateData['nextDue'] =
            '${nextDue.day} ${_monthName(nextDue.month)} ${nextDue.year}';
        updateData['disbursedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shgId)
          .collection('loans')
          .doc(loanId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loan $newStatus successfully'),
            backgroundColor: newStatus == 'APPROVED' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}
