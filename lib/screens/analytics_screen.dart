import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../sql_helper/database_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  TaskAnalytics? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      String? ownerUid;
      int? assigneeId;
      if (firebaseUser != null) {
        ownerUid = firebaseUser.uid;
      } else {
        final local = await DatabaseHelper.getCurrentUser();
        assigneeId = local != null ? local['id'] as int? : null;
      }

      final stats = await DatabaseHelper.getTaskStats(
        ownerUid: ownerUid,
        assigneeId: assigneeId,
      );

      setState(() {
        _analytics = TaskAnalytics(
          totalTasks: stats['total'] ?? 0,
          completedTasks: stats['completed'] ?? 0,
          taskHistory: [], // TODO: Implement task history
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Task Analytics',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
          ? const Center(child: Text('No data available'))
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCompletionRate(),
                    const SizedBox(height: 24),
                    _buildProductivityChart(),
                    const SizedBox(height: 24),
                    _buildTaskBreakdown(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCompletionRate() {
    final completionRate =
        _analytics!.completedTasks / _analytics!.totalTasks * 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Completion Rate',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _analytics!.completedTasks / _analytics!.totalTasks,
              backgroundColor: Colors.grey[200],
              minHeight: 10,
            ),
            const SizedBox(height: 8),
            Text(
              '${completionRate.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Progress',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  // Chart configuration would go here
                  // This is a placeholder for actual data visualization
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Breakdown',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildBreakdownItem(
              label: 'Completed Tasks',
              count: _analytics!.completedTasks,
              color: Colors.green,
            ),
            const SizedBox(height: 8),
            _buildBreakdownItem(
              label: 'Pending Tasks',
              count: _analytics!.totalTasks - _analytics!.completedTasks,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem({
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: GoogleFonts.poppins(fontSize: 16)),
        const Spacer(),
        Text(
          count.toString(),
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class TaskAnalytics {
  final int totalTasks;
  final int completedTasks;
  final List<Map<String, dynamic>> taskHistory;

  TaskAnalytics({
    required this.totalTasks,
    required this.completedTasks,
    required this.taskHistory,
  });
}
