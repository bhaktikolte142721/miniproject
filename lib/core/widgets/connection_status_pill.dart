import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../../providers/telemetry_mode_provider.dart';
import '../../services/socket_service.dart';

/// Interactive clinical status chip displaying data source mode (Live vs. Simulation)
/// and real-time backend connection status. Tapping allows changing backend host IP.
class ConnectionStatusPill extends ConsumerWidget {
  const ConnectionStatusPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modeState = ref.watch(telemetryModeProvider);

    Color bg;
    Color fg;
    IconData icon;
    String label;

    if (modeState.isSimulation) {
      bg = const Color(0xFFF3E5F5); // Soft Purple
      fg = const Color(0xFF7B1FA2);
      icon = Icons.science_rounded;
      label = 'SIMULATION';
    } else {
      switch (modeState.connectionStatus) {
        case SocketConnectionStatus.connected:
          bg = const Color(0xFFE8F5E9); // Soft Green
          fg = const Color(0xFF2E7D32);
          icon = Icons.sensors_rounded;
          label = 'LIVE GATEWAY';
          break;
        case SocketConnectionStatus.connecting:
          bg = const Color(0xFFFFF8E1); // Soft Amber
          fg = const Color(0xFFF57F17);
          icon = Icons.sync_rounded;
          label = 'CONNECTING...';
          break;
        case SocketConnectionStatus.error:
        case SocketConnectionStatus.disconnected:
          bg = const Color(0xFFFFEBEE); // Soft Red
          fg = const Color(0xFFC62828);
          icon = Icons.cloud_off_rounded;
          label = 'SERVER OFFLINE';
          break;
      }
    }

    return GestureDetector(
      onTap: () => _showSettingsModal(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: fg.withValues(alpha: 0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: fg.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.badgeText.copyWith(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.arrow_drop_down_rounded, color: fg, size: 16),
          ],
        ),
      ),
    );
  }

  void _showSettingsModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _TelemetrySourceModal(),
    );
  }
}

class _TelemetrySourceModal extends ConsumerStatefulWidget {
  const _TelemetrySourceModal();

  @override
  ConsumerState<_TelemetrySourceModal> createState() => _TelemetrySourceModalState();
}

class _TelemetrySourceModalState extends ConsumerState<_TelemetrySourceModal> {
  late TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final modeState = ref.read(telemetryModeProvider);
    _urlController = TextEditingController(text: modeState.serverUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modeState = ref.watch(telemetryModeProvider);
    final notifier = ref.read(telemetryModeProvider.notifier);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Modal Title
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.mintLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.hub_rounded, color: AppColors.primaryTeal, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Telemetry Data Source',
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Toggle between offline simulation and live Node.js gateway',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mode Selection Segmented Cards
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  title: 'Simulation',
                  subtitle: 'Offline Demo (No Server)',
                  icon: Icons.science_rounded,
                  isSelected: modeState.isSimulation,
                  activeColor: const Color(0xFF7B1FA2),
                  onTap: () {
                    notifier.setMode(TelemetrySourceMode.simulation);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  title: 'Live Gateway',
                  subtitle: 'Node.js Socket.IO',
                  icon: Icons.wifi_tethering_rounded,
                  isSelected: modeState.isLive,
                  activeColor: AppColors.primaryTeal,
                  onTap: () {
                    notifier.setMode(TelemetrySourceMode.live);
                  },
                ),
              ),
            ],
          ),

          if (modeState.isLive) ...[
            const SizedBox(height: 20),
            Text(
              'BACKEND SERVER URL (HTTP/WS)',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Server URL Input Field
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'http://192.168.1.142:3000',
                prefixIcon: const Icon(Icons.link_rounded, size: 20, color: AppColors.primaryTeal),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryTeal),
                  onPressed: () {
                    notifier.setServerUrl(_urlController.text);
                    FocusScope.of(context).unfocus();
                  },
                ),
                filled: true,
                fillColor: AppColors.bgStart,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryMint, width: 1.6),
                ),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),

            // Quick Host Preset Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildQuickPreset('Android Emulator', 'http://10.0.2.2:3000', notifier),
                _buildQuickPreset('Localhost', 'http://localhost:3000', notifier),
                _buildQuickPreset('WiFi LAN', 'http://192.168.1.142:3000', notifier),
              ],
            ),
            const SizedBox(height: 16),

            // Live Connection Status Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: modeState.isConnected
                    ? const Color(0xFFE8F5E9)
                    : (modeState.isConnecting ? const Color(0xFFFFF8E1) : const Color(0xFFFFEBEE)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    modeState.isConnected
                        ? Icons.check_circle_rounded
                        : (modeState.isConnecting ? Icons.sync_rounded : Icons.error_outline_rounded),
                    size: 18,
                    color: modeState.isConnected
                        ? const Color(0xFF2E7D32)
                        : (modeState.isConnecting ? const Color(0xFFF57F17) : const Color(0xFFC62828)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      modeState.isConnected
                          ? 'Connected to Socket.IO telemetry stream!'
                          : (modeState.isConnecting
                              ? 'Connecting to ${modeState.serverUrl}...'
                              : 'Cannot connect. Ensure backend is running.'),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: modeState.isConnected
                            ? const Color(0xFF2E7D32)
                            : (modeState.isConnecting ? const Color(0xFFF57F17) : const Color(0xFFC62828)),
                      ),
                    ),
                  ),
                  if (!modeState.isConnected)
                    TextButton(
                      onPressed: () => notifier.reconnect(),
                      child: const Text('RETRY'),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                if (modeState.isLive) {
                  notifier.setServerUrl(_urlController.text);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save & Apply', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPreset(String label, String url, TelemetryModeNotifier notifier) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: AppColors.chipInactive,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        _urlController.text = url;
        notifier.setServerUrl(url);
      },
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.08) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.cardBorder,
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: isSelected ? activeColor : AppColors.textSecondary, size: 22),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: activeColor, size: 18),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: AppTextStyles.titleSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected ? activeColor : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
