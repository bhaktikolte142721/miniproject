import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/clay_button.dart';
import '../home_shell_screen.dart';
import '../settings/ward_settings_sheet.dart';
import '../ward_grid/node_health_sheet.dart';

/// SENTINEL-Ward Award-Winning Hero Landing Page.
/// Features a glowing 3D heartbeat centerpiece with floating telemetry orbs,
/// live statistics strip, and smooth 60fps micro-animations.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _heartScale;
  late final Animation<double> _outerRipple;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _heartScale = Tween<double>(begin: 0.94, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutCubic),
    );

    _outerRipple = Tween<double>(begin: 0.85, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _enterWard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const HomeShellScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesk = size.width >= 850;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F7F6), // soft medical mint
              Color(0xFFE0F2F7), // cyan glow
              Color(0xFFEDEBF9), // soft lavender
              Color(0xFFF7EDF5), // rose mist
            ],
            stops: [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient Glowing Medical Orbs (Background Accents)
              Positioned(
                top: -80,
                left: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryMint.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                right: -60,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF00E5FF).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main Column
              Column(
                children: [
                  // 1. Top Navigation Bar
                  _TopNavBar(
                    isDesk: isDesk,
                    onOpenSettings: () => WardSettingsSheet.show(context),
                  ),

                  // 2. Main Hero Viewport
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesk ? 56 : 22,
                        vertical: 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Column(
                            children: [
                              if (isDesk)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Left: 3D Pulsing Organ Centerpiece
                                    Expanded(
                                      flex: 5,
                                      child: _HeroVisual(
                                        heartScale: _heartScale,
                                        outerRipple: _outerRipple,
                                      ),
                                    ),
                                    const SizedBox(width: 48),
                                    // Right: Typography & CTA
                                    Expanded(
                                      flex: 6,
                                      child: _HeroContent(
                                        isDesk: true,
                                        onStart: _enterWard,
                                        onOpenNodes: () => NodeHealthSheet.show(context),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    _HeroVisual(
                                      heartScale: _heartScale,
                                      outerRipple: _outerRipple,
                                      maxSize: (size.width * 0.75).clamp(220.0, 310.0),
                                    ),
                                    const SizedBox(height: 28),
                                    _HeroContent(
                                      isDesk: false,
                                      onStart: _enterWard,
                                      onOpenNodes: () => NodeHealthSheet.show(context),
                                    ),
                                  ],
                                ),

                              const SizedBox(height: 38),

                              // 3. Stats & Capabilities Strip
                              _CapabilitiesStrip(isDesk: isDesk),
                              const SizedBox(height: 28),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP NAVIGATION BAR
// ─────────────────────────────────────────────────────────────────────────────
class _TopNavBar extends StatelessWidget {
  final bool isDesk;
  final VoidCallback onOpenSettings;

  const _TopNavBar({required this.isDesk, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesk ? 48 : 20,
        vertical: 14,
      ),
      child: Row(
        children: [
          // Logo Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: AppColors.mintTealGradient,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMint.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SENTINEL-Ward',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primaryTeal,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Text(
                      'IoT Clinical Telemetry v2.4',
                      style: TextStyle(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Live Ward Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF81C784), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fiber_manual_record, color: Color(0xFF2E7D32), size: 10),
                SizedBox(width: 6),
                Text(
                  'WARD 3B • 6 BEDS READY',
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Nurse Shift / Settings Action
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenSettings,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.mintTealGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryTeal.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Staff Sign-In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3D PULSING ORGAN CENTERPIECE WITH FLOATING TELEMETRY BADGES
// ─────────────────────────────────────────────────────────────────────────────
class _HeroVisual extends StatelessWidget {
  final Animation<double> heartScale;
  final Animation<double> outerRipple;
  final double maxSize;

  const _HeroVisual({
    required this.heartScale,
    required this.outerRipple,
    this.maxSize = 400,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: heartScale,
      builder: (_, __) {
        return SizedBox(
          width: maxSize,
          height: maxSize,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer Glowing Expansion Wave
              Transform.scale(
                scale: outerRipple.value,
                child: Container(
                  width: maxSize * 0.78,
                  height: maxSize * 0.78,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryMint.withValues(alpha: 0.25),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMint.withValues(alpha: 0.15),
                        blurRadius: 36,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Mid Frosted Aura Ring
              Transform.scale(
                scale: heartScale.value * 0.98,
                child: Container(
                  width: maxSize * 0.65,
                  height: maxSize * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.45),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00BFA5).withValues(alpha: 0.20),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
              ),

              // 3D Clay Heart Centerpiece
              Transform.scale(
                scale: heartScale.value,
                child: Image.asset(
                  'assets/images/vital_heart_3d.png',
                  width: maxSize * 0.82,
                  height: maxSize * 0.82,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: maxSize * 0.6,
                    height: maxSize * 0.6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mintLight,
                    ),
                    child: const Icon(Icons.favorite_rounded, size: 80, color: AppColors.primaryMint),
                  ),
                ),
              ),

              // Floating Badge 1: Heart Rate (Top-Right)
              Positioned(
                top: maxSize * 0.04,
                right: -10,
                child: _HeroOrbBadge(
                  icon: '🫀',
                  value: '72 BPM',
                  subtitle: 'Sinus Rhythm',
                  accentColor: const Color(0xFFFF5252),
                ),
              ),

              // Floating Badge 2: SpO2 (Top-Left)
              Positioned(
                top: maxSize * 0.12,
                left: -14,
                child: _HeroOrbBadge(
                  icon: '🫁',
                  value: '99% SpO₂',
                  subtitle: 'Optimal Saturation',
                  accentColor: const Color(0xFF00C853),
                ),
              ),

              // Floating Badge 3: Body Temperature (Bottom-Left)
              Positioned(
                bottom: maxSize * 0.08,
                left: -6,
                child: _HeroOrbBadge(
                  icon: '🌡️',
                  value: '36.8°C',
                  subtitle: 'MAX30205 Clinical',
                  accentColor: const Color(0xFF00838F),
                ),
              ),

              // Floating Badge 4: Radio Mesh (Bottom-Right)
              Positioned(
                bottom: maxSize * 0.04,
                right: -14,
                child: _HeroOrbBadge(
                  icon: '📡',
                  value: '-56 dBm',
                  subtitle: 'nRF24 6-Node Link',
                  accentColor: const Color(0xFF0288D1),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroOrbBadge extends StatelessWidget {
  final String icon;
  final String value;
  final String subtitle;
  final Color accentColor;

  const _HeroOrbBadge({
    required this.icon,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.35), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          const BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 8, offset: Offset(-2, -2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO TYPOGRAPHY & CALL TO ACTION
// ─────────────────────────────────────────────────────────────────────────────
class _HeroContent extends StatelessWidget {
  final bool isDesk;
  final VoidCallback onStart;
  final VoidCallback onOpenNodes;

  const _HeroContent({
    required this.isDesk,
    required this.onStart,
    required this.onOpenNodes,
  });

  @override
  Widget build(BuildContext context) {
    final align = isDesk ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = isDesk ? TextAlign.left : TextAlign.center;

    return Column(
      crossAxisAlignment: align,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pill Tagline
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE0F2F1), Color(0xFFE1F5FE)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primaryTeal),
              const SizedBox(width: 6),
              Text(
                'NEXT-GEN 2.4GHz WIRELESS WARD TELEMETRY',
                style: AppTextStyles.badgeText.copyWith(
                  color: AppColors.primaryTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isDesk ? 20 : 16),

        // Bold Headline
        Text(
          'Real-Time Patient Vitals.\nZero Alarm Delay.',
          textAlign: textAlign,
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: isDesk ? 52 : 36,
            fontWeight: FontWeight.w900,
            height: 1.12,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: isDesk ? 18 : 12),

        // Subtitle
        Text(
          'Autonomous multi-patient telemetry linking Arduino Pro Mini bedside sensors directly to an ESP32 central gateway and nursing consoles. Verified with IEC 60601-1-8 medical alarm sound standards.',
          textAlign: textAlign,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            fontSize: isDesk ? 17 : 15,
            height: 1.6,
          ),
        ),
        SizedBox(height: isDesk ? 32 : 24),

        // Action Buttons Row
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: isDesk ? WrapAlignment.start : WrapAlignment.center,
          children: [
            SizedBox(
              height: 52,
              child: ClayButton(
                label: 'Launch Nursing Station ➔',
                gradient: AppColors.mintTealGradient,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                onPressed: onStart,
              ),
            ),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onOpenNodes,
                icon: const Icon(Icons.sensors_rounded, size: 18),
                label: const Text(
                  'Hardware Diagnostics',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryTeal,
                  side: const BorderSide(color: AppColors.primaryMint, width: 1.6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAPABILITIES STRIP (4 METRICS)
// ─────────────────────────────────────────────────────────────────────────────
class _CapabilitiesStrip extends StatelessWidget {
  final bool isDesk;
  const _CapabilitiesStrip({required this.isDesk});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      {'title': '6 Beds', 'subtitle': 'Concurrent Radio Mesh', 'icon': Icons.hub_rounded, 'color': AppColors.primaryTeal},
      {'title': '< 15 ms', 'subtitle': 'Gateway Telemetry Latency', 'icon': Icons.speed_rounded, 'color': const Color(0xFF0288D1)},
      {'title': 'IEC 60601', 'subtitle': 'Clinical Alarm Escalation', 'icon': Icons.notifications_active_rounded, 'color': AppColors.alertCritical},
      {'title': '99.8%', 'subtitle': 'RF Packet Integrity Rate', 'icon': Icons.verified_user_rounded, 'color': const Color(0xFF00C853)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, 8)),
          BoxShadow(color: Color(0xE6FFFFFF), blurRadius: 10, offset: Offset(-3, -3)),
        ],
      ),
      child: isDesk
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: metrics.map((m) => _buildMetricItem(m)).toList(),
            )
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceAround,
              children: metrics.map((m) => SizedBox(width: 140, child: _buildMetricItem(m))).toList(),
            ),
    );
  }

  Widget _buildMetricItem(Map<String, dynamic> m) {
    final Color color = m['color'] as Color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(m['icon'] as IconData, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              m['title'] as String,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              m['subtitle'] as String,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
