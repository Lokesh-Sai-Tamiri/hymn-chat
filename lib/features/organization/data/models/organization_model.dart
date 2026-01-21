/// ============================================================================
/// ORGANIZATION MODELS - HIPAA Compliant
/// ============================================================================
library;

/// Organization type enum
enum OrganizationType {
  hospital,
  clinic,
  practice,
  network,
  other,
}

/// Member role enum
enum MemberRole {
  owner,
  admin,
  head,
  member,
  staff,
  guest,
}

/// Member status enum
enum MemberStatus {
  active,
  inactive,
  pending,
  suspended,
}

/// Organization model
class OrganizationModel {
  final String id;
  final String name;
  final OrganizationType type;
  final String? description;
  final String? phone;
  final String? email;
  final String? website;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? logoUrl;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.phone,
    this.email,
    this.website,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.logoUrl,
    this.isPublic = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: _parseType(json['type'] as String?),
      description: json['description'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      country: json['country'] as String?,
      logoUrl: json['logo_url'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static OrganizationType _parseType(String? type) {
    switch (type) {
      case 'hospital':
        return OrganizationType.hospital;
      case 'clinic':
        return OrganizationType.clinic;
      case 'practice':
        return OrganizationType.practice;
      case 'network':
        return OrganizationType.network;
      default:
        return OrganizationType.other;
    }
  }

  String get location {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    return parts.join(', ');
  }

  String get typeDisplay {
    switch (type) {
      case OrganizationType.hospital:
        return 'Hospital';
      case OrganizationType.clinic:
        return 'Clinic';
      case OrganizationType.practice:
        return 'Practice';
      case OrganizationType.network:
        return 'Network';
      case OrganizationType.other:
        return 'Organization';
    }
  }
}

/// User's organization membership (from my_organizations view)
class MyOrganizationModel {
  final String organizationId;
  final String organizationName;
  final OrganizationType organizationType;
  final String? logoUrl;
  final String? city;
  final String? state;
  final MemberRole role;
  final String? title;
  final MemberStatus status;
  final DateTime? joinedAt;
  final String? departmentId;
  final String? departmentName;
  final int memberCount;

  const MyOrganizationModel({
    required this.organizationId,
    required this.organizationName,
    required this.organizationType,
    this.logoUrl,
    this.city,
    this.state,
    required this.role,
    this.title,
    required this.status,
    this.joinedAt,
    this.departmentId,
    this.departmentName,
    required this.memberCount,
  });

  factory MyOrganizationModel.fromJson(Map<String, dynamic> json) {
    return MyOrganizationModel(
      organizationId: json['organization_id'] as String,
      organizationName: json['organization_name'] as String,
      organizationType: OrganizationModel._parseType(json['organization_type'] as String?),
      logoUrl: json['logo_url'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      role: _parseRole(json['role'] as String?),
      title: json['title'] as String?,
      status: _parseStatus(json['status'] as String?),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      departmentId: json['department_id'] as String?,
      departmentName: json['department_name'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  static MemberRole _parseRole(String? role) {
    switch (role) {
      case 'owner':
        return MemberRole.owner;
      case 'admin':
        return MemberRole.admin;
      case 'head':
        return MemberRole.head;
      case 'staff':
        return MemberRole.staff;
      case 'guest':
        return MemberRole.guest;
      default:
        return MemberRole.member;
    }
  }

  static MemberStatus _parseStatus(String? status) {
    switch (status) {
      case 'active':
        return MemberStatus.active;
      case 'inactive':
        return MemberStatus.inactive;
      case 'pending':
        return MemberStatus.pending;
      case 'suspended':
        return MemberStatus.suspended;
      default:
        return MemberStatus.pending;
    }
  }

  String get location {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    return parts.join(', ');
  }

  String get roleDisplay {
    switch (role) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.head:
        return 'Department Head';
      case MemberRole.member:
        return 'Member';
      case MemberRole.staff:
        return 'Staff';
      case MemberRole.guest:
        return 'Guest';
    }
  }

  bool get isAdmin => role == MemberRole.owner || role == MemberRole.admin;
}

/// Department model
class DepartmentModel {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final int displayOrder;
  final String? headUserId;
  final String? headFirstName;
  final String? headLastName;
  final int memberCount;

  const DepartmentModel({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.color,
    this.icon,
    this.displayOrder = 0,
    this.headUserId,
    this.headFirstName,
    this.headLastName,
    this.memberCount = 0,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['department_id'] as String,
      organizationId: json['organization_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      headUserId: json['head_user_id'] as String?,
      headFirstName: json['head_first_name'] as String?,
      headLastName: json['head_last_name'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
    );
  }

  String? get headFullName {
    if (headFirstName != null && headLastName != null) {
      return '$headFirstName $headLastName';
    }
    return headFirstName ?? headLastName;
  }
}

/// Organization colleague (member with profile info)
class ColleagueModel {
  final String membershipId;
  final String organizationId;
  final String userId;
  final String? departmentId;
  final MemberRole role;
  final String? title;
  final MemberStatus status;
  final DateTime? joinedAt;
  final String? departmentName;
  final String? departmentColor;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? specialization;
  final String? avatarUrl;

  const ColleagueModel({
    required this.membershipId,
    required this.organizationId,
    required this.userId,
    this.departmentId,
    required this.role,
    this.title,
    required this.status,
    this.joinedAt,
    this.departmentName,
    this.departmentColor,
    this.firstName,
    this.lastName,
    this.displayName,
    this.specialization,
    this.avatarUrl,
  });

  factory ColleagueModel.fromJson(Map<String, dynamic> json) {
    return ColleagueModel(
      membershipId: json['membership_id'] as String,
      organizationId: json['organization_id'] as String,
      userId: json['user_id'] as String,
      departmentId: json['department_id'] as String?,
      role: MyOrganizationModel._parseRole(json['role'] as String?),
      title: json['title'] as String?,
      status: MyOrganizationModel._parseStatus(json['status'] as String?),
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      departmentName: json['department_name'] as String?,
      departmentColor: json['department_color'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      displayName: json['display_name'] as String?,
      specialization: json['specialization'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (displayName != null) {
      return displayName!;
    } else if (firstName != null) {
      return firstName!;
    }
    return 'Unknown';
  }

  String get initials {
    if (firstName != null && lastName != null) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    } else if (displayName != null && displayName!.isNotEmpty) {
      final parts = displayName!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return displayName![0].toUpperCase();
    }
    return '?';
  }

  String get roleDisplay {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    switch (role) {
      case MemberRole.owner:
        return 'Owner';
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.head:
        return 'Department Head';
      case MemberRole.member:
        return 'Member';
      case MemberRole.staff:
        return 'Staff';
      case MemberRole.guest:
        return 'Guest';
    }
  }
}

/// Pending organization invite
class OrganizationInviteModel {
  final String inviteId;
  final String organizationId;
  final MemberRole role;
  final String? departmentId;
  final String? inviteCode;
  final DateTime expiresAt;
  final DateTime createdAt;
  final String organizationName;
  final OrganizationType organizationType;
  final String? logoUrl;
  final String? city;
  final String? state;
  final String? departmentName;
  final String? inviterFirstName;
  final String? inviterLastName;

  const OrganizationInviteModel({
    required this.inviteId,
    required this.organizationId,
    required this.role,
    this.departmentId,
    this.inviteCode,
    required this.expiresAt,
    required this.createdAt,
    required this.organizationName,
    required this.organizationType,
    this.logoUrl,
    this.city,
    this.state,
    this.departmentName,
    this.inviterFirstName,
    this.inviterLastName,
  });

  factory OrganizationInviteModel.fromJson(Map<String, dynamic> json) {
    return OrganizationInviteModel(
      inviteId: json['invite_id'] as String,
      organizationId: json['organization_id'] as String,
      role: MyOrganizationModel._parseRole(json['role'] as String?),
      departmentId: json['department_id'] as String?,
      inviteCode: json['invite_code'] as String?,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      organizationName: json['organization_name'] as String,
      organizationType: OrganizationModel._parseType(json['organization_type'] as String?),
      logoUrl: json['logo_url'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      departmentName: json['department_name'] as String?,
      inviterFirstName: json['inviter_first_name'] as String?,
      inviterLastName: json['inviter_last_name'] as String?,
    );
  }

  String? get inviterFullName {
    if (inviterFirstName != null && inviterLastName != null) {
      return '$inviterFirstName $inviterLastName';
    }
    return inviterFirstName ?? inviterLastName;
  }

  String get location {
    final parts = <String>[];
    if (city != null) parts.add(city!);
    if (state != null) parts.add(state!);
    return parts.join(', ');
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
