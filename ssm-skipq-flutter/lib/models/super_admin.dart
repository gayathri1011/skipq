class ManagedManager {
  const ManagedManager(
      {required this.id,
      required this.name,
      required this.managerId,
      this.passwordMasked = '********',
      this.passwordPlain});

  final String id;
  final String name;
  final String managerId;
  final String passwordMasked;
  final String? passwordPlain;

  factory ManagedManager.fromJson(Map<String, dynamic> json) => ManagedManager(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        managerId: json['managerId'] as String? ?? '',
        passwordMasked: json['passwordMasked'] as String? ?? '********',
        passwordPlain: json['passwordPlain'] as String?,
      );
}
