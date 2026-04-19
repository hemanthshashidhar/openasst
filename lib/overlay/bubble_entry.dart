import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'chat_overlay.dart';

class OrbOverlayEntry extends StatefulWidget {
  const OrbOverlayEntry({super.key});
  @override
  State<OrbOverlayEntry> createState() => _OrbOverlayEntryState();
}

class _OrbOverlayEntryState extends State<OrbOverlayEntry>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 350), vsync: this);
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    await FlutterOverlayWindow.resizeOverlay(
      Constants.overlayWidth.toInt(),
      Constants.overlayHeight.toInt(),
      true,
    );
    setState(() => _expanded = true);
    _controller.forward();
  }

  Future<void> _close() async {
    await _controller.reverse();
    setState(() => _expanded = false);
    await FlutterOverlayWindow.resizeOverlay(
      Constants.bubbleSize.toInt(),
      Constants.bubbleSize.toInt(),
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: _expanded ? _buildChat() : _buildBubble(),
      ),
    );
  }

  Widget _buildBubble() {
    return GestureDetector(
      onTap: _open,
      child: Container(
        width: Constants.bubbleSize,
        height: Constants.bubbleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [AppTheme.accentColor, AppTheme.accentColor.withOpacity(0.6)],
          ),
          boxShadow: [
            BoxShadow(color: AppTheme.accentColor.withOpacity(0.6), blurRadius: 20, spreadRadius: 4),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: const Center(
          child: Text('◉', style: TextStyle(fontSize: 30, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildChat() {
    return ScaleTransition(
      scale: _scale,
      child: ChatOverlay(onClose: _close),
    );
  }
}