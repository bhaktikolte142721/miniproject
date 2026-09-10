import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/audio_alert_service.dart';
import '../../core/widgets/clay_button.dart';
import '../../core/widgets/clay_card.dart';
import '../../models/nurse.dart';
import '../../providers/nurse_provider.dart';

/// Modal bottom sheet for Ward Settings, Nurse Registration & Shift Management,
/// and Hardware Gateway Diagnostics.
class WardSettingsSheet extends ConsumerStatefulWidget {
  final int initialTab;

  const WardSettingsSheet({super.key, this.initialTab = 0});

  static Future<void> show(BuildContext context, {int initialTab = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WardSettingsSheet(initialTab: initialTab),
    );
  }

  @override
  ConsumerState<WardSettingsSheet> createState() => _WardSettingsSheetState();
}

class _WardSettingsSheetState extends ConsumerState<WardSettingsSheet> {
  late int _selectedTab;
  bool _showRegisterForm = false;

  // New Nurse Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _rnCtrl     = TextEditingController();
  final _roleCtrl   = TextEditingController(text: 'Staff Nurse');
  final _wardCtrl   = TextEditingController(text: 'Ward 3B Telemetry');
  String _shiftChoice = 'Morning (07:00 - 15:00)';

  static const _shifts = [
    'Morning (07:00 - 15:00)',
    'Evening (15:00 - 23:00)',
    'Night (23:00 - 07:00)',
  ];

  // Gateway Ping simulation state
  String _pingStatus = '';
  bool _isPinging = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rnCtrl.dispose();
    _roleCtrl.dispose();
    _wardCtrl.dispose();
    super.dispose();
  }

  void _submitNewNurse() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(nurseNotifierProvider.notifier).registerNurse(
      name: _nameCtrl.text.trim(),
      registrationNumber: _rnCtrl.text.trim(),
      designation: _roleCtrl.text.trim(),
      ward: _wardCtrl.text.trim(),
      shift: _shiftChoice,
      setOnDuty: true,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${_nameCtrl.text.trim()} successfully registered & set ON-DUTY!',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryTeal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    _nameCtrl.clear();
    _rnCtrl.clear();
    setState(() => _showRegisterForm = false);
  }

  void _testPingGateway() async {
    setState(() {
      _isPinging = true;
      _pingStatus = 'Pinging ESP32 Hub at 192.168.1.142:3000...';
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isPinging = false;
      _pingStatus = '✅ Gateway Online! Latency: 12ms • 6 nRF24 Pipes Active';
    });
  }

  void _testAlarmSound() {
    AudioAlertService().playWarningTone();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.volume_up_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text('Synthesized IEC 60601-1-8 test alarm chime!'),
          ],
        ),
        backgroundColor: AppColors.alertWarning,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeNurse = ref.watch(activeNurseProvider);
    final nursesList  = ref.watch(nurseNotifierProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Drag Handle ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ─── Sheet Header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryMint, width: 1.5),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: AppColors.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ward 3B Settings & Roster',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    Text(
                      'Nurse Identity • Shift Handover • Hardware Links',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ─── Segmented Tab Switcher ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    index: 0,
                    icon: Icons.badge_rounded,
                    label: 'Nurse Roster & Register',
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildTabButton(
                    index: 1,
                    icon: Icons.router_rounded,
                    label: 'Gateway & Hardware',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Scrollable Tab Content ──────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: _selectedTab == 0
                    ? _buildNurseTab(activeNurse, nursesList)
                    : _buildHardwareTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintLight : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryMint : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 1: NURSE ROSTER & REGISTRATION
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildNurseTab(Nurse activeNurse, List<Nurse> nursesList) {
    return Column(
      key: const ValueKey('nurse_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Active Nurse Card ────────────────────────────────────────────────
        Text(
          'CURRENTLY ON-DUTY NURSE',
          style: AppTextStyles.sectionLabel,
        ),
        const SizedBox(height: 8),
        ClayCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryMint, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F00B4D8),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  activeNurse.initials,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryTeal,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            activeNurse.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.fiber_manual_record, color: Color(0xFF2E7D32), size: 9),
                              SizedBox(width: 4),
                              Text(
                                'ON-DUTY',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${activeNurse.designation} • ${activeNurse.registrationNumber}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${activeNurse.ward} • Shift: ${activeNurse.shift}',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Shift Switch & Roster ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'REGISTERED WARD NURSES (${nursesList.length})',
              style: AppTextStyles.sectionLabel,
            ),
            TextButton.icon(
              onPressed: () => setState(() => _showRegisterForm = !_showRegisterForm),
              icon: Icon(
                _showRegisterForm ? Icons.remove_circle_outline : Icons.add_circle_outline_rounded,
                size: 16,
                color: AppColors.primaryTeal,
              ),
              label: Text(
                _showRegisterForm ? 'Hide Form' : '+ Register Nurse',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.primaryTeal,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Expandable Register New Nurse Form ──────────────────────────────
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _showRegisterForm ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: ClayCard(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_add_rounded, color: AppColors.primaryTeal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Register New Nurse to Ward Roster',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name Field
                  _buildFormField(
                    controller: _nameCtrl,
                    label: 'Full Name (with title)',
                    hint: 'e.g. Sister Meera Patel, RN',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter nurse name' : null,
                  ),
                  const SizedBox(height: 10),

                  // Registration / Staff ID
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          controller: _rnCtrl,
                          label: 'Registration / Staff ID',
                          hint: 'e.g. RN #92811',
                          icon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter RN number' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildFormField(
                          controller: _roleCtrl,
                          label: 'Designation / Role',
                          hint: 'e.g. Staff Nurse',
                          icon: Icons.medical_services_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Ward & Shift
                  Row(
                    children: [
                      Expanded(
                        child: _buildFormField(
                          controller: _wardCtrl,
                          label: 'Ward Department',
                          hint: 'Ward 3B Telemetry',
                          icon: Icons.local_hospital_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Assigned Shift',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _shiftChoice,
                                  isExpanded: true,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: _shifts.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                  onChanged: (v) {
                                    if (v != null) setState(() => _shiftChoice = v);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ClayButton(
                      label: 'Save & Set On-Duty Now ➔',
                      gradient: AppColors.mintTealGradient,
                      onPressed: _submitNewNurse,
                    ),
                  ),
                ],
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),

        const SizedBox(height: 10),

        // List of Registered Nurses
        ...nursesList.map((nurse) {
          final isCurrent = nurse.isOnDuty;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.mintLight : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent ? AppColors.primaryMint : AppColors.cardBorder,
                  width: isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: isCurrent ? AppColors.primaryTeal : const Color(0xFFECEFF1),
                    child: Text(
                      nurse.initials,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isCurrent ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nurse.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isCurrent ? AppColors.primaryTeal : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${nurse.designation} • ${nurse.registrationNumber} • ${nurse.shift}',
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (!isCurrent)
                    ElevatedButton(
                      onPressed: () {
                        ref.read(nurseNotifierProvider.notifier).switchOnDuty(nurse.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Switched shift on-duty nurse to ${nurse.name}'),
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primaryTeal,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mintLight,
                        foregroundColor: AppColors.primaryTeal,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppColors.primaryMint),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text(
                        'Set On-Duty',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal, size: 22),
                    ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 2: GATEWAY & HARDWARE SETTINGS
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildHardwareTab() {
    return Column(
      key: const ValueKey('hardware_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ESP32 CENTRAL RECEIVER HUB',
          style: AppTextStyles.sectionLabel,
        ),
        const SizedBox(height: 8),

        ClayCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.mintLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.router_rounded, color: AppColors.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESP32-WROOM-32 Gateway',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Endpoint: http://192.168.1.142:3000/api/telemetry/ingest',
                          style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_pingStatus.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _pingStatus.contains('✅') ? const Color(0xFFE8F5E9) : AppColors.mintLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _pingStatus,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _pingStatus.contains('✅') ? const Color(0xFF2E7D32) : AppColors.primaryTeal,
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPinging ? null : _testPingGateway,
                      icon: _isPinging
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find_rounded, size: 16),
                      label: Text(_isPinging ? 'Pinging...' : 'Test Gateway Ping'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryTeal,
                        side: const BorderSide(color: AppColors.primaryMint),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _testAlarmSound,
                      icon: const Icon(Icons.volume_up_rounded, size: 16),
                      label: const Text('Test Alarm Audio'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coralLight,
                        foregroundColor: AppColors.alertCritical,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppColors.alertCritical),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── nRF24 Radio Configuration Matrix ──────────────────────────────
        Text(
          'nRF24L01 2.4GHz MULTI-BED RADIO MATRIX',
          style: AppTextStyles.sectionLabel,
        ),
        const SizedBox(height: 8),

        ClayCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildConfigRow('Radio Channel', 'Channel 108 (2.508 GHz) • No Wi-Fi Clutter'),
              const Divider(height: 16),
              _buildConfigRow('Data Rate', '250 kbps (High Sensitivity Long Range)'),
              const Divider(height: 16),
              _buildConfigRow('Active Pipes', '6 Hardware Pipes (BED01 through BED06)'),
              const Divider(height: 16),
              _buildConfigRow('Sensors Bound', 'MAX30102 (HR/SpO2) + MAX30205 (Temp)'),
              const Divider(height: 16),
              _buildConfigRow('Battery Mode', 'Bench Testing (Nominal 100% Locked)'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ─── Clinical Alarm Thresholds ─────────────────────────────────────
        Text(
          'CLINICAL ALARM THRESHOLD MATRIX (IEC 60601-1-8)',
          style: AppTextStyles.sectionLabel,
        ),
        const SizedBox(height: 8),

        ClayCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildConfigRow('SpO2 Critical Alert', '< 90% (Immediate Code Escalation)'),
              const Divider(height: 16),
              _buildConfigRow('SpO2 Warning', '< 94% (Bedside Nurse Check)'),
              const Divider(height: 16),
              _buildConfigRow('Heart Rate Limits', 'Tachycardia > 120 BPM • Bradycardia < 50 BPM'),
              const Divider(height: 16),
              _buildConfigRow('Pyrexia Alert', 'Body Temp > 38.5°C (Febrile Protocol)'),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryTeal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 15, color: AppColors.textMuted),
            prefixIcon: Icon(icon, size: 18, color: AppColors.primaryTeal),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryMint, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
