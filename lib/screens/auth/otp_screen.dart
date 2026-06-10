import 'package:bookplayz/widgets/app_loader.dart';
import 'package:bookplayz/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_auth/smart_auth.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_constants.dart';
import '../../api/api_constants.dart';
import '../../api/session_manager.dart';


class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  String _phoneNumber = '';
  bool _loading = false;
  final _smartAuth = SmartAuth();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) _phoneNumber = args.toString();
  }

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideAnims = List.generate(4, (i) {
      final start = i * 0.25;
      final end = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 1.2),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ));
    });

    _fadeAnims = List.generate(4, (i) {
      final start = i * 0.18;
      final end = (start + 0.35).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _staggerController.forward();
    });

    _listenForSms();
  }

  Future<void> _listenForSms() async {
    final result = await _smartAuth.getSmsCode(
      useUserConsentApi: true,
      matcher: r'\d{4}',
    );
    if (!mounted || !result.codeFound) return;
    final digits = result.code!;
    for (int i = 0; i < 4; i++) {
      _controllers[i].text = digits[i];
    }
    setState(() {});
    Future.microtask(_onContinue);
  }

  @override
  void dispose() {
    _smartAuth.removeSmsListener();
    _staggerController.dispose();
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Auto-submit when last digit entered
        if (_isOtpComplete) _onContinue();
      }
    }
  }

  bool get _isOtpComplete => _controllers.every((c) => c.text.isNotEmpty);

  Future<void> _onContinue() async {
    if (!_isOtpComplete) {
      AppSnackbar.showError(context, 'Please enter the 4-digit OTP');
      return;
    }

    final otp = _controllers.map((c) => c.text).join();

    setState(() => _loading = true);
    try {
      final data = await AuthApi.verifyOtp(
        mobile: _phoneNumber,
        otp: otp,
      );

      // Save session
      await SessionManager.instance.saveSession(
        user: SessionUser.fromJson(data['user'] as Map<String, dynamic>),
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

      if (!mounted) return;
      // Clear entire auth stack and go home
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.locationPermission,
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      // Clear OTP boxes on wrong OTP
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      AppSnackbar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onResend() async {
    for (final c in _controllers) { c.clear(); }
    _focusNodes[0].requestFocus();
    _staggerController.reset();
    _staggerController.forward();

    try {
      await AuthApi.requestOtp(_phoneNumber);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'OTP resent successfully');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topHeight = size.height * 0.26;

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // ── Top image ──
          SizedBox(
            height: topHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(AppImages.otpTop,
                    fit: BoxFit.cover, alignment: Alignment.topCenter),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Image.asset(AppImages.signTopOverlay,
                      fit: BoxFit.fitWidth, width: double.infinity),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.limeGreen, size: 20),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20, left: 0, right: 0,
                  child: Column(
                    children: [
                      const Text(
                        "Enter",
                        style: TextStyle(
                          fontFamily: 'AtlanticBentley',
                          fontSize: 25,
                          color: AppColors.brightLimeGreen,
                          height: 0.2,
                        ),
                      ),
                      const Text(
                        'OTP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Anton',
                          fontSize: 25,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.white,
                            ),
                            children: [
                              const TextSpan(
                                  text: 'We have just sent you 4 digit code via your phone '),
                              TextSpan(
                                text: _phoneNumber.isEmpty
                                    ? '+91 99988 77755'
                                    : _phoneNumber,
                                style: const TextStyle(
                                  color: AppColors.brightLimeGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── OTP form ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 36, 30, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return AnimatedBuilder(
                        animation: _staggerController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnims[index],
                            child: SlideTransition(
                              position: _slideAnims[index],
                              child: child,
                            ),
                          );
                        },
                        child: _OtpBox(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          onChanged: (val) => _onDigitChanged(val, index),
                          onBackspace: () {
                            if (_controllers[index].text.isEmpty && index > 0) {
                              _controllers[index - 1].clear();
                              _focusNodes[index - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _onContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        disabledBackgroundColor:
                            AppColors.limeGreen.withValues(alpha: 0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _loading
                          ? const AppLoader(size: 22)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_outward_rounded,
                                    size: 20, color: AppColors.white),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Resend
                  GestureDetector(
                    onTap: _loading ? null : _onResend,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                          letterSpacing: 0.2,
                        ),
                        children: [
                          const TextSpan(text: "Didn't receive code? "),
                          TextSpan(
                            text: 'Resend Code',
                            style: TextStyle(
                              color: _loading
                                  ? AppColors.limeGreen.withValues(alpha: 0.4)
                                  : AppColors.limeGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single OTP digit box ──────────────────────────────────
class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  void _rebuild() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;

    return SizedBox(
      width: 72, height: 72,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              widget.controller.text.isEmpty) {
            widget.onBackspace();
          }
        },
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          onChanged: widget.onChanged,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: isFocused
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.5),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.limeGreen, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}