import 'package:bookplayz/theme/app_theme.dart';
import 'package:flutter/material.dart';

// Mirrors the content on the BookPlayz web app's Privacy Policy page
// (bookplayz_web_frontend/src/pages/PrivacyPolicy/PrivacyPolicyContent.jsx).
// Keep the two in sync when the policy changes.
const List<({String title, String content})> _kPrivacySections = [
  (
    title: 'Information That We Collect',
    content:
        'The company collects information to provide you with a seamless process during your booking experience on our platform for your sports venue. Information can be collected in the following situations: Registration on our platform, Booking of sports venues, Contacting our customer service, and Taking part in our promotions.\n\n'
        "Your personal information, such as your full name, email address, telephone number, city, booking preferences, and log-in information will be asked for during the situations mentioned above. Information relating to booking transactions — booked venues' details, timeslots, previous bookings, payment confirmation, and refunds — may also be collected.\n\n"
        'The payment method is made through third-party payment gateways, and BookPlayz does not store any of your debit/credit card or banking information. Technical information about your device (device type, browser version, OS, IP address) is automatically gathered for system improvement and security. Location information can be collected with your agreement to discover sports venues near you.',
  ),
  (
    title: 'How Your Information is Used',
    content:
        'All the data we collect is used to make our service more effective, efficient, and safe. Your personal data is necessary to set up your profile and manage booking and cancellation operations.\n\n'
        'The data you provide enables us to improve our recommendation system, provide personalized recommendations, and discover your preferences. Sometimes, we may notify you about promotions and news related to our services or events you have booked. You will always have the option to unsubscribe from marketing emails. Technical and analytical data is gathered to improve our platform and ensure smooth operation.',
  ),
  (
    title: 'Sharing and Disclosure of Information',
    content:
        'BookPlayz does not sell, rent, or commercialize any user information to third parties. To ensure provision of quality services, some information is shared with our service providers, which include venues, payment processors, hosting facilities, analytics providers, and customer service providers. These organizations are obligated to keep details strictly confidential and can use information only to ensure smooth operation of services provided by BookPlayz.\n\n'
        "Information will also be shared if the law requires, due to legal proceedings, or to defend BookPlayz's, the customers', and partners' rights, interests, and safety. In the event BookPlayz undergoes changes such as mergers, acquisitions, or restructuring, information will be passed on in good faith for business continuity.",
  ),
  (
    title: 'Cookies and Tracking Technologies',
    content:
        'BookPlayz uses cookies and similar technology for added convenience and performance. Through this technology, BookPlayz can remember preferences, maintain login information, decrease loading times, find trends, and customize better. Cookies enable us to understand how our website is being used, making it possible to enhance the website. The user is given the option of blocking cookies in their browser, but this may limit some website functionality.',
  ),
  (
    title: 'Data Protection and Security',
    content:
        'BookPlayz maintains industry-standard technical, administrative, and operational security measures to guard your personal information from unauthorized access, use, disclosure, loss, destruction, or modification. Our system utilizes encryption-based communication protocols, security-enforced infrastructure, administrative restrictions, round-the-clock security monitoring, and secure integration with third-party financial services providers.\n\n'
        'Although BookPlayz implements robust security measures, users are aware that no online data transmission or digital data storage is completely foolproof.',
  ),
  (
    title: 'Data Retention',
    content:
        'BookPlayz keeps user data for only as long as is reasonably necessary to deliver its services and comply with legal obligations. Once the purpose for which the data was stored no longer applies, the data will be securely destroyed, anonymized, or archived.',
  ),
  (
    title: 'User Rights and Account Control',
    content:
        'User rights include the ability to access, review, update, or request the removal of any personal data connected to their BookPlayz account as long as there are no legal restrictions. A user can revoke permission for promotional communications or request correction of any inaccuracies. Personal data will be removed from any records upon request, provided the account is deleted. BookPlayz will ensure removal or de-identification of any personal data in such cases.',
  ),
  (
    title: 'Third-Party Links',
    content:
        'The BookPlayz platform may contain links to third-party websites, venue partner pages, or external services. BookPlayz is not responsible for the privacy practices, policies, or content of such third-party platforms. Users are advised to review the privacy policies of external services before interacting with them.',
  ),
  (
    title: "Children's Privacy",
    content:
        'The BookPlayz platform is designed for users who have reached an adequate age to book by themselves. Personal data obtained without valid consent of parents or guardians from children will not knowingly be collected by BookPlayz. In case such personal information is found, it will immediately be deleted from our records.',
  ),
  (
    title: 'Changes to this Privacy Policy',
    content:
        'BookPlayz may update this Privacy Policy periodically to reflect changes in legal requirements, technology, or platform enhancements. Updated versions will be published on this page along with the revised effective date. Continued use of the platform following such updates constitutes acceptance of the revised Privacy Policy.',
  ),
  (
    title: 'Contact Us',
    content:
        'For any privacy-related concerns, requests, clarifications, or support assistance, users may contact us directly.\n\n'
        'BookPlayz — Madurai, Tamil Nadu, India\n'
        'Email: support@bookplayz.com\n'
        'Website: www.bookplayz.com',
  ),
];

class PrivacyPolicyScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const PrivacyPolicyScreen({super.key, this.onBack});

  void _goBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: SafeArea(
        child: Column(
          children: [
            // ── Screen title with back button ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _goBack(context),
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
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Privacy',
                          style: TextStyle(
                            fontFamily: 'AtlanticBentley',
                            fontSize: 22,
                            color: AppColors.brightLimeGreen,
                            height: 1.0,
                          ),
                        ),
                        const Text(
                          'Policy',
                          style: TextStyle(
                            fontFamily: 'Anton',
                            fontSize: 26,
                            color: AppColors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 38), // balance the back button
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'We Take Your Privacy Seriously',
                      style: const TextStyle(
                        fontFamily: 'Jost',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Here at BookPlayz, we ensure that the privacy of all individuals '
                      'visiting our website and using our services is taken care of. This '
                      'Privacy Policy includes all necessary information related to how the '
                      'information of our users is used and protected by us. By accessing or '
                      'using our website and services, you agree that you have read, '
                      'understand, and agree with the contents of this Privacy Policy.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.6,
                        color: AppColors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 28),

                    for (final section in _kPrivacySections) ...[
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontFamily: 'Jost',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.limeGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final para in section.content.split('\n\n')) ...[
                        Text(
                          para,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            height: 1.6,
                            color: AppColors.white.withValues(alpha: 0.65),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 14),
                    ],

                    Center(
                      child: Text(
                        'Book Smart. Play Hard. Stay Protected with BookPlayz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white.withValues(alpha: 0.4),
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
