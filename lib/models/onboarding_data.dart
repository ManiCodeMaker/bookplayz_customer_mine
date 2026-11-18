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
    title: 'Book with Ease,\nStay with Style',
    subtitle:
        'Find the perfect ground for your game and play with your best squad.',
  ),
  OnboardingData(
    image: 'assets/images/onboarding_img2.png',
    title: 'Discover Your Turf,\nEffortlessly',
    subtitle:
        'Find the perfect turf near you, check availability and book your favourite sports venue with ease.',
  ),
  OnboardingData(
    image: 'assets/images/onboarding_img3.png',
    title: 'Find Nearby Venue',
    subtitle:
        'Discover sports stadiums and venues near you. Explore facilities, check availability, and book your next game with ease.',
  ),
];
