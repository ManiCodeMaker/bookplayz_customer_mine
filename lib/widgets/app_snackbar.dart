// lib/screens/widgets/app_snackbar.dart

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppSnackbar {
  AppSnackbar._();

  static void showSuccess(BuildContext context, String message) {
    _show(context, message: message, isError: false);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message: message, isError: true);
  }

  /// Show success with an optional action button (e.g. "Share")
  static void showSuccessWithAction(
    BuildContext context,
    String message, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    _show(
      context,
      message:     message,
      isError:     false,
      actionLabel: actionLabel,
      onAction:    onAction,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required bool isError,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Navigator.of(context, rootNavigator: true).overlay;
    if (overlay == null) return;
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _AppSnackbarWidget(
        message:     message,
        isError:     isError,
        actionLabel: actionLabel,
        onAction:    onAction,
        onDismiss:   () => entry.remove(),
      ),
    );

    overlay.insert(entry);
  }
}

class _AppSnackbarWidget extends StatefulWidget {
  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _AppSnackbarWidget({
    required this.message,
    required this.isError,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_AppSnackbarWidget> createState() => _AppSnackbarWidgetState();
}

class _AppSnackbarWidgetState extends State<_AppSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slide;
  late Animation<double> _fade;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color _successBg     = Color(0xFF00224A);
  static const Color _successBorder = Color(0xFF9CCE00);
  static const Color _successText   = Color(0xFFCCE482);
  static const Color _successIcon   = Color(0xFF9CCE00);

  static const Color _errorBg       = Color(0xFF1A0A0A);
  static const Color _errorBorder   = Color(0xFFFF3B30);
  static const Color _errorText     = Color(0xFFFF6B6B);
  static const Color _errorIcon     = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Stay longer if there's an action button
    final duration = widget.actionLabel != null
        ? const Duration(seconds: 6)
        : const Duration(seconds: 3);
    Future.delayed(duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    final bg     = widget.isError ? _errorBg     : _successBg;
    final border = widget.isError ? _errorBorder : _successBorder;
    final text   = widget.isError ? _errorText   : _successText;
    final icon   = widget.isError ? _errorIcon   : _successIcon;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _fade,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: border.withValues(alpha: 0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: border.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // ── Icon ───────────────────────────────────────────────
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: icon.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: icon.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.isError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: icon,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // ── Message ────────────────────────────────────────────
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: text,
                        ),
                      ),
                    ),

                    // ── Action button (optional) ───────────────────────────
                    if (widget.actionLabel != null && widget.onAction != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          widget.onAction!();
                          _dismiss();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: icon.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: icon.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: icon,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else
                      const SizedBox(width: 8),

                    // ── Dismiss X ──────────────────────────────────────────
                    Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: icon.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}