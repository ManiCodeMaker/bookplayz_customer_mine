import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';
  String _selectedFlag = '🇮🇳';

  final List<Map<String, String>> _countryCodes = [
    {'flag': '🇮🇳', 'code': '+91', 'country': 'India'},
    {'flag': '🇺🇸', 'code': '+1', 'country': 'USA'},
    {'flag': '🇬🇧', 'code': '+44', 'country': 'UK'},
    {'flag': '🇦🇺', 'code': '+61', 'country': 'Australia'},
    {'flag': '🇨🇦', 'code': '+1', 'country': 'Canada'},
    {'flag': '🇸🇬', 'code': '+65', 'country': 'Singapore'},
    {'flag': '🇦🇪', 'code': '+971', 'country': 'UAE'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_phoneController.text.isNotEmpty) {
      Navigator.pushNamed(
        context,
        AppRoutes.otp,
        arguments: '$_selectedCountryCode ${_phoneController.text}',
      );
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
          // ── Top image with title overlay ──
          SizedBox(
            height: topHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(AppImages.signinTop, fit: BoxFit.cover,
                alignment: Alignment.topCenter, ),
                // Gradient overlay bottom  
                // Container(
                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       begin: Alignment.topCenter,
                //       end: Alignment.bottomCenter,
                //       colors: [
                //         Colors.black.withOpacity(0.1),
                //         AppColors.navyBlue.withOpacity(0.92),
                //       ],
                //       stops: const [0.35, 1.0],
                //     ),
                //   ),
                // ),
                 // 🖼 Overlay Image (top)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
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
                    onTap: () =>  {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.splash,
                        (route) => false, // clears entire stack
                      )
                    },
                    child: Container(
                      width: 48,
                      height: 48,
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
                  bottom: 45,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        "Let's",
                         style: TextStyle(
                            fontFamily: 'AtlanticBentley',
                            fontSize: 25,
                            color: AppColors.brightLimeGreen,
                            height: 0.3, 
                          ),
                      ),
                      Text(
                        'Sign you in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Anton',
                          fontSize: 25,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lorem ipsum dolor sit amet, consectetur',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.white
                        )
                      ),
                    ],
                  ),
                ),

          
              ],
            ),
          ),

          // ── Bottom scrollable form ──
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(30, 28, 30, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Phone Number label
                      Text(
                        'Phone Number',
                        style: TextStyle(
                          color:AppColors.white,
                          fontFamily: 'Jost',
                          fontSize: 14,
                          fontWeight: FontWeight.w600
                        )
                      ),
                      const SizedBox(height: 10),

                      // Phone input
                      _PhoneInputField(
                        controller: _phoneController,
                        selectedFlag: _selectedFlag,
                        selectedCode: _selectedCountryCode,
                        onTapCode: () => _showCountryPicker(context),
                      ),
                      const SizedBox(height: 24),

                      // Continue button
                      _PrimaryButton(
                        label: 'Continue',
                        icon: Icons.arrow_outward_rounded,
                        onPressed: _onContinue,
                      ),
                      const SizedBox(height: 18),

                      // Don't have account
                      Center(
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.signup),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color:AppColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                TextSpan(
                                  text: 'Sign Up',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.limeGreen,
                                  )
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const _OrDivider(label: 'Or Sign In with'),
                      const SizedBox(height: 25),

                      // Social buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SocialButton(
                              icon: SvgPicture.asset(
                                  AppImages.googleIcon,
                                  width: 24,
                                  height: 24,
                                ),
                              onTap: () {}),
                          if (Platform.isIOS) ...[
                            const SizedBox(width: 24),
                            _SocialButton(
                              icon: const Icon(Icons.apple,
                                  color: AppColors.blue, size: 28),
                              onTap: () {},
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 35),

                      // Terms
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              letterSpacing: 0.2,
                              height: 2,
                              color: AppColors.white.withValues(alpha: 0.5),
                            ),
                            children: [
                              const TextSpan(
                                  text: 'By signing up you agree to our '),
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(
                                  color: AppColors.neonLime,
                                ),
                              ),
                              const TextSpan(text: ' and\n'),
                              TextSpan(
                                text: 'Conditions of Use',
                                style: const TextStyle(
                                  color: AppColors.limeGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                            //dummy
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context, AppRoutes.home);
                          
                        },
                        child: Text(
                          "Go to Dashboard",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.underline, // optional
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            )
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
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
                leading: Text(item['flag']!,
                    style: const TextStyle(fontSize: 24)),
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
}

// ─────────────────────────────────────────────
// Shared reusable widgets (used across auth screens)
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
                  right: BorderSide(color: AppColors.white.withOpacity(0.15)),
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
                        fontWeight: FontWeight.w500),
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
                  fontWeight: FontWeight.w400
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                letterSpacing: 1,
                fontWeight: FontWeight.w400,
                color: AppColors.white),
              ),
            const SizedBox(width: 8),
            Icon(icon, size: 20, color: AppColors.white),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;
  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha: 0.2), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: TextStyle(
                fontFamily: 'Jost',
                  fontSize: 14,
                  letterSpacing: 0.2,
                  color: Colors.white.withValues(alpha:0.5))
                  ),
        ),
        Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha:0.2), thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Center(child: icon),
      ),
    );
  }
}

