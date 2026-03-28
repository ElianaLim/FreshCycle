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

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      initials: map['initials'] as String? ?? 'U',
      profilePictureUrl: map['profile_picture_url'] as String?,
    );
  }

  // Sample user for demo
  static const User sampleUser = User(
    id: 'user_001',
    name: 'Maria Clara',
    email: 'maria.clara@example.com',
    initials: 'MC',
    profilePictureUrl: null,
  );
}