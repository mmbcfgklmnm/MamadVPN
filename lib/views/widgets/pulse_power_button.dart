import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../services/vpn_core_service.dart';

class PulsePowerButton extends StatefulWidget {
  final VpnState state;
  final Duration connectedDuration;
  final VoidCallback onTap;

  const PulsePowerButton({
    super.key,
    required this.state,
    required this.connectedDuration,
    required this.onTap,
  });

  @override
  State<PulsePowerButton> createState() => _PulsePowerButtonState();
}

class _PulsePowerButtonState extends State<PulsePowerButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.stop();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = widget.state == VpnState.connected;
    final isConnecting = widget.state == VpnState.connecting;

    Color primaryGlowColor;
    if (isConnected) {
      primaryGlowColor = AppColors.connectedGreen;
    } else if (isConnecting) {
      primaryGlowColor = AppColors.connectingYellow;
    } else {
      primaryGlowColor = isDark ? AppColors.neonCyan : AppColors.lightPrimary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              final scale = (isConnected || isConnecting) ? _pulseAnimation.value : 1.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 175,
                  height: 175,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      // Outer ambient glow
                      BoxShadow(
                        color: primaryGlowColor.withOpacity(isConnected ? 0.35 : (isConnecting ? 0.25 : 0.1)),
                        blurRadius: isConnected ? 36 : 20,
                        spreadRadius: isConnected ? 6 : 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glowing border ring
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryGlowColor.withOpacity(isConnected ? 0.8 : 0.25),
                            width: isConnected ? 3.5 : 2,
                          ),
                          gradient: isConnected
                              ? SweepGradient(
                                  colors: [
                                    AppColors.connectedGreen,
                                    AppColors.neonCyan,
                                    AppColors.connectedGreen,
                                  ],
                                )
                              : null,
                        ),
                      ),

                      // Inner Button Surface
                      Container(
                        width: 145,
                        height: 145,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          gradient: isConnected
                              ? LinearGradient(
                                  colors: [
                                    AppColors.connectedGreen.withOpacity(0.18),
                                    isDark ? AppColors.darkSurface : Colors.white,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkCardBorder
                                : AppColors.lightCardBorder,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isConnecting
                              ? SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(primaryGlowColor),
                                  ),
                                )
                              : Icon(
                                  Icons.power_settings_new_rounded,
                                  size: 64,
                                  color: isConnected
                                      ? AppColors.connectedGreen
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightPrimary),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Status Text
        Text(
          _getStatusLabel(widget.state),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: primaryGlowColor,
          ),
        ),

        const SizedBox(height: 6),

        // Elapsed Duration
        if (isConnected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.connectedGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.connectedGreen.withOpacity(0.3)),
            ),
            child: Text(
              Formatters.formatDuration(widget.connectedDuration),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.connectedGreen,
                letterSpacing: 1.0,
              ),
            ),
          )
        else
          Text(
            widget.state == VpnState.connecting
                ? 'Establishing secure tunnel...'
                : 'Tap power icon to connect',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
      ],
    );
  }

  String _getStatusLabel(VpnState state) {
    switch (state) {
      case VpnState.connected:
        return 'CONNECTED';
      case VpnState.connecting:
        return 'CONNECTING...';
      case VpnState.disconnecting:
        return 'DISCONNECTING...';
      case VpnState.error:
        return 'CONNECTION FAILED';
      case VpnState.disconnected:
        return 'DISCONNECTED';
    }
  }
}
