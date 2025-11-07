import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sql_helper/database_helper.dart';

class TaskSummary {
  final int total;
  final int completed;
  final int pending;
  final int overdue;

  TaskSummary({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
  });
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _auth = FirebaseAuth.instance;
  TaskSummary? _taskSummary;
  List<Map<String, dynamic>> _recentTasks = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final firebaseUser = _auth.currentUser;
      String? ownerUid;
      int? assigneeId;
      if (firebaseUser != null) {
        ownerUid = firebaseUser.uid;
      } else {
        final local = await DatabaseHelper.getCurrentUser();
        assigneeId = local != null ? local['id'] as int? : null;
      }

      final stats = await DatabaseHelper.getTaskStats(ownerUid: ownerUid);
      final tasks = await DatabaseHelper.getTasks(
        ownerUid: ownerUid,
        assigneeId: ownerUid == null ? assigneeId : null,
      );

      if (!mounted) return;

      setState(() {
        _taskSummary = TaskSummary(
          total: stats["total"] ?? 0,
          completed: stats["completed"] ?? 0,
          pending: stats["total"] - (stats["completed"] ?? 0),
          overdue: stats["overdue"] ?? 0,
        );

        _recentTasks = List.from(tasks)
          ..sort((a, b) {
            final aDate =
                DateTime.tryParse(a["dueDate"] ?? "") ?? DateTime.now();
            final bDate =
                DateTime.tryParse(b["dueDate"] ?? "") ?? DateTime.now();
            return bDate.compareTo(aDate);
          })
          ..take(5); // Limit to 5 most recent tasks
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error loading dashboard data: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildDashboardGrid(),
                const SizedBox(height: 30),
                _buildProgressSection(),
                _buildRecentActivity(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final user = _auth.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome to your Dashboard",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        if (user != null) ...[
          const SizedBox(height: 8),
          Text(
            user.email ?? "User",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDashboardGrid() {
    if (_taskSummary == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 20,
      mainAxisSpacing: 20,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: "Total Tasks",
          value: _taskSummary!.total.toString(),
          icon: FontAwesomeIcons.listCheck,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: "Completed",
          value: _taskSummary!.completed.toString(),
          icon: FontAwesomeIcons.circleCheck,
          color: Colors.green,
        ),
        _buildStatCard(
          title: "Pending",
          value: _taskSummary!.pending.toString(),
          icon: FontAwesomeIcons.clockRotateLeft,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: "Overdue",
          value: _taskSummary!.overdue.toString(),
          icon: FontAwesomeIcons.circleExclamation,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    if (_taskSummary == null || _taskSummary!.total == 0) {
      return Container();
    }

    final completionPercentage =
        (_taskSummary!.completed / _taskSummary!.total * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Overall Progress",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: _taskSummary!.completed / _taskSummary!.total,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: completionPercentage == 100
                        ? Colors.green
                        : Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "$completionPercentage% Complete",
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    if (_recentTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FontAwesomeIcons.listCheck, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No tasks yet",
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Tasks",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            TextButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(FontAwesomeIcons.arrowsRotate, size: 14),
              label: Text(
                "Refresh",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentTasks.length.clamp(0, 5),
          itemBuilder: (context, index) {
            final task = _recentTasks[index];
            final isCompleted = task["status"] == 2;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(26),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withAlpha(26)
                          : Colors.orange.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCompleted
                          ? FontAwesomeIcons.checkDouble
                          : FontAwesomeIcons.hourglassHalf,
                      size: 16,
                      color: isCompleted ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task["title"] ?? "Untitled Task",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCompleted
                                ? Colors.grey[600]
                                : Colors.grey[800],
                          ),
                        ),
                        if (task["dueDate"] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            "Due: ${_formatDate(task["dueDate"])}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    FontAwesomeIcons.chevronRight,
                    size: 14,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final taskDate = DateTime(date.year, date.month, date.day);

      if (taskDate == today) {
        return "Today";
      } else if (taskDate == today.add(const Duration(days: 1))) {
        return "Tomorrow";
      } else if (taskDate == today.subtract(const Duration(days: 1))) {
        return "Yesterday";
      } else {
        return "${date.day}/${date.month}/${date.year}";
      }
    } catch (e) {
      return "Invalid date";
    }
  }
}
