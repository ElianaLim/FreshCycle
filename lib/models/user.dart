class User {
  final String id;
  final String name;
  final String email;
  final String initials;
  final String? profilePictureUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.initials,
    this.profilePictureUrl,
  });

  // Sample user for demo
  static const User sampleUser = User(
    id: 'user_001',
    name: 'Maria Clara',
    email: 'maria.clara@example.com',
    initials: 'MC',
    profilePictureUrl: null,
  );
}