import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../api/api_constants.dart';
import '../../api/api_service.dart';
import '../../theme/app_constants.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_loader.dart';
import '../../widgets/app_snackbar.dart';

/// Shown after a login attempt reports the account as Deleted. Lets the
/// user choose to retrieve the same account or free it up and start over,
/// then requests an OTP for whichever action they picked.
class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({super.key});

  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? _identifier;
  String _identifierType = 'mobile';
  String _action = 'retrieve';
  bool _loading = false;
  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _identifier = args['identifier'] as String?;
      _identifierType = args['identifierType'] as String? ?? 'mobile';
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? get _resolvedIdentifier =>
      _identifier ?? (_phoneController.text.trim().isEmpty ? null : _phoneController.text.trim());

  Future<void> _onContinue() async {
    final identifier = _resolvedIdentifier;
    if (identifier == null || identifier.isEmpty) {
      AppSnackbar.showError(context, 'Please enter your phone number');
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthApi.requestAccountRecovery(
        identifier: identifier,
        identifierType: _identifierType,
      );
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.accountRecoveryOtp,
        arguments: {
          'identifier': identifier,
          'identifierType': _identifierType,
          'action': _action,
        },
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        e is ApiException ? e.message : 'Failed to send OTP. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(30, 8, 30, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recover',
                      style: TextStyle(
                        fontFamily: 'AtlanticBentley',
                        fontSize: 25,
                        color: AppColors.brightLimeGreen,
                        height: 1.0,
                      ),
                    ),
                    const Text(
                      'Your Account',
                      style: TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 25,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_identifier == null) ...[
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
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: GoogleFonts.poppins(color: AppColors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Enter your Phone Number',
                            hintStyle: TextStyle(
                              color: AppColors.inputPlceholder,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Text(
                        'We found a deleted account for $_identifier.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: AppColors.white,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    _ActionCard(
                      title: 'Retrieve My Account',
                      subtitle: 'Restore your bookings, favorites and profile exactly as they were.',
                      selected: _action == 'retrieve',
                      onTap: () => setState(() => _action = 'retrieve'),
                    ),
                    const SizedBox(height: 12),
                    _ActionCard(
                      title: 'Start Fresh',
                      subtitle: 'Permanently free up this number and sign up as a new account.',
                      selected: _action == 'create_new',
                      onTap: () => setState(() => _action = 'create_new'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.limeGreen,
                          disabledBackgroundColor: AppColors.limeGreen.withValues(alpha: 0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _loading
                            ? const AppLoader(size: 22)
                            : const Text(
                                'Send OTP',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.white,
                                ),
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

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.limeGreen.withValues(alpha: 0.1)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.limeGreen : AppColors.white.withValues(alpha: 0.1),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.limeGreen : AppColors.white.withValues(alpha: 0.4),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Jost',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
