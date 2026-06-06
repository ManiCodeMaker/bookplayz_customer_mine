import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InviteFriendsBanner extends StatelessWidget {
  final String discount;
  final VoidCallback? onInviteTap;

  const InviteFriendsBanner({
    super.key,
    this.discount = '₹200',
    this.onInviteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        // Warm cream/yellow gradient matching the design
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: text + button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INVITE YOUR FRIENDS',
                  style: TextStyle(
                    fontFamily: 'Anton',
                    fontSize: 18,
                    color: AppColors.navyBlue,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Get $discount Discount on\n',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.navyBlue.withValues(alpha: 0.7),
                          height: 1.4,
                        ),
                      ),
                      TextSpan(
                        text: 'Next Booking',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Invite button
                GestureDetector(
                  onTap: onInviteTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.limeGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'INVITE',
                      style: TextStyle(
                        fontFamily: 'Anton',
                        fontSize: 14,
                        color: AppColors.navyBlue,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Right: illustration
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Decorative dots
                Positioned(
                  top: 0,
                  right: 0,
                  child: _DotsDecoration(),
                ),
                // Gift/hands illustration placeholder
                // Replace with Image.asset(AppImages.inviteIllustration) when asset is added
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.limeGreen.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: AppColors.navyBlue,
                    size: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotsDecoration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(
        painter: _DotsPainter(),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navyBlue.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    const dotSize = 3.0;
    const spacing = 8.0;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(col * spacing + dotSize, row * spacing + dotSize),
          dotSize / 2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}