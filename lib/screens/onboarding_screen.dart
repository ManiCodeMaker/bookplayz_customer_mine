import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/api_constants.dart';
import '../models/onboarding_data.dart';
import '../models/page_image_model.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loader.dart';
import '../theme/app_constants.dart';

/// pageType slug (superadmin "User App Splash Screen") that backs this
/// screen's slide images.
const String _onboardingPageType = 'user-app-splash-screen';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _swipingRight = false; // ← track swipe direction

  AnimationController? _textController;
  Animation<Offset>? _textSlideAnim;
  Animation<double>? _textFadeAnim;
  final TapGestureRecognizer _venueRegTap = TapGestureRecognizer();

  // Network slide content (image + title + subtitle) keyed by index,
  // matched 1:1 against [onboardingPages]. Falls back to the local
  // hardcoded copy until/unless loaded.
  List<PageImageModel>? _networkPages;

  // True until the first _loadImages() attempt finishes (success or
  // failure). Kept true rather than showing the local stock image, so the
  // slide never flashes local asset → network image once it arrives.
  bool _imagesLoading = true;

  @override
  void initState() {
    super.initState();
    _venueRegTap.onTap = () {
      Navigator.pushNamed(context, AppRoutes.signup);
    };

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    _initTextAnimation(fromRight: true);
     // ← ADD THIS — triggers the animation after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _textController?.forward();
      });

    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final images = await PageImagesApi.byPageType(_onboardingPageType);
      if (!mounted) return;
      setState(() {
        if (images.length == onboardingPages.length) _networkPages = images;
        _imagesLoading = false;
      });
    } catch (e) {
      debugPrint('Onboarding page images fetch failed, using local assets: $e');
      if (mounted) setState(() => _imagesLoading = false);
    }
  }

  void _initTextAnimation({required bool fromRight}) {
    _textController?.dispose();

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    // ← direction-aware slide
    _textSlideAnim = Tween<Offset>(
      begin: Offset(fromRight ? 0.3 : -0.3, 0), // right→left or left→right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOut,
    ));

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOut),
    );

    _textController = controller;
  }

  void _startTextAnimation({required bool fromRight}) {
    _initTextAnimation(fromRight: fromRight);
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _textController?.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _textController?.dispose();
    _venueRegTap.dispose(); // ← don't forget this
    super.dispose();
  }

  void _onContinue() {
    if (_currentPage < onboardingPages.length - 1) {
      _swipingRight = false; // continue button always goes forward
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.signin);
    }
  }

  String _pageTitle(int index) {
    final networkTitle = _networkPages?[index].title;
    if (networkTitle != null && networkTitle.isNotEmpty) return networkTitle;
    return onboardingPages[index].title;
  }

  String _pageSubtitle(int index) {
    final networkSubtitle = _networkPages?[index].subTitle;
    if (networkSubtitle != null && networkSubtitle.isNotEmpty) return networkSubtitle;
    final networkDescription = _networkPages?[index].description;
    if (networkDescription != null && networkDescription.isNotEmpty) return networkDescription;
    return onboardingPages[index].subtitle;
  }

  void _onPageChanged(int index) {
    final comingFromRight = index > _currentPage; // forward = text from right
    setState(() => _currentPage = index);
    _startTextAnimation(fromRight: comingFromRight);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentPage == onboardingPages.length - 1;
    final bottomPanelHeight = size.height * 0.55;
    final topImageHeight = size.height * 0.55;

    if (_textController == null ||
        _textSlideAnim == null ||
        _textFadeAnim == null) {
      return const Scaffold(backgroundColor: Color(0xFF0A1628));
    }

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      // ── Wrap entire body so full screen is swipeable ──
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;

          if (velocity < -300 && _currentPage < onboardingPages.length - 1) {
            // Swipe LEFT → go forward
            _swipingRight = false;
            _pageController.nextPage(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
            );
          } else if (velocity > 300 && _currentPage > 0) {
            // Swipe RIGHT → go back
            _swipingRight = true;
            _pageController.previousPage(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Stack(
          children: [
            // ── Image layer ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topImageHeight,
              child: _imagesLoading
                  ? Container(
                      color: AppColors.darkNavy,
                      child: const Center(child: AppLoader()),
                    )
                  : PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const NeverScrollableScrollPhysics(), // ← PageView itself locked
                      itemCount: onboardingPages.length,
                      itemBuilder: (context, index) {
                        final networkUrl = _networkPages?[index].imageUrl;
                        if (networkUrl != null && networkUrl.isNotEmpty) {
                          return Image.network(
                            networkUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              // Show a spinner (not the local stock image)
                              // while the network bytes download, so the
                              // slide never flashes local → backend image.
                              return Container(
                                color: AppColors.darkNavy,
                                child: const Center(child: AppLoader()),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Image.asset(
                              onboardingPages[index].image,
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                        return Image.asset(
                          onboardingPages[index].image,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
            ),

            // ── Bottom navy brush-stroke panel ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomPanelHeight,
              child: Image.asset(
                AppImages.onboardingBottomBg,
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
              ),
            ),

            // ── Bottom content ──
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: bottomPanelHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(18, size.height * 0.12, 18, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRect(
                      child: SizedBox(
                        width: size.width - 60,
                        child: FadeTransition(
                          opacity: _textFadeAnim!,
                          child: SlideTransition(
                            position: _textSlideAnim!,
                            child: Column(
                              children: [
                                Text(
                                  _pageTitle(_currentPage),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Jost',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.white,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _pageSubtitle(_currentPage),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.white,
                                    height: 1.55,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SmoothPageIndicator(
                      controller: _pageController,
                      count: onboardingPages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppColors.limeGreen,
                        dotColor: AppColors.white.withOpacity(0.35),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 2.8,
                        spacing: 6,
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: 300,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _onContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.limeGreen,
                          foregroundColor: AppColors.navyBlue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLastPage ? 'Get Started' : 'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: AppColors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLastPage
                                  ? Icons.arrow_forward_rounded
                                  : Icons.arrow_outward_rounded,
                              size: 20,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (isLastPage) ...[
                      const SizedBox(height: 16),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Jost',
                            color: AppColors.white.withValues(alpha: 0.65),
                          ),
                          // children: [
                          //   const TextSpan(
                          //       text: "Don't have Registered your Venue? "),
                          //   TextSpan(
                          //     text: 'Register',
                          //     style: const TextStyle(
                          //       fontSize: 16,
                          //       fontWeight: FontWeight.w600,
                          //       color: AppColors.limeGreen,
                          //     ),
                          //     recognizer: _venueRegTap,
                          //   ),
                          // ],
                        ),
                      ),
                    ] else
                      const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Skip button (hidden on last page) ──
            if (!isLastPage)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.signin),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          
          ],
        ),
      ),
    );
  }
}