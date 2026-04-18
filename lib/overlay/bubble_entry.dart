import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'chat_overlay.dart';

/// This is the root widget rendered inside the overlay context
class OrbOverlayEntry extends StatefulWidget {
  const OrbOverlayEntry({super.key});

  @override
  State<OrbOverlayEntry> createState() => _OrbOverlayEntryState();
}

class _OrbOverlayEntryState extends State<OrbOverlayEntry>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      // Resize overlay to chat size
      FlutterOverlayWindow.resizeOverlay(
        Constants.overlayWidth.toInt(),
        Constants.overlayHeight.toInt(),
        true,
      );
      _controller.forward();
    } else {
      // Shrink back to bubble
      _controller.reverse().then((_) {
        FlutterOverlayWindow.resizeOverlay(
          Constants.bubbleSize.toInt(),
          Constants.bubbleSize.toInt(),
          true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: _expanded ? _buildExpanded() : _buildBubble(),
      ),
    );
  }

  Widget _buildBubble() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        width: Constants.bubbleSize,
        height: Constants.bubbleSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppTheme.accentColor,
              AppTheme.accentColor.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: const Center(
          child: Text(
            '◉',
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ChatOverlay(onClose: _toggleExpanded),
    );
  }
}
