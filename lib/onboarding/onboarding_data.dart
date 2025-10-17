class OnboardingData {
  final String title;
  final String description;
  final String image;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
  });
}

final List<OnboardingData> onboardingPages = [
  OnboardingData(
    title: 'Welcome to',
    description: 'Instantly identify crabs and learn fascinating facts with just a snap',
    image: 'assets/brand/mr_crab.svg',
  ),
  OnboardingData(
    title: 'Scan your image to identify the crab',
    description: 'Point, scan, and let us identify your crab.',
    image: 'assets/brand/search.svg',
  ),
  OnboardingData(
    title: 'Learn Crab Facts',
    description: 'Discover amazing information about different crab species.',
    image: 'assets/brand/crab_idea.svg',
  ),
  OnboardingData(
    title: 'Ready to Discover Crabs?',
    description: 'Your smart crab companion - always ready to help you explore.',
    image: 'assets/brand/scan_crab.svg',
  ),
];
