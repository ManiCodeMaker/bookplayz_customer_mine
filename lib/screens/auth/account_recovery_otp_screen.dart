import 'package:flutter/material.dart';
import '../../api/api_constants.dart';
import '../../api/api_service.dart';
import '../../api/session_manager.dart';
import '../../theme/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/otp_box.dart';

class AccountRecoveryOtpScreen extends StatefulWidget {
  const AccountRecoveryOtpScreen({super.key});

  @override
  State<AccountRecoveryOtpScreen> createState() => _AccountRecoveryOtpScreenState();
}

class _AccountRecoveryOtpScreenState extends State<AccountRecoveryOtpScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  String _identifier = '';
  String _identifierType = 'mobile';
  String _action = 'retrieve';
  bool _loading = false;
  bool _argsRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _identifier = args['identifier'] as String? ?? '';
      _identifierType = args['identifierType'] as String? ?? 'mobile';
      _action = args['action'] as String? ?? 'retrieve';
    }
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
  }

  @override
  void dispose() {
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
      final data = await AuthApi.resolveAccountRecovery(
        identifier: _identifier,
        identifierType: _identifierType,
        otp: otp,
        action: _action,
      );

      if (_action == 'retrieve') {
        await SessionManager.instance.saveSession(
          user: SessionUser.fromJson(data['user'] as Map<String, dynamic>),
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );
        if (!mounted) return;
        AppSnackbar.showSuccess(context, 'Welcome back! Your account has been restored.');
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          AppRoutes.locationPermission,
          (route) => false,
        );
      } else {
        await SessionManager.instance.clearSession();
        if (!mounted) return;
        await _showCreateNewDialog();
      }
    } catch (e) {
      if (!mounted) return;
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
      AppSnackbar.showError(context, e is ApiException ? e.message : e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showCreateNewDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Number Freed',
          style: TextStyle(
            fontFamily: 'Jost',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Color(0xFF0A2540),
          ),
        ),
        content: const Text(
          'This number is now free. Continue to sign in and you can create a new account right away.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context, rootNavigator: true)
                  .pushNamedAndRemoveUntil(AppRoutes.signin, (r) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.limeGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text(
              'Continue to Sign In',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: AppColors.navyBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onResend() async {
    for (final c in _controllers) { c.clear(); }
    _focusNodes[0].requestFocus();
    _staggerController.reset();
    _staggerController.forward();

    try {
      await AuthApi.requestAccountRecovery(
        identifier: _identifier,
        identifierType: _identifierType,
      );
      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'OTP resent successfully');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e is ApiException ? e.message : e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.limeGreen, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 12, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter',
                    style: TextStyle(
                      fontFamily: 'AtlanticBentley',
                      fontSize: 25,
                      color: AppColors.brightLimeGreen,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'OTP',
                    style: TextStyle(
                      fontFamily: 'Anton',
                      fontSize: 25,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.white,
                      ),
                      children: [
                        const TextSpan(text: 'We have sent a 4 digit code to '),
                        TextSpan(
                          text: _identifier,
                          style: const TextStyle(
                            color: AppColors.brightLimeGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

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
                          child: OtpBox(
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
      ),
    );
  }
}
