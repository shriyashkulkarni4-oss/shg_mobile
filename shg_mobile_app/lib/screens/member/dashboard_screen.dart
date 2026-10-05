import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import 'communication_screen.dart';

class MemberDashboardScreen extends StatefulWidget {
  const MemberDashboardScreen({super.key});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final shgId = context.watch<AuthProvider>().shgId;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (shgId == null || uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CommunicationScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                context.read<AuthProvider>().clear();
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ShgGroups')
            .doc(shgId)
            .collection('members')
            .doc(uid)
            .snapshots(),
        builder: (context, memberSnap) {
          if (memberSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!memberSnap.hasData || !memberSnap.data!.exists) {
            return const Center(child: Text('Member profile not found'));
          }

          final memberData = memberSnap.data!.data() as Map<String, dynamic>;
          final double trustScore = (memberData['trustScore'] ?? 0.0).toDouble();

          // Sub-scores stored directly on member doc
          final double financialScore = (memberData['loanRepaymentScore'] ?? memberData['financialScore'] ?? 0.0).toDouble();
          final double timelinessScore = (memberData['monthlyRoundScore'] ?? memberData['timelinessScore'] ?? 0.0).toDouble();
          final double attendanceScore = (memberData['attendanceScore'] ?? 0.0).toDouble();

          // Contributions: sum from rounds
          return FutureBuilder<_DashboardData>(
            future: _fetchDashboardData(shgId, uid),
            builder: (context, snap) {
              final data = snap.data ?? _DashboardData();
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(data.totalContributed, data.groupRank, data.totalMembers),
                    const SizedBox(height: 24),
                    _buildTrustScoreCard(trustScore, financialScore, timelinessScore, attendanceScore),
                    const SizedBox(height: 24),
                    _buildFinancialBalanceCard(shgId, uid),
                    const SizedBox(height: 24),
                    _buildRecentTransactionsCard(shgId, uid),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<_DashboardData> _fetchDashboardData(String shgId, String uid) async {
    final db = FirebaseFirestore.instance;
    // Total contributed by this member across all rounds
    double totalContributed = 0;
    final roundsSnap = await db.collection('ShgGroups').doc(shgId).collection('monthlyRounds').get();
    for (final roundDoc in roundsSnap.docs) {
      final contribSnap = await db
          .collection('ShgGroups')
          .doc(shgId)
          .collection('monthlyRounds')
          .doc(roundDoc.id)
          .collection('contributions')
          .doc(uid)
          .get();
      if (contribSnap.exists) {
        totalContributed += (contribSnap.data()?['amountPaid'] ?? 0).toDouble();
      }
    }

    // Group rank
    final membersSnap = await db.collection('ShgGroups').doc(shgId).collection('members').get();
    final allMembers = membersSnap.docs.map((d) => {'id': d.id, 'score': (d.data()['trustScore'] ?? 0).toDouble()}).toList();
    allMembers.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    final rankIdx = allMembers.indexWhere((m) => m['id'] == uid);
    final int groupRank = rankIdx >= 0 ? rankIdx + 1 : 1;

    return _DashboardData(
      totalContributed: totalContributed,
      groupRank: groupRank,
      totalMembers: allMembers.length,
    );
  }

  Widget _buildQuickStats(double totalContributed, int groupRank, int totalMembers) {
    String ordinal(int n) {
      if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
      switch (n % 10) {
        case 1: return '${n}st';
        case 2: return '${n}nd';
        case 3: return '${n}rd';
        default: return '${n}th';
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total\nContributed',
            '₹${totalContributed.toStringAsFixed(0)}',
            Icons.trending_up,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Group\nRank',
            '${ordinal(groupRank)} of $totalMembers',
            Icons.group,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54))),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                )
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustScoreCard(double trustScore, double financialScore, double timelinessScore, double attendanceScore) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Trust Score", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: CircularProgressIndicator(
                    value: trustScore / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    color: const Color(0xFF0D9488),
                  ),
                ),
                Column(
                  children: [
                    Text(trustScore.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
                    const Text("/ 100", style: TextStyle(color: Colors.black54)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 24),
            // Sub score bars
            _buildSubScoreRow("Financial", financialScore, 40, Colors.blue),
            const SizedBox(height: 8),
            _buildSubScoreRow("Timeliness", timelinessScore, 40, Colors.purple),
            const SizedBox(height: 8),
            _buildSubScoreRow("Attendance", attendanceScore, 20, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildSubScoreRow(String label, double score, double max, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text("${score.toStringAsFixed(1)} / $max",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: max > 0 ? score / max : 0,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialBalanceCard(String shgId, String uid) {
    // Streaming: total group savings = sum all contributions in all rounds
    // Active loan total for this member
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shgId)
          .collection('loans')
          .where('memberId', isEqualTo: uid)
          .where('status', isEqualTo: 'APPROVED')
          .snapshots(),
      builder: (context, loanSnap) {
        double activeLoanTotal = 0;
        for (final doc in loanSnap.data?.docs ?? []) {
          final d = doc.data() as Map<String, dynamic>;
          activeLoanTotal += (d['remainingAmount'] ?? d['remaining'] ?? d['amount'] ?? 0).toDouble();
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Financial Balances", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.money_off, color: Colors.white)),
                  title: const Text("My Active Loan Balance"),
                  trailing: Text(
                    "₹${activeLoanTotal.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactionsCard(String shgId, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ShgGroups')
          .doc(shgId)
          .collection('loans')
          .where('memberId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Loan Transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  const Text("No recent loan transactions", style: TextStyle(color: Colors.black54))
                else
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final double amount = (data['amount'] ?? data['principalAmount'] ?? 0).toDouble();
                    final String purpose = data['purpose'] ?? 'Loan';
                    final String status = data['status'] ?? 'PENDING';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_upward, color: Colors.blue),
                      ),
                      title: Text(purpose, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(status, style: const TextStyle(fontSize: 12)),
                      trailing: Text(
                        '₹${amount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashboardData {
  final double totalContributed;
  final int groupRank;
  final int totalMembers;
  _DashboardData({this.totalContributed = 0, this.groupRank = 1, this.totalMembers = 1});
}
