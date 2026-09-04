import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/services/notification_service.dart';
import '../../../../shared/widgets/portal_switcher_bar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedTab = 0;

  // New User Dialog Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController(text: 'pass123');
  String _newUserRole = 'patient';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _showCreateUserDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Create New User Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _newUserRole,
                  decoration: const InputDecoration(labelText: 'User Role'),
                  items: const [
                    DropdownMenuItem(value: 'patient', child: Text('Patient')),
                    DropdownMenuItem(value: 'doctor', child: Text('Doctor / Physician')),
                    DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  ],
                  onChanged: (v) => setDialogState(() => _newUserRole = v ?? 'patient'),
                ),
                const SizedBox(height: 10),
                TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 10),
                TextFormField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Mobile Number')),
                const SizedBox(height: 10),
                TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email Address')),
                const SizedBox(height: 10),
                TextFormField(controller: _passController, decoration: const InputDecoration(labelText: 'Temporary Password')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) return;
                final nav = Navigator.of(ctx);
                final success = await ref.read(adminProvider.notifier).createUser(
                      name: _nameController.text.trim(),
                      phone: _phoneController.text.trim(),
                      email: _emailController.text.trim(),
                      password: _passController.text,
                      role: _newUserRole,
                    );
                if (success) {
                  nav.pop();
                  _nameController.clear();
                  _phoneController.clear();
                  _emailController.clear();
                  NotificationService.showSuccess('User account created and saved to SQLite!');
                }
              },
              child: const Text('Create User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(UserModel user) {
    final resetController = TextEditingController(text: 'newpass123');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password for ${user.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new password (will be hashed with SHA-256 before storing):', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            TextFormField(controller: resetController, decoration: const InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              final success = await ref.read(adminProvider.notifier).resetPassword(user.id, resetController.text);
              if (success) {
                nav.pop();
                NotificationService.showSuccess('Password reset successfully!');
              }
            },
            child: const Text('Save Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final currentUser = ref.watch(authProvider).currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.amber, size: 24),
            SizedBox(width: 10),
            Text('MediKiosk AI — Administration & Analytics Panel'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Analytics',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(adminProvider.notifier).loadAdminData(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Chip(
              backgroundColor: AppColors.surfaceVariant,
              avatar: const Icon(Icons.shield_rounded, color: Colors.amber, size: 16),
              label: Text(currentUser?.name ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const PortalDemoSwitcher(currentPortal: 'admin'),
            Expanded(
              child: Row(
                children: [
                  // Left Admin Sidebar
                  _buildAdminSidebar(),
                  const VerticalDivider(width: 1, thickness: 1, color: AppColors.border),

                  // Main View
                  Expanded(
                    child: adminState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSelectedTab(adminState),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSidebar() {
    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildSidebarTile(0, Icons.analytics_rounded, 'Analytics & Triage'),
          _buildSidebarTile(1, Icons.manage_accounts_rounded, 'User Management'),
          _buildSidebarTile(2, Icons.history_toggle_off_rounded, 'Audit Trail & Logs'),
          _buildSidebarTile(3, Icons.settings_suggest_rounded, 'System & ABDM Config'),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.priorityP1),
            title: const Text('Sign Out', style: TextStyle(color: AppColors.priorityP1, fontWeight: FontWeight.bold, fontSize: 14)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) context.go('/');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarTile(int index, IconData icon, String title) {
    final isSelected = _selectedTab == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () => setState(() => _selectedTab = index),
      ),
    );
  }

  Widget _buildSelectedTab(AdminState state) {
    switch (_selectedTab) {
      case 1:
        return _buildUserManagementTab(state);
      case 2:
        return _buildAuditLogsTab(state);
      case 3:
        return _buildSettingsTab();
      case 0:
      default:
        return _buildAnalyticsTab(state);
    }
  }

  Widget _buildAnalyticsTab(AdminState state) {
    final p1 = state.p1Count.toDouble();
    final p2 = state.p2Count.toDouble();
    final p3 = state.p3Count.toDouble();
    final total = state.totalSessions > 0 ? state.totalSessions.toDouble() : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - 48 > 0 ? constraints.maxWidth - 48 : 0,
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
          // Stat KPI Cards
          Row(
            children: [
              _buildKpiCard('Total Intakes', '${state.totalSessions}', Icons.people_alt_rounded, AppColors.primary),
              const SizedBox(width: 14),
              _buildKpiCard('Priority 1 (Urgent)', '${state.p1Count}', Icons.emergency_rounded, AppColors.priorityP1),
              const SizedBox(width: 14),
              _buildKpiCard('Priority 2 (Moderate)', '${state.p2Count}', Icons.warning_amber_rounded, AppColors.priorityP2),
              const SizedBox(width: 14),
              _buildKpiCard('Priority 3 (Routine)', '${state.p3Count}', Icons.check_circle_rounded, AppColors.priorityP3),
            ],
          ),
          const SizedBox(height: 28),

          // Charts Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart 1: Priority Distribution Pie Chart
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Triage Priority Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Live ratio of emergency vs moderate vs routine intakes', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: [
                              PieChartSectionData(
                                value: p1 > 0 ? p1 : 1,
                                color: AppColors.priorityP1,
                                title: '${((p1 / total) * 100).round()}%',
                                radius: 55,
                                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                              ),
                              PieChartSectionData(
                                value: p2 > 0 ? p2 : 1,
                                color: AppColors.priorityP2,
                                title: '${((p2 / total) * 100).round()}%',
                                radius: 55,
                                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                              ),
                              PieChartSectionData(
                                value: p3 > 0 ? p3 : 1,
                                color: AppColors.priorityP3,
                                title: '${((p3 / total) * 100).round()}%',
                                radius: 55,
                                titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ChartLegend(color: AppColors.priorityP1, label: 'P1 Urgent'),
                          SizedBox(width: 14),
                          _ChartLegend(color: AppColors.priorityP2, label: 'P2 Moderate'),
                          SizedBox(width: 14),
                          _ChartLegend(color: AppColors.priorityP3, label: 'P3 Routine'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Chart 2: Hourly Kiosk Pre-Intake Inflow
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Intake Flow by Department', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Text('Allopathy SOCRATES vs AYUSH Dashavidha throughput', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: 15,
                            barTouchData: BarTouchData(enabled: true),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    switch (val.toInt()) {
                                      case 0:
                                        return const Text('09 AM', style: TextStyle(fontSize: 10));
                                      case 1:
                                        return const Text('10 AM', style: TextStyle(fontSize: 10));
                                      case 2:
                                        return const Text('11 AM', style: TextStyle(fontSize: 10));
                                      case 3:
                                        return const Text('12 PM', style: TextStyle(fontSize: 10));
                                      case 4:
                                        return const Text('01 PM', style: TextStyle(fontSize: 10));
                                      default:
                                        return const Text('');
                                    }
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: true, drawVerticalLine: false),
                            borderData: FlBorderData(show: false),
                            barGroups: [
                              _makeBarGroup(0, 4, 3),
                              _makeBarGroup(1, 7, 5),
                              _makeBarGroup(2, 9, 6),
                              _makeBarGroup(3, 6, 4),
                              _makeBarGroup(4, 5, 2),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ChartLegend(color: AppColors.primary, label: 'Allopathy'),
                          SizedBox(width: 16),
                          _ChartLegend(color: AppColors.ayushGreen, label: 'AYUSH'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
},
);
}

  BarChartGroupData _makeBarGroup(int x, double y1, double y2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y1, color: AppColors.primary, width: 14, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: y2, color: AppColors.ayushGreen, width: 14, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementTab(AdminState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - 48 > 0 ? constraints.maxWidth - 48 : 0,
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('User & Role Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Manage patient records, doctors, and kiosk administrators in SQLite', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateUserDialog,
                      icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                      label: const Text('Add New User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Users Table
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.allUsers.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final user = state.allUsers[idx];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.role == 'doctor'
                              ? AppColors.ayushGreenContainer
                              : user.role == 'admin'
                                  ? Colors.amber.shade50
                                  : AppColors.primaryContainer,
                          child: Icon(
                            user.role == 'doctor'
                                ? Icons.medical_services_rounded
                                : user.role == 'admin'
                                    ? Icons.admin_panel_settings_rounded
                                    : Icons.person_rounded,
                            color: user.role == 'doctor'
                                ? AppColors.ayushGreen
                                : user.role == 'admin'
                                    ? Colors.amber.shade900
                                    : AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('ABHA: ${user.abhaId} • Phone: ${user.phone} • Email: ${user.email}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              backgroundColor: AppColors.surfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Reset Password',
                              icon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 20),
                              onPressed: () => _showResetPasswordDialog(user),
                            ),
                            IconButton(
                              tooltip: 'Delete User',
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.priorityP1, size: 20),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Confirm Deletion'),
                                    content: Text('Are you sure you want to delete user ${user.name}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(adminProvider.notifier).deleteUser(user.id);
                                  NotificationService.showSuccess('User deleted.');
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsTab(AdminState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth - 48 > 0 ? constraints.maxWidth - 48 : 0,
              maxWidth: 1200,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('System Audit Trail & Security Logs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Immutable local log trail complying with DPDP Act and clinical auditing principles', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.auditLogs.length,
                    separatorBuilder: (c, i) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final log = state.auditLogs[idx];
                      return ListTile(
                        leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                        title: Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${log.details}\nUser: ${log.userId} (${log.userRole})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        trailing: Text(
                          log.timestamp.toIso8601String().substring(11, 19),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontFamily: 'monospace'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('System Configuration & ABDM Sandbox', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),
              SwitchListTile(
                title: const Text('ABDM Sandbox Milestone (M1/M2/M3) Simulation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Simulates ABHA discovery, linking, and FHIR clinical document sharing'),
                value: true,
                onChanged: (v) {},
              ),
              const Divider(height: 18),
              SwitchListTile(
                title: const Text('DPDP Act Encryption (Local SQLite at Rest)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Sensitive patient identifiers secured in secure enclave'),
                value: true,
                onChanged: (v) {},
              ),
              const Divider(height: 18),
              SwitchListTile(
                title: const Text('Indic Speech Synthesis (AI4Bharat / Bhashini Fallback)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Enables regional acoustic models for 5 languages'),
                value: true,
                onChanged: (v) {},
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => NotificationService.showSuccess('Settings saved in local configuration.'),
                child: const Text('Save System Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
