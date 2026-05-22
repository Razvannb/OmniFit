class User {
  final int? id;
  final String username;
  final String email;
  final String password; // Bcrypt hashed password

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id?.toString(),
      'username': username,
      'email': email,
    };
  }
}
