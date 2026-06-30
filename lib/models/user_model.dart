/// Model data user
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? role;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.role,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      fullName: map['full_name'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: map['role'],
      createdAt: map['created_at'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }

  bool get isAdmin => role?.toLowerCase() == 'admin';
}
