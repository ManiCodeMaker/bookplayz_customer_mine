class OnboardingData {
  final String image;
  final String title;
  final String subtitle;

  const OnboardingData({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

const List<OnboardingData> onboardingPages = [
  OnboardingData(
    image: 'assets/images/onboarding_img1.png',
    title: 'Find Nearby\nStadiums',
    subtitle:
        'Discover sports venues near you and\nbook your favorite courts instantly.',
  ),
  OnboardingData(
    image: 'assets/images/onboarding_img2.png',
    title: 'Book with Ease,\nStay with Style',
    subtitle:
        'Seamlessly reserve your slot and enjoy\na premium sporting experience.',
  ),
  OnboardingData(
    image: 'assets/images/onboarding_img3.png',
    title: 'Discover Your Turf,\nEffortlessly',
    subtitle:
        'Find the perfect ground for your game\nand play with your best squad.',
  ),
];
