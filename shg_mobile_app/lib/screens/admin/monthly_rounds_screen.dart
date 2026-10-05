import 'package:flutter/material.dart';

class MonthlyRoundsScreen extends StatefulWidget {
  const MonthlyRoundsScreen({super.key});

  @override
  State<MonthlyRoundsScreen> createState() => _MonthlyRoundsScreenState();
}

class _MonthlyRoundsScreenState extends State<MonthlyRoundsScreen> {
  final List<Map<String, dynamic>> rounds = [
    {"id": "1", "roundName": "March Round", "amount": 2500},
    {"id": "2", "roundName": "February Round", "amount": 2500},
    {"id": "3", "roundName": "January Round", "amount": 2000},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Rounds'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage monthly savings rounds",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (rounds.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text("No rounds created yet", style: TextStyle(color: Colors.black54)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                ),
                itemCount: rounds.length,
                itemBuilder: (context, index) {
                  final round = rounds[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            round['roundName'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "₹${round['amount']}",
                            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoundDialog,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Round'),
      ),
    );
  }

  void _showCreateRoundDialog() {
    String roundName = "";
    String amount = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Monthly Round'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Round Name', hintText: 'e.g. April Round'),
                onChanged: (val) => roundName = val,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(labelText: 'Amount (₹)', hintText: 'e.g. 2000'),
                keyboardType: TextInputType.number,
                onChanged: (val) => amount = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (roundName.isNotEmpty && amount.isNotEmpty) {
                  setState(() {
                    rounds.insert(0, {
                      "id": DateTime.now().toString(),
                      "roundName": roundName,
                      "amount": int.tryParse(amount) ?? 0,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
