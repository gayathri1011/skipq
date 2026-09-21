sealed class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.role,
  });

  final String id;
  final String name;
  final UserRole role;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final role = UserRoleX.fromString(json['role'] as String? ?? '');
    if (role == UserRole.manager) {
      return ManagerUser(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        managerId: json['managerId'] as String? ?? '',
      );
    }
    return StudentUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      registerNumber: json['registerNumber'] as String? ?? '',
      department: json['department'] as String? ?? '',
      academicStream: json['academicStream'] as String? ?? '',
    );
  }
}

enum UserRole { student, manager }

extension UserRoleX on UserRole {
  static UserRole fromString(String value) {
    return value == 'manager' ? UserRole.manager : UserRole.student;
  }

  String get value => name;
}

class StudentUser extends AppUser {
  const StudentUser({
    required super.id,
    required super.name,
    required this.mobile,
    this.registerNumber = '',
    this.department = '',
    this.academicStream = '',
  }) : super(role: UserRole.student);

  final String mobile;
  final String registerNumber;
  final String department;
  final String academicStream;
}

class ManagerUser extends AppUser {
  const ManagerUser({
    required super.id,
    required super.name,
    required this.managerId,
  }) : super(role: UserRole.manager);

  final String managerId;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}
