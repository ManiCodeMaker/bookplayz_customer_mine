  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:google_fonts/google_fonts.dart';
  import '../../theme/app_theme.dart';
  import '../../theme/app_constants.dart';
  import 'package:flutter_svg/flutter_svg.dart';
  import '../../api/api_constants.dart';
  import '../../widgets/app_snackbar.dart';


  class SignInScreen extends StatefulWidget {
    const SignInScreen({super.key});

    @override
    State<SignInScreen> createState() => _SignInScreenState();
  }

  class _SignInScreenState extends State<SignInScreen> {
    final TextEditingController _phoneController = TextEditingController();
    String _selectedCountryCode = '+91';
    String _selectedFlag = '🇮🇳';
    bool _loading = false;

    final List<Map<String, String>> _countryCodes = [
      {'flag': '🇮🇳', 'code': '+91', 'country': 'India'},
      {'flag': '🇺🇸', 'code': '+1',  'country': 'USA'},
      {'flag': '🇬🇧', 'code': '+44', 'country': 'UK'},
      {'flag': '🇦🇺', 'code': '+61', 'country': 'Australia'},
      {'flag': '🇨🇦', 'code': '+1',  'country': 'Canada'},
      {'flag': '🇸🇬', 'code': '+65', 'country': 'Singapore'},
      {'flag': '🇦🇪', 'code': '+971','country': 'UAE'},
    ];

    @override
    void dispose() {
      _phoneController.dispose();
      super.dispose();
    }

    Future<void> _onContinue() async {
      final phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        AppSnackbar.showError(context, 'Please enter your phone number');
        return;
      }

      final mobile = '$_selectedCountryCode$phone'; 

      setState(() => _loading = true);
      try {
        await AuthApi.requestOtp(mobile);
        if (!mounted) return;
        AppSnackbar.showSuccess(context, 'OTP sent to $mobile'); 
        Navigator.pushNamed(
          context,
          AppRoutes.otp,
          arguments: mobile, // pass full number with country code
        );
      } catch (e) {
        if (!mounted) return;
        AppSnackbar.showError(context, e.toString());
      } finally {
        if (mounted) setState(() => _loading = false);
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
                  Image.asset(AppImages.signinTop,
                      fit: BoxFit.cover, alignment: Alignment.topCenter),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Image.asset(
                      AppImages.signTopOverlay,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                    ),
                  ),
                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, AppRoutes.splash, (r) => false),
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
                  // Title block
                  Positioned(
                    bottom: 45, left: 0, right: 0,
                    child: Column(
                      children: [
                        Text(
                          "Let's",
                          style: const TextStyle(
                            fontFamily: 'AtlanticBentley',
                            fontSize: 25,
                            color: AppColors.brightLimeGreen,
                            height: 0.3,
                          ),
                        ),
                        const Text(
                          'Sign you in',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Anton',
                            fontSize: 25,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter your phone number to receive an OTP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Form ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 28, 30, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        color: AppColors.white,
                        fontFamily: 'Jost',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PhoneInputField(
                      controller: _phoneController,
                      selectedFlag: _selectedFlag,
                      selectedCode: _selectedCountryCode,
                      onTapCode: () => _showCountryPicker(context),
                    ),
                    const SizedBox(height: 24),
                    _PrimaryButton(
                      label: 'Continue',
                      icon: Icons.arrow_outward_rounded,
                      loading: _loading,
                      onPressed: _loading ? null : _onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    void _showCountryPicker(BuildContext context) {
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0D1B3E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _countryCodes.length,
              itemBuilder: (_, i) {
                final item = _countryCodes[i];
                return ListTile(
                  leading:
                      Text(item['flag']!, style: const TextStyle(fontSize: 24)),
                  title: Text(
                    '${item['country']} (${item['code']})',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedFlag = item['flag']!;
                      _selectedCountryCode = item['code']!;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }
  }class _PrimaryButton extends StatelessWidget {
    final String label;
    final IconData icon;
    final VoidCallback? onPressed;
    final bool loading;

    const _PrimaryButton({
      required this.label,
      required this.icon,
      required this.onPressed,
      this.loading = false,
    });

    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.limeGreen,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: loading
              ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w400,
                          color: AppColors.white,
                        )),
                    const SizedBox(width: 8),
                    Icon(icon, size: 20, color: AppColors.white),
                  ],
                ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  // Reusable widgets
  // ─────────────────────────────────────────────

  class _PhoneInputField extends StatelessWidget {
    final TextEditingController controller;
    final String selectedFlag;
    final String selectedCode;
    final VoidCallback onTapCode;

    const _PhoneInputField({
      required this.controller,
      required this.selectedFlag,
      required this.selectedCode,
      required this.onTapCode,
    });

    @override
    Widget build(BuildContext context) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onTapCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
                  ),
                ),
                child: Row(
                  children: [
                    Text(selectedFlag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(
                      selectedCode,
                      style: GoogleFonts.poppins(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.white.withValues(alpha: 0.6), size: 18),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(color: AppColors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter your Phone Number',
                  hintStyle: TextStyle(
                    color: AppColors.inputPlceholder,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }