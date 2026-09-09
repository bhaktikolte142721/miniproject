import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/alerts_provider.dart';
import 'handover/shift_handover_screen.dart';
import 'ward_grid/multi_patient_grid_screen.dart';
import 'handover/schedule_handover_screen.dart';
import 'alerts/alerts_feed_screen.dart';

/// Central Shell Screen hosting the 3D claymorphic bottom navigation bar.
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

    final List<Widget> screens = [
      ShiftHandoverScreen(onNavigateTab: (index) => setState(() => _currentIndex = index)),
      const MultiPatientGridScreen(),
      const ScheduleHandoverScreen(),
      const AlertsFeedScreen(),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Stack(
          children: [
            // Active Screen
            IndexedStack(
              index: _currentIndex,
              children: screens,
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
                          color: AppColors.alertCritical.withOpacity(0.4),
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
                              fontSize: 12,
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
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Floating Claymorphic Bottom Navigation Bar matching Reference UI
            Positioned(
              left: 24,
              right: 24,
              bottom: 18,
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Color(0xE6FFFFFF),
                      blurRadius: 10,
                      offset: Offset(-4, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      index: 0,
                      tooltip: 'Home',
                    ),
                    _buildNavItem(
                      icon: Icons.grid_view_rounded,
                      index: 1,
                      tooltip: 'Ward Grid',
                    ),
                    _buildNavItem(
                      icon: Icons.calendar_today_rounded,
                      index: 2,
                      tooltip: 'Rounds',
                    ),
                    _buildNavItem(
                      icon: Icons.notifications_rounded,
                      index: 3,
                      tooltip: 'Alarms',
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

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String tooltip,
    String? badgeCount,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintLight : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
            ),
            if (badgeCount != null)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.alertCritical,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    badgeCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
