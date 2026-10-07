enum CampusRole { student, faculty, staff, security, visitor }

extension CampusRoleLabel on CampusRole {
  String get label {
    switch (this) {
      case CampusRole.student:
        return 'Student';
      case CampusRole.faculty:
        return 'Faculty';
      case CampusRole.staff:
        return 'Staff / Personnel';
      case CampusRole.security:
        return 'Security / Responder';
      case CampusRole.visitor:
        return 'Visitor';
    }
  }
}

class AppUser {
  const AppUser({
    required this.fullName,
    required this.email,
    required this.campusId,
    required this.role,
    required this.department,
    required this.phoneNumber,
    required this.wantsEmergencyLocationAlerts,
  });

  final String fullName;
  final String email;
  final String campusId;
  final CampusRole role;
  final String department;
  final String phoneNumber;

  /// Opt-in for alerts that carry the location of an active campus incident.
  final bool wantsEmergencyLocationAlerts;

  List<String> get _nameParts => fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((String part) => part.isNotEmpty)
      .toList();

  String get firstName {
    final List<String> parts = _nameParts;
    return parts.isEmpty ? fullName : parts.first;
  }

  String get initials {
    final List<String> parts = _nameParts;
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  AppUser copyWith({
    String? campusId,
    String? department,
    String? phoneNumber,
    bool? wantsEmergencyLocationAlerts,
  }) {
    return AppUser(
      fullName: fullName,
      email: email,
      campusId: campusId ?? this.campusId,
      role: role,
      department: department ?? this.department,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      wantsEmergencyLocationAlerts:
          wantsEmergencyLocationAlerts ?? this.wantsEmergencyLocationAlerts,
    );
  }
}
