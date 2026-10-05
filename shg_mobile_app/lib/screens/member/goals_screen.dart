import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final double totalSavings = 50000;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(body: Center(child: Text("Loading auth...")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('savingGoal')
            .doc(uid)
            .collection('goals')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          final goalsList = docs.map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>}).toList();

          int activeGoals = goalsList.where((g) => !(g['goalAchieved'] ?? false)).length;
          int achievedGoals = goalsList.where((g) => (g['goalAchieved'] ?? false)).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(activeGoals, achievedGoals),
                const SizedBox(height: 24),
                _buildGoalsList(goalsList),
                const SizedBox(height: 24),
                _buildTipsCard(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGoalDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  Widget _buildSummaryCard(int activeGoals, int achievedGoals) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildSummaryItem(Icons.track_changes, Colors.teal, "Total Savings", "₹${totalSavings.toStringAsFixed(0)}")),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: _buildSummaryItem(Icons.trending_up, Colors.blue, "Active Goals", activeGoals.toString())),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryItem(Icons.emoji_events, Colors.green, "Goals Achieved", achievedGoals.toString())),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, Color color, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildGoalsList(List<Map<String, dynamic>> goalsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Goals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...goalsList.map((goal) => _buildGoalCard(goal)),
      ],
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    bool achieved = goal['goalAchieved'] ?? false;
    String name = goal['goalName'] ?? 'Unnamed Goal';
    String targetDate = goal['targetDate'] ?? '';
    double targetAmount = (goal['targetAmount'] ?? 0).toDouble();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: achieved ? Colors.green.shade50 : null,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: achieved ? Colors.green.shade200 : Colors.transparent),
        borderRadius: BorderRadius.circular(12)
      ),
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
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (achieved) const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(Icons.emoji_events, size: 16, color: Colors.green),
                    )
                  ],
                ),
                if (!achieved)
                  OutlinedButton(
                    onPressed: () async {
                      if (uid != null) {
                        await FirebaseFirestore.instance
                          .collection('savingGoal')
                          .doc(uid)
                          .collection('goals')
                          .doc(goal['id'])
                          .update({'goalAchieved': true});
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text("Mark Done"),
                  )
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
                const SizedBox(width: 4),
                Text("Target: $targetDate", style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progress", style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text("${achieved ? 100 : 0}%", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: achieved ? 1.0 : 0.0,
              backgroundColor: Colors.grey.shade200,
              color: achieved ? Colors.green : Colors.blue,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Target", style: TextStyle(fontSize: 12, color: Colors.black54)),
                Text("₹${targetAmount.toInt()}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Card(
      color: Colors.purple.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.purple.shade200),
        borderRadius: BorderRadius.circular(12)
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                const Text("Tips for Achieving Your Goals", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _buildTip("Set realistic and specific goals with clear deadlines"),
            _buildTip("Make regular contributions, even small amounts add up over time"),
            _buildTip("Review and adjust your goals quarterly based on your progress"),
            _buildTip("Celebrate milestones to stay motivated on your journey"),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    String name = "";
    String target = "";
    String date = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create New Savings Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Goal Name', hintText: 'e.g. Emergency Fund'),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Target Amount (₹)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => target = v,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Target Date (YYYY-MM)'),
                onChanged: (v) => date = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (name.isNotEmpty && target.isNotEmpty && date.isNotEmpty && uid != null) {
                  await FirebaseFirestore.instance
                    .collection('savingGoal')
                    .doc(uid)
                    .collection('goals')
                    .add({
                      "goalName": name,
                      "targetAmount": int.tryParse(target) ?? 0,
                      "targetDate": date,
                      "goalAchieved": false,
                    });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Create Goal'),
            ),
          ],
        );
      }
    );
  }
}
