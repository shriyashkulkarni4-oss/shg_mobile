import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/blockchain_service.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final BlockchainService _blockchainService = BlockchainService();

  @override
  Widget build(BuildContext context) {
    final shgId = context.watch<AuthProvider>().shgId;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (shgId == null || uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Management')),
      body: StreamBuilder<DocumentSnapshot>(
        // Get member doc for trust score
        stream: FirebaseFirestore.instance
            .collection('ShgGroups')
            .doc(shgId)
            .collection('members')
            .doc(uid)
            .snapshots(),
        builder: (context, memberSnap) {
          final memberData = memberSnap.data?.data() as Map<String, dynamic>? ?? {};
          final double trustScore = (memberData['trustScore'] ?? 0).toDouble();
          final double totalContributed = (memberData['totalContributed'] ?? 12500).toDouble();
          final double eligibleAmount = totalContributed * 2.5;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('ShgGroups')
                .doc(shgId)
                .collection('loans')
                .where('memberId', isEqualTo: uid)
                .snapshots(),
            builder: (context, loanSnap) {
              if (loanSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = loanSnap.data?.docs ?? [];
              final loansList = docs
                  .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                  .toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEligibilityCard(trustScore, eligibleAmount),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _showEmiCalculator,
                            icon: const Icon(Icons.calculate),
                            label: const Text('EMI Calculator'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade50,
                              foregroundColor: Colors.teal.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showApplyLoanDialog(shgId, uid),
                            icon: const Icon(Icons.add),
                            label: const Text('Apply Loan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text("Your Loans",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (loansList.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.account_balance_wallet_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text("No loans yet",
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("Apply for a loan to get started",
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ...loansList.map((loan) => _buildLoanCard(loan, shgId, uid)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEligibilityCard(double trustScore, double eligibleAmount) {
    return Card(
      elevation: 2,
      color: Colors.teal.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Loan Eligibility",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("Trust Score: ${trustScore.toInt()}",
                      style: TextStyle(color: Colors.purple.shade700, fontSize: 12)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Max Eligible Amount",
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      Text("₹${eligibleAmount.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Interest Rate",
                          style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const Text("12% p.a.",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLoanCard(Map<String, dynamic> loan, String shgId, String uid) {
    final double amount = (loan['amount'] ?? loan['principalAmount'] ?? 0).toDouble();
    final double remaining =
        (loan['remainingAmount'] ?? loan['remaining'] ?? amount).toDouble();
    final double paid = amount - remaining;
    final double progress = amount > 0 ? (paid / amount).clamp(0.0, 1.0) : 0.0;
    final String purpose = loan['purpose'] ?? 'General Loan';
    final String status = loan['status'] ?? 'PENDING';
    final double emi = (loan['emi'] ?? loan['emiAmount'] ?? 0).toDouble();
    final String nextDue = loan['nextDue'] ?? 'N/A';
    final bool isApproved = status == 'APPROVED';
    final bool isPending = status == 'PENDING';

    Color statusColor = isPending ? Colors.orange : (isApproved ? Colors.green : Colors.red);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.blue),
                    const SizedBox(width: 8),
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
                  child: Text(status,
                      style: TextStyle(
                          color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Principal", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text("₹${amount.toInt()}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Remaining", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text("₹${remaining.toInt()}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Monthly EMI", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    Text("₹${emi.toInt()}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Repayment Progress",
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text("${(progress * 100).toInt()}%",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: progress >= 1.0 ? Colors.green : Colors.blue,
                minHeight: 10,
              ),
            ),
            if (isApproved && remaining > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        const Text("Next EMI Due",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text(nextDue,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.payment),
                  label: Text("Pay EMI  (₹${emi.toInt()})"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => _payEmi(loan, shgId, uid, emi),
                ),
              ),
            ],
            if (progress >= 1.0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Loan Fully Repaid!",
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _payEmi(Map<String, dynamic> loan, String shgId, String uid, double emiAmount) async {
    final String loanId = loan['id'];
    final double amount = (loan['amount'] ?? loan['principalAmount'] ?? 0).toDouble();
    final double remaining = (loan['remainingAmount'] ?? loan['remaining'] ?? amount).toDouble();
    final double newRemaining = (remaining - emiAmount).clamp(0, double.infinity);

    // Show processing
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing payment...'), duration: Duration(seconds: 1)),
    );

    try {
      // Update Firestore immediately (optimistic)
      await FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shgId)
          .collection('loans')
          .doc(loanId)
          .update({
        'remainingAmount': newRemaining,
        'paidAmount': amount - newRemaining,
        'status': newRemaining <= 0 ? 'COMPLETED' : 'APPROVED',
        'lastPaidAt': FieldValue.serverTimestamp(),
      });

      // Optionally also call blockchain (fire-and-forget, don't block UI)
      _blockchainService.payEMI(1, 0.01).then((txHash) {
        debugPrint('Blockchain TX: $txHash');
      }).catchError((e) {
        debugPrint('Blockchain TX failed (non-critical): $e');
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newRemaining <= 0
              ? '🎉 Loan fully repaid!'
              : 'Payment successful! Remaining: ₹${newRemaining.toStringAsFixed(0)}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showApplyLoanDialog(String shgId, String uid) {
    final purposeCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final tenureCtrl = TextEditingController(text: '12');
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Apply for Loan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Purpose (e.g. Agriculture)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tenureCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tenure (months)',
                    border: OutlineInputBorder(),
                    suffixText: 'months',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final purpose = purposeCtrl.text.trim();
                      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                      final tenure = int.tryParse(tenureCtrl.text.trim()) ?? 12;
                      if (purpose.isEmpty || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields')),
                        );
                        return;
                      }
                      setDialogState(() => isLoading = true);
                      // EMI = P * r * (1+r)^n / ((1+r)^n - 1) where r = 12%/12
                      final double r = 12 / 12 / 100;
                      double pow = 1;
                      for (int i = 0; i < tenure; i++) pow *= (1 + r);
                      final double emi = (amount * r * pow) / (pow - 1);

                      await FirebaseFirestore.instance
                          .collection('ShgGroups')
                          .doc(shgId)
                          .collection('loans')
                          .add({
                        'memberId': uid,
                        'purpose': purpose,
                        'amount': amount,
                        'principalAmount': amount,
                        'remainingAmount': amount,
                        'paidAmount': 0,
                        'emi': emi.roundToDouble(),
                        'emiAmount': emi.roundToDouble(),
                        'tenureMonths': tenure,
                        'status': 'PENDING',
                        'nextDue': 'Pending approval',
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      setDialogState(() => isLoading = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Loan application submitted! Awaiting admin approval.'),
                            backgroundColor: Colors.teal,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488), foregroundColor: Colors.white),
              child: isLoading
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmiCalculator() {
    double amount = 10000;
    double tenure = 12;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final double r = 12 / 12 / 100;
          double pw = 1;
          for (int i = 0; i < tenure.toInt(); i++) pw *= (1 + r);
          final double emi = (amount * r * pw) / (pw - 1);
          final double totalPayable = emi * tenure;
          final double totalInterest = totalPayable - amount;

          return AlertDialog(
            title: const Text('EMI Calculator'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Amount: ₹${amount.toInt()}"),
                Slider(
                  value: amount,
                  min: 1000,
                  max: 200000,
                  divisions: 199,
                  activeColor: const Color(0xFF0D9488),
                  onChanged: (v) => setState(() => amount = v),
                ),
                Text("Tenure: ${tenure.toInt()} months"),
                Slider(
                  value: tenure,
                  min: 3,
                  max: 36,
                  divisions: 33,
                  activeColor: Colors.blue,
                  onChanged: (v) => setState(() => tenure = v),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Monthly EMI:"),
                    Text("₹${emi.toInt()}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Color(0xFF0D9488), fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Interest:"),
                    Text("₹${totalInterest.toInt()}"),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total Payable:"),
                    Text("₹${totalPayable.toInt()}",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }
}
