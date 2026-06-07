import 'dart:io';

import 'package:bookplayz/api/api_constants.dart';
import 'package:bookplayz/api/api_service.dart';
import 'package:bookplayz/api/session_manager.dart';
import 'package:bookplayz/theme/app_theme.dart';
import 'package:bookplayz/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const EditProfileScreen({super.key, this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController  = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool    _loading  = true;
  bool    _isSaving = false;
  String? _error;

  bool    _emailVerified  = true;  // true = no banner until after first save
  bool    _hasSaved       = false;
  bool    _isSendingOtp   = false;
  String? _profileImageUrl;
  XFile?  _pickedImage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Fetch ────────────────────────────────────────────────────────────────────
  Future<void> _fetchProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res  = await ApiService.instance.get(ProfileApi.me);
      final data = res['data'] as Map<String, dynamic>;
      _nameController.text  = data['fullName'] as String? ?? '';
      _emailController.text = data['email']    as String? ?? '';
      _phoneController.text = data['mobile']   as String? ?? '';
      setState(() {
        _emailVerified   = data['emailVerified']  as bool? ?? false;
        _profileImageUrl = data['profileImage']   as String?;
        _loading         = false;
      });

      // Keep session in sync
      final session = SessionManager.instance;
      if (session.currentUser != null) {
        session.user = session.currentUser!.copyWith(
          fullName:       data['fullName']    as String?,
          email:          data['email']       as String?,
          emailVerified:  data['emailVerified']  as bool?,
          mobileVerified: data['mobileVerified'] as bool?,
          profileImage:   data['profileImage']   as String?,
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Pick image ───────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (img != null) setState(() => _pickedImage = img);
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final fullName = _nameController.text.trim();
    final email    = _emailController.text.trim();
    final mobile   = _phoneController.text.trim();

    if (fullName.isEmpty) {
      AppSnackbar.showError(context, 'Name is required.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final fields = <String, String>{
        'fullName': fullName,
        if (email.isNotEmpty) 'email': email,
        'mobile': mobile,
      };
      final files = <http.MultipartFile>[];
      if (_pickedImage != null) {
        files.add(await http.MultipartFile.fromPath('profileImage', _pickedImage!.path));
      }
      final res = await ApiService.instance.putMultipart(ProfileApi.me, fields, files: files);
      final responseData = res['data'] as Map<String, dynamic>;

      // Update session
      final session = SessionManager.instance;
      if (session.currentUser != null) {
        session.user = session.currentUser!.copyWith(
          fullName:      responseData['fullName']    as String?,
          email:         responseData['email']       as String?,
          profileImage:  responseData['profileImage'] as String?,
          emailVerified: responseData['emailVerified'] as bool?,
        );
      }

      setState(() {
        _isSaving        = false;
        _hasSaved        = true;
        _pickedImage     = null;
        _profileImageUrl = responseData['profileImage'] as String?;
        _emailVerified   = responseData['emailVerified'] as bool? ?? false;
      });

      if (mounted) AppSnackbar.showSuccess(context, 'Profile updated successfully');
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        final msg = e is ApiException ? e.message : 'Update failed. Please try again.';
        AppSnackbar.showError(context, msg);
      }
    }
  }

  // ── Request email OTP ────────────────────────────────────────────────────────
  Future<void> _requestEmailOtp() async {
    setState(() => _isSendingOtp = true);
    try {
      await ApiService.instance.post(ProfileApi.verifyEmailRequest, {});
      setState(() => _isSendingOtp = false);
      if (!mounted) return;
      _showVerifyEmailSheet();
    } catch (e) {
      setState(() => _isSendingOtp = false);
      if (mounted) AppSnackbar.showError(context, 'Failed to send OTP. Please try again.');
    }
  }

  void _showVerifyEmailSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VerifyEmailSheet(email: _emailController.text.trim()),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.limeGreen))
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _fetchProfile)
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      // ── Screen title with back button ─────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              left: 16,
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.onBack != null) {
                                    widget.onBack!();
                                  } else {
                                    Navigator.maybePop(context);
                                  }
                                },
                                child: Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.white.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: AppColors.limeGreen,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontFamily: 'AtlanticBentley',
                                    fontSize: 22,
                                    color: AppColors.brightLimeGreen,
                                    height: 1.0,
                                  ),
                                ),
                                const Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontFamily: 'Anton',
                                    fontSize: 26,
                                    color: AppColors.white,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Update your profile information',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Form content ──────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(30, 0, 30, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: _AvatarPicker(
                              imageUrl:    _profileImageUrl,
                              pickedImage: _pickedImage,
                              onTap:       _pickImage,
                            )),
                            const SizedBox(height: 24),

                            if (_hasSaved && !_emailVerified) ...[
                              _UnverifiedBanner(
                                onVerify:  _isSendingOtp ? null : _requestEmailOtp,
                                isSending: _isSendingOtp,
                              ),
                              const SizedBox(height: 20),
                            ],

                            _FieldLabel('Full Name'),
                            const SizedBox(height: 8),
                            _EditField(
                              controller:   _nameController,
                              hintText:     'Your full name',
                              keyboardType: TextInputType.name,
                              prefixIcon:   Icons.person_outline_rounded,
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('Email Address'),
                            const SizedBox(height: 8),
                            _EditField(
                              controller:   _emailController,
                              hintText:     'Email address',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon:   Icons.mail_outline_rounded,
                            ),
                            const SizedBox(height: 16),

                            _FieldLabel('Mobile Number'),
                            const SizedBox(height: 8),
                            _EditField(
                              controller:   _phoneController,
                              hintText:     'Mobile number',
                              keyboardType: TextInputType.phone,
                              prefixIcon:   Icons.phone_outlined,
                              enabled:      false,
                            ),
                            const SizedBox(height: 32),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.limeGreen,
                                  disabledBackgroundColor:
                                      AppColors.limeGreen.withValues(alpha: 0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 22, height: 22,
                                        child: CircularProgressIndicator(
                                          color: AppColors.navyBlue,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.check_rounded,
                                              size: 20, color: AppColors.white),
                                          SizedBox(width: 8),
                                          Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.white,
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
    );
  }
}

// ── Avatar picker ─────────────────────────────────────────────────────────────
class _AvatarPicker extends StatelessWidget {
  final String? imageUrl;
  final XFile?  pickedImage;
  final VoidCallback onTap;

  const _AvatarPicker({
    required this.imageUrl,
    required this.pickedImage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.limeGreen.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.limeGreen, width: 2),
            ),
            child: ClipOval(
              child: pickedImage != null
                  ? Image.file(File(pickedImage!.path), fit: BoxFit.cover)
                  : imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, err) => _defaultAvatar,
                        )
                      : _defaultAvatar,
            ),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: AppColors.limeGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.navyBlue, width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded,
                  size: 15, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget get _defaultAvatar => Icon(
    Icons.person_rounded,
    color: AppColors.limeGreen,
    size: 52,
  );
}

// ── Unverified email banner ───────────────────────────────────────────────────
class _UnverifiedBanner extends StatelessWidget {
  final VoidCallback? onVerify;
  final bool isSending;

  const _UnverifiedBanner({required this.onVerify, required this.isSending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Your email is unverified',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onVerify,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: isSending
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.mail_outline_rounded,
                            size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Verify Now',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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

// ── Verify email OTP bottom sheet ─────────────────────────────────────────────
class _VerifyEmailSheet extends StatefulWidget {
  final String email;
  const _VerifyEmailSheet({required this.email});

  @override
  State<_VerifyEmailSheet> createState() => _VerifyEmailSheetState();
}

class _VerifyEmailSheetState extends State<_VerifyEmailSheet>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  late AnimationController _staggerController;
  late List<Animation<Offset>> _slideAnims;
  late List<Animation<double>> _fadeAnims;

  bool _loading = false;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _slideAnims = List.generate(4, (i) {
      final start = i * 0.25;
      final end   = (start + 0.45).clamp(0.0, 1.0);
      return Tween<Offset>(begin: const Offset(0, 1.2), end: Offset.zero)
          .animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ));
    });

    _fadeAnims = List.generate(4, (i) {
      final start = i * 0.18;
      final end   = (start + 0.35).clamp(0.0, 1.0);
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
    for (final f in _focusNodes)  { f.dispose(); }
    super.dispose();
  }

  void _onDigitChanged(String value, int index) {
    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isNotEmpty && index == 3) {
      _focusNodes[index].unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.78),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: AppColors.navyBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Drag handle ──────────────────────────────────────
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Header row ───────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Your Email',
                              style: TextStyle(
                                fontFamily: 'Jost',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close_rounded,
                              size: 18,
                              color: AppColors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ─────────────────────────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.white.withValues(alpha: 0.6),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Enter the OTP sent to '),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              color: AppColors.limeGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── OTP boxes ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return AnimatedBuilder(
                        animation: _staggerController,
                        builder: (context, child) => FadeTransition(
                          opacity: _fadeAnims[index],
                          child: SlideTransition(
                            position: _slideAnims[index],
                            child: child,
                          ),
                        ),
                        child: _OtpBox(
                          controller: _controllers[index],
                          focusNode:  _focusNodes[index],
                          onChanged:  (val) => _onDigitChanged(val, index),
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
                  const SizedBox(height: 32),

                  // ── Verify button ────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () {
                              AppSnackbar.showSuccess(
                                  context, 'OTP validation coming soon');
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.limeGreen,
                        disabledBackgroundColor:
                            AppColors.limeGreen.withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: AppColors.navyBlue, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.verified_outlined,
                                    size: 20, color: AppColors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
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
        ),
      ),
    );
  }
}

// ── OTP digit box (matches otp_screen.dart design) ────────────────────────────
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
          controller:   widget.controller,
          focusNode:    widget.focusNode,
          keyboardType: TextInputType.number,
          textAlign:    TextAlign.center,
          maxLength:    1,
          onChanged:    widget.onChanged,
          style: TextStyle(
            fontFamily:  'Inter',
            fontSize:    22,
            fontWeight:  FontWeight.w600,
            color: isFocused
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.5),
          ),
          decoration: InputDecoration(
            counterText: '',
            filled:      true,
            fillColor:   AppColors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.15)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.limeGreen, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared field widgets ───────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color:      AppColors.white,
      fontFamily: 'Jost',
      fontSize:   14,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final bool enabled;

  const _EditField({
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.white.withValues(alpha: 0.07)
            : AppColors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled
              ? AppColors.white.withValues(alpha: 0.15)
              : AppColors.white.withValues(alpha: 0.07),
        ),
      ),
      child: TextField(
        controller:   controller,
        keyboardType: keyboardType,
        enabled:      enabled,
        style: TextStyle(
          color:      enabled ? AppColors.white : AppColors.white.withValues(alpha: 0.4),
          fontFamily: 'Inter',
          fontSize:   14,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color:      AppColors.white.withValues(alpha: 0.35),
            fontSize:   13,
            fontFamily: 'Inter',
          ),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon,
                  size:  18,
                  color: enabled
                      ? AppColors.white.withValues(alpha: 0.5)
                      : AppColors.white.withValues(alpha: 0.2))
              : null,
          border:         InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                color: AppColors.white.withValues(alpha: 0.4), size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize:   13,
                color: AppColors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.limeGreen,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontFamily: 'Inter', color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
