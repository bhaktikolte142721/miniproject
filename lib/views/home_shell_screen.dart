import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../providers/alerts_provider.dart';
import '../providers/nurse_provider.dart';
import 'handover/shift_handover_screen.dart';
import 'ward_grid/multi_patient_grid_screen.dart';
import 'handover/schedule_handover_screen.dart';
import 'alerts/alerts_feed_screen.dart';
import 'patients/patient_admission_sheet.dart';
import 'settings/ward_settings_sheet.dart';

/// Central Shell Screen supporting both Desktop Workstation (Laptop) and Mobile viewports.
class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final criticalCount = ref.watch(activeCriticalAlarmsCountProvider);
    final activeNurse = ref.watch(activeNurseProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final List<Widget> screens = [
      ShiftHandoverScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const MultiPatientGridScreen(),
      const ScheduleHandoverScreen(),
      const AlertsFeedScreen(),
    ];

    if (isDesktop) {
      // Desktop / Laptop Workstation Multi-Column Layout
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
          ),
          child: Row(
            children: [
              // Left Clinical Navigation Sidebar (Workstation Rail)
              Container(
                width: 290,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  border: const Border(
                    right: BorderSide(color: AppColors.cardBorder, width: 1.5),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x08000000),
                      blurRadius: 20,
                      offset: Offset(4, 0),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Header
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/sentinel_shield_badge_3d.png',
                          width: 44,
                          height: 44,
                          errorBuilder: (_, __, ___) => Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.mintLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.shield_rounded, color: AppColors.primaryTeal),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SENTINEL-Ward',
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.mintLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Ward 3B Telemetry',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    Text(
                      'CLINICAL MODULES',
                      style: AppTextStyles.sectionLabel,
                    ),
                    const SizedBox(height: 10),

                    // Navigation Buttons
                    _buildSidebarNavItem(
                      icon: Icons.home_rounded,
                      label: 'Shift Overview',
                      index: 0,
                    ),
                    const SizedBox(height: 6),
                    _buildSidebarNavItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Live Ward Grid',
                      index: 1,
                    ),
                    const SizedBox(height: 6),
                    _buildSidebarNavItem(
                      icon: Icons.calendar_today_rounded,
                      label: 'Rounds Schedule',
                      index: 2,
                    ),
                    const SizedBox(height: 6),
                    _buildSidebarNavItem(
                      icon: Icons.notifications_rounded,
                      label: 'Active Alarms',
                      index: 3,
                      badgeCount: criticalCount > 0 ? '$criticalCount' : null,
                    ),

                    const SizedBox(height: 16),

                    // ─── Admit Patient Button ───────────────────────────
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => PatientAdmissionSheet.show(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            gradient: AppColors.mintTealGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [AppColors.clayPillShadow],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Admit Patient',
                                style: AppTextStyles.buttonText.copyWith(fontSize: 17),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ESP32 Hardware Status Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.alertStable,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ESP32-WARD-3B-GW',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                                Text(
                                  '3 Nodes Synchronized',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nurse Profile Card (Interactive: Click to change or register nurse)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => WardSettingsSheet.show(context, initialTab: 0),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.cardBorder),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.mintLight,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primaryMint, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  activeNurse.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryTeal,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeNurse.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${activeNurse.designation} • ${activeNurse.registrationNumber}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded, size: 18, color: AppColors.primaryTeal),
                                tooltip: 'Ward & Nurse Settings',
                                onPressed: () => WardSettingsSheet.show(context, initialTab: 1),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Expanded Viewport Area
              Expanded(
                child: Column(
                  children: [
                    // Emergency Bar if Critical
                    if (criticalCount > 0 && _currentIndex != 3)
                      GestureDetector(
                        onTap: () => setState(() => _currentIndex = 3),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          color: AppColors.alertCritical,
                          child: Row(
                            children: [
                              const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$criticalCount CRITICAL PHYSIOLOGICAL ALARM ACTIVE • BED 03 HYPOXEMIA',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text(
                                  'RESPOND TO ALARM',
                                  style: TextStyle(
                                    color: AppColors.alertCritical,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Active Screen Content with smooth 60fps fade+slide transition
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.012, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentIndex),
                          child: screens[_currentIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mobile Viewport with Floating Claymorphic Bottom Bar
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Active Screen with smooth transition and bottom inset
            Padding(
              padding: const EdgeInsets.only(bottom: 84),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.016, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_currentIndex),
                  child: screens[_currentIndex],
                ),
              ),
            ),

            // Top Persistent Emergency Alert Banner if Critical Alarms Active
            if (criticalCount > 0 && _currentIndex != 3)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.alertCritical,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.alertCritical.withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$criticalCount CRITICAL ALARM ACTIVE • BED 03 HYPOXIA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'RESPOND',
                            style: TextStyle(
                              color: AppColors.alertCritical,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Floating Bottom Navigation Bar ──────────────────────────────
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
                    BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 10, offset: Offset(-4, -4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(icon: Icons.home_rounded,           index: 0, tooltip: 'Home',      label: 'Home'),
                    _buildNavItem(icon: Icons.grid_view_rounded,      index: 1, tooltip: 'Ward',      label: 'Ward'),
                    // Add patient FAB center
                    GestureDetector(
                      onTap: () => PatientAdmissionSheet.show(context),
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: AppColors.mintTealGradient,
                          shape: BoxShape.circle,
                          boxShadow: [AppColors.clayPillShadow],
                        ),
                        child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                    _buildNavItem(icon: Icons.calendar_today_rounded, index: 2, tooltip: 'Rounds',    label: 'Rounds'),
                    _buildNavItem(
                      icon: Icons.notifications_rounded,
                      index: 3,
                      tooltip: 'Alarms',
                      label: 'Alarms',
                      badgeCount: criticalCount > 0 ? '$criticalCount' : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarNavItem({
    required IconData icon,
    required String label,
    required int index,
    String? badgeCount,
  }) {
    final isSelected = _currentIndex == index;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primaryMint : Colors.transparent,
              width: 1.4,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
                  ),
                ),
              ),
              if (badgeCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.alertCritical,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String tooltip,
    required String label,
    String? badgeCount,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintLight : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
                ),
                if (badgeCount != null)
                  Positioned(
                    top: -4,
                    right: -7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.alertCritical,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
