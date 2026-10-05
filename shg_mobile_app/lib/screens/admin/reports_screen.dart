import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../providers/auth_provider.dart';

enum _ReportType { monthlyFinancial, memberActivity, loanDefaulters }

class _ReportData {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<MapEntry<String, String>> summary;

  const _ReportData({
    required this.title,
    required this.headers,
    required this.rows,
    required this.summary,
  });
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoggingOut = false;
  bool _isGeneratingReport = false;

  Future<void> _generateAndShowReport(_ReportType type) async {
    setState(() => _isGeneratingReport = true);
    try {
      var shgId = context.read<AuthProvider>().shgId;
      if (shgId == null || shgId.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _showMessage('You are signed out. Please sign in again.');
          return;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data();
        shgId = userData?['shgId'] as String?;
        if (!userDoc.exists || shgId == null || shgId.isEmpty) {
          _showMessage(
            'Your admin user record does not have a valid SHG ID. '
            'Add shgId to users/${user.uid} and try again.',
          );
          return;
        }

        if (!mounted) return;
        context.read<AuthProvider>().setAuthData(
          shgId: shgId,
          userRole: userData?['role'] as String? ?? 'admin',
          userName: userData?['name'] as String? ?? 'Admin',
        );
      }

      final report = switch (type) {
        _ReportType.monthlyFinancial => await _buildMonthlyFinancialReport(
          shgId,
        ),
        _ReportType.memberActivity => await _buildMemberActivityReport(shgId),
        _ReportType.loanDefaulters => await _buildLoanDefaultersReport(shgId),
      };
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _buildReportPreview(report),
      );
    } catch (error) {
      if (mounted) _showMessage('Could not generate report: $error');
    } finally {
      if (mounted) setState(() => _isGeneratingReport = false);
    }
  }

  Future<_ReportData> _buildMonthlyFinancialReport(String shgId) async {
    final groupRef = FirebaseFirestore.instance
        .collection('ShgGroups')
        .doc(shgId);
    final rounds = await groupRef.collection('monthlyRounds').get();
    final loans = await groupRef.collection('loans').get();
    final members = await groupRef.collection('members').get();
    final rows = <List<String>>[];
    var totalCollected = 0.0;

    for (final round in rounds.docs) {
      final roundData = round.data();
      final contributions = await groupRef
          .collection('monthlyRounds')
          .doc(round.id)
          .collection('contributions')
          .get();
      var collected = 0.0;
      for (final contribution in contributions.docs) {
        collected += _asDouble(contribution.data()['amountPaid']);
      }
      totalCollected += collected;
      final name =
          roundData['roundName']?.toString() ??
          roundData['name']?.toString() ??
          round.id;
      rows.add([
        'Monthly round',
        name,
        '${contributions.size} member(s)',
        _formatAmount(collected),
        'Per-member target: ${_formatAmount(_asDouble(roundData['amount']))}',
      ]);
    }

    var loanPrincipal = 0.0;
    var loanPaid = 0.0;
    var loanOutstanding = 0.0;
    for (final loanDoc in loans.docs) {
      final loan = loanDoc.data();
      final status = (loan['status'] ?? '').toString().toUpperCase();
      if (status != 'APPROVED' && status != 'COMPLETED') continue;
      final principal = _asDouble(loan['principalAmount'] ?? loan['amount']);
      final remaining = status == 'COMPLETED'
          ? 0.0
          : _asDouble(
              loan['remainingAmount'] ?? loan['remaining'] ?? principal,
            );
      final paid = _asDouble(loan['paidAmount'] ?? (principal - remaining));
      loanPrincipal += principal;
      loanPaid += paid;
      loanOutstanding += remaining;
      rows.add([
        'Loan',
        loan['purpose']?.toString() ?? loanDoc.id,
        status,
        _formatAmount(principal),
        'Repaid: ${_formatAmount(paid)}; outstanding: ${_formatAmount(remaining)}',
      ]);
    }

    return _ReportData(
      title: 'Monthly Financial Report',
      headers: const [
        'Category',
        'Round / Loan',
        'Members / Status',
        'Amount',
        'Details',
      ],
      rows: rows,
      summary: [
        MapEntry('Members', members.size.toString()),
        MapEntry('Monthly rounds', rounds.size.toString()),
        MapEntry('Contributions collected', _formatAmount(totalCollected)),
        MapEntry('Loan principal', _formatAmount(loanPrincipal)),
        MapEntry('Loan repaid', _formatAmount(loanPaid)),
        MapEntry('Loan outstanding', _formatAmount(loanOutstanding)),
      ],
    );
  }

  Future<_ReportData> _buildMemberActivityReport(String shgId) async {
    final groupRef = FirebaseFirestore.instance
        .collection('ShgGroups')
        .doc(shgId);
    final members = await groupRef.collection('members').get();
    final rounds = await groupRef.collection('monthlyRounds').get();
    final loans = await groupRef.collection('loans').get();
    final memberNames = <String, String>{};
    final rows = <List<String>>[];

    for (final member in members.docs) {
      final data = member.data();
      final name = _memberName(data, member.id);
      memberNames[member.id] = name;
      rows.add([
        'Member profile',
        name,
        _formatDate(data['joinedAt'] ?? data['joinedDate']),
        '-',
        'Status: ${data['status'] ?? 'Unknown'}; role: ${data['role'] ?? 'Member'}; trust score: ${data['trustScore'] ?? '-'}',
      ]);
    }

    for (final round in rounds.docs) {
      final contributions = await groupRef
          .collection('monthlyRounds')
          .doc(round.id)
          .collection('contributions')
          .get();
      for (final contribution in contributions.docs) {
        final data = contribution.data();
        rows.add([
          'Round contribution',
          memberNames[contribution.id] ?? contribution.id,
          _formatDate(data['paidAt']),
          _formatAmount(_asDouble(data['amountPaid'])),
          'Round: ${round.data()['roundName'] ?? round.data()['name'] ?? round.id}',
        ]);
      }
    }

    for (final loanDoc in loans.docs) {
      final loan = loanDoc.data();
      final name =
          memberNames[loan['memberId']?.toString()] ??
          loan['memberId']?.toString() ??
          'Unknown member';
      final dueDates = loan['dueDates'];
      if (dueDates is! List) continue;
      for (var i = 0; i < dueDates.length; i++) {
        final due = dueDates[i];
        if (due is! Map || due['paid'] != true) continue;
        rows.add([
          'Loan repayment',
          name,
          _formatDate(due['paidAt']),
          _formatAmount(
            _asDouble(due['amount'] ?? loan['emiAmount'] ?? loan['emi']),
          ),
          'Loan: ${loan['purpose'] ?? loanDoc.id}; installment ${i + 1}',
        ]);
      }
    }

    rows.sort((a, b) => a[2].compareTo(b[2]));
    return _ReportData(
      title: 'Member Activity Log',
      headers: const ['Activity', 'Member', 'Date', 'Amount', 'Details'],
      rows: rows,
      summary: [
        MapEntry('Members', members.size.toString()),
        MapEntry('Rounds', rounds.size.toString()),
        MapEntry('Loans', loans.size.toString()),
        MapEntry('Recorded activities', rows.length.toString()),
      ],
    );
  }

  Future<_ReportData> _buildLoanDefaultersReport(String shgId) async {
    final groupRef = FirebaseFirestore.instance
        .collection('ShgGroups')
        .doc(shgId);
    final loans = await groupRef.collection('loans').get();
    final members = await groupRef.collection('members').get();
    final memberNames = {
      for (final member in members.docs)
        member.id: _memberName(member.data(), member.id),
    };
    final rows = <List<String>>[];
    final now = DateTime.now();
    var overdueAmount = 0.0;

    for (final loanDoc in loans.docs) {
      final loan = loanDoc.data();
      if ((loan['status'] ?? '').toString().toUpperCase() != 'APPROVED') {
        continue;
      }
      final dueDates = loan['dueDates'];
      if (dueDates is! List) continue;
      for (var i = 0; i < dueDates.length; i++) {
        final due = dueDates[i];
        if (due is! Map || due['paid'] == true) continue;
        final dueDate = _parseDate(due['date']);
        if (dueDate == null || !dueDate.isBefore(now)) continue;
        final amount = _asDouble(
          due['amount'] ?? loan['emiAmount'] ?? loan['emi'],
        );
        overdueAmount += amount;
        final memberId = loan['memberId']?.toString() ?? '';
        rows.add([
          memberNames[memberId] ?? memberId,
          loan['purpose']?.toString() ?? loanDoc.id,
          _formatDate(dueDate),
          _formatAmount(amount),
          'Installment ${i + 1}; loan status: ${loan['status']}',
        ]);
      }
    }

    return _ReportData(
      title: 'Loan Defaulters List',
      headers: const [
        'Member',
        'Loan',
        'Due date',
        'Overdue amount',
        'Details',
      ],
      rows: rows,
      summary: [
        MapEntry('Overdue installments', rows.length.toString()),
        MapEntry('Total overdue amount', _formatAmount(overdueAmount)),
      ],
    );
  }

  Widget _buildReportPreview(_ReportData report) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 900,
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(report.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Generated ${_formatDate(DateTime.now())}'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: report.summary
                    .map(
                      (entry) =>
                          Chip(label: Text('${entry.key}: ${entry.value}')),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: report.rows.isEmpty
                    ? const Center(child: Text('No matching records found.'))
                    : Scrollbar(
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: report.headers
                                  .map(
                                    (header) => DataColumn(label: Text(header)),
                                  )
                                  .toList(),
                              rows: report.rows
                                  .map(
                                    (row) => DataRow(
                                      cells: row
                                          .map((value) => DataCell(Text(value)))
                                          .toList(),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _savePdf(report),
                    icon: const Icon(Icons.download),
                    label: const Text('Download / Save PDF'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePdf(_ReportData report) async {
    try {
      final document = pw.Document();
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text(
              report.title,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text('Generated ${_formatDate(DateTime.now())}'),
            pw.SizedBox(height: 16),
            ...report.summary.map(
              (entry) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text('${entry.key}: ${entry.value}'),
              ),
            ),
            pw.SizedBox(height: 16),
            if (report.rows.isEmpty)
              pw.Text('No matching records found.')
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  for (var i = 0; i < report.headers.length; i++)
                    i: const pw.FlexColumnWidth(),
                },
                children: [
                  _pdfTableRow(report.headers, isHeader: true),
                  ...report.rows.map((row) => _pdfTableRow(row)),
                ],
              ),
          ],
        ),
      );
      final fileName =
          '${report.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}.pdf';
      await Printing.layoutPdf(
        name: fileName,
        onLayout: (_) => document.save(),
      );
    } catch (error) {
      if (mounted) _showMessage('Could not save PDF: $error');
    }
  }

  pw.TableRow _pdfTableRow(List<String> values, {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.deepPurple)
          : null,
      children: values
          .map(
            (value) => pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: isHeader ? PdfColors.white : PdfColors.black,
                  fontWeight: isHeader
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  String _memberName(Map<String, dynamic> data, String fallback) {
    return (data['name'] ?? data['firstName'] ?? data['email'] ?? fallback)
        .toString();
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is Map && value['seconds'] is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        (value['seconds'] as num).toInt() * 1000,
      );
    }
    return null;
  }

  String _formatDate(dynamic value) {
    final date = _parseDate(value);
    if (date == null) return 'Not recorded';
    final localDate = date.toLocal();
    return '${localDate.year.toString().padLeft(4, '0')}-'
        '${localDate.month.toString().padLeft(2, '0')}-'
        '${localDate.day.toString().padLeft(2, '0')}';
  }

  String _formatAmount(double value) => 'INR ${value.toStringAsFixed(2)}';

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      context.read<AuthProvider>().clear();
      context.go('/login');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $error')));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Settings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Reports",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildReportTile(
            "Monthly Financial Report",
            Icons.pie_chart,
            _ReportType.monthlyFinancial,
          ),
          _buildReportTile(
            "Member Activity Log",
            Icons.assignment,
            _ReportType.memberActivity,
          ),
          _buildReportTile(
            "Loan Defaulters List",
            Icons.warning,
            _ReportType.loanDefaulters,
          ),

          const Divider(height: 48),

          const Text(
            "Settings",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.settings, color: Colors.white),
            ),
            title: const Text("Group Settings"),
            subtitle: const Text("Manage SHG details and rules"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.security, color: Colors.white),
            ),
            title: const Text("Security"),
            subtitle: const Text("Password and authentication"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoggingOut ? null : _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: Text(
                _isLoggingOut ? "Logging out..." : "Logout",
                style: const TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTile(String title, IconData icon, _ReportType type) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title),
        trailing: _isGeneratingReport
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                tooltip: 'Generate and download $title',
                icon: const Icon(Icons.download),
                onPressed: () => _generateAndShowReport(type),
              ),
      ),
    );
  }
}
