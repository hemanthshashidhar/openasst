import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'memory/database.dart';
import 'settings/settings_screen.dart';
import 'settings/document_screen.dart';
import 'settings/telegram_screen.dart';
import 'overlay/chat_overlay.dart';
import 'overlay/bubble_entry.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';

// Entry point for the main app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize local database
  await OrbDatabase.instance.init();

  runApp(const OrbApp());
}

// Entry point when overlay is triggered
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrbOverlayEntry());
}

class OrbApp extends StatefulWidget {
  const OrbApp({super.key});

  @override
  State<OrbApp> createState() => _OrbAppState();
}

class _OrbAppState extends State<OrbApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ORB',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const OrbHomeScreen(),
    );
  }
}

class OrbHomeScreen extends StatefulWidget {
  const OrbHomeScreen({super.key});

  @override
  State<OrbHomeScreen> createState() => _OrbHomeScreenState();
}

class _OrbHomeScreenState extends State<OrbHomeScreen>
    with SingleTickerProviderStateMixin {
  bool _overlayActive = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _checkOverlayStatus();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkOverlayStatus() async {
    final active = await FlutterOverlayWindow.isActive();
    if (mounted) setState(() => _overlayActive = active);
  }

  Future<void> _toggleOverlay() async {
    // Check overlay permission first
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
      return;
    }

    if (_overlayActive) {
      await FlutterOverlayWindow.closeOverlay();
      setState(() => _overlayActive = false);
    } else {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        overlayTitle: "ORB Assistant",
        overlayContent: "ORB is active",
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        positionGravity: PositionGravity.auto,
        height: Constants.bubbleSize.toInt(),
        width: Constants.bubbleSize.toInt(),
        startPosition: const OverlayPosition(0, 150),
      );
      setState(() => _overlayActive = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ORB',
                        style: AppTheme.headlineStyle.copyWith(fontSize: 32),
                      ),
                      Text(
                        'On-screen Reasoning Brain',
                        style: AppTheme.captionStyle,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: AppTheme.accentColor),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Main ORB visual
            Center(
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _overlayActive ? _pulseAnimation.value : 1.0,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: _toggleOverlay,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: _overlayActive
                                ? [
                                    AppTheme.accentColor,
                                    AppTheme.accentColor.withOpacity(0.3),
                                  ]
                                : [
                                    AppTheme.surfaceColor,
                                    AppTheme.bgColor,
                                  ],
                          ),
                          boxShadow: _overlayActive
                              ? [
                                  BoxShadow(
                                    color:
                                        AppTheme.accentColor.withOpacity(0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  )
                                ],
                          border: Border.all(
                            color: _overlayActive
                                ? AppTheme.accentColor
                                : AppTheme.accentColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '◉',
                            style: TextStyle(
                              fontSize: 60,
                              color: _overlayActive
                                  ? Colors.white
                                  : AppTheme.accentColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _overlayActive ? 'ORB is active' : 'Tap to summon ORB',
                    style: AppTheme.bodyStyle.copyWith(
                      color: _overlayActive
                          ? AppTheme.accentColor
                          : AppTheme.subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _overlayActive
                        ? 'Floating on your screen'
                        : 'ORB will float over all your apps',
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Quick stats / info cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _InfoCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Open Chat',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: AppTheme.bgColor,
                          appBar: AppBar(title: const Text('Chat with ORB')),
                          body: ChatOverlay(onClose: () => Navigator.pop(context)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _InfoCard(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Documents',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DocumentScreen()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _InfoCard(
                    icon: Icons.telegram,
                    label: 'Telegram',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TelegramScreen()),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentColor.withOpacity(0.15),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.accentColor, size: 22),
              const SizedBox(height: 6),
              Text(label, style: AppTheme.captionStyle),
            ],
          ),
        ),
      ),
    );
  }
}