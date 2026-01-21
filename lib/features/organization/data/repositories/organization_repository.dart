/// ============================================================================
/// ORGANIZATION REPOSITORY - HIPAA Compliant
/// ============================================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/app_config.dart';
import '../models/organization_model.dart';

class OrganizationRepository {
  final SupabaseClient _supabase = SupabaseService.client;

  // ============================================================================
  // MY ORGANIZATIONS
  // ============================================================================

  /// Get user's organizations
  Future<List<MyOrganizationModel>> getMyOrganizations() async {
    try {
      if (AppConfig.debugMode) {
        print('🏢 Fetching user organizations...');
      }

      final response = await _supabase
          .from('my_organizations')
          .select()
          .order('organization_name');

      final orgs = (response as List)
          .map((json) => MyOrganizationModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Organizations loaded: ${orgs.length}');
      }

      return orgs;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching organizations: $e');
      }
      rethrow;
    }
  }

  /// Get single organization details
  Future<OrganizationModel?> getOrganization(String organizationId) async {
    try {
      final response = await _supabase
          .from('organizations')
          .select()
          .eq('id', organizationId)
          .maybeSingle();

      if (response == null) return null;

      return OrganizationModel.fromJson(response);
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching organization: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // DEPARTMENTS
  // ============================================================================

  /// Get departments for an organization
  Future<List<DepartmentModel>> getDepartments(String organizationId) async {
    try {
      if (AppConfig.debugMode) {
        print('🏬 Fetching departments for org: $organizationId');
      }

      final response = await _supabase
          .from('organization_departments')
          .select()
          .eq('organization_id', organizationId)
          .order('display_order')
          .order('name');

      final depts = (response as List)
          .map((json) => DepartmentModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Departments loaded: ${depts.length}');
      }

      return depts;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching departments: $e');
      }
      rethrow;
    }
  }

  /// Create a new department
  Future<String> createDepartment({
    required String organizationId,
    required String name,
    String? description,
    String? color,
  }) async {
    try {
      if (AppConfig.debugMode) {
        print('➕ Creating department: $name');
      }

      final response = await _supabase.rpc('create_department', params: {
        'p_organization_id': organizationId,
        'p_name': name,
        'p_description': description,
        'p_color': color,
      });

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error creating department: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // COLLEAGUES
  // ============================================================================

  /// Get colleagues in an organization
  Future<List<ColleagueModel>> getColleagues(String organizationId) async {
    try {
      if (AppConfig.debugMode) {
        print('👥 Fetching colleagues for org: $organizationId');
      }

      final response = await _supabase
          .from('organization_colleagues')
          .select()
          .eq('organization_id', organizationId)
          .order('department_name')
          .order('first_name');

      final colleagues = (response as List)
          .map((json) => ColleagueModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Colleagues loaded: ${colleagues.length}');
      }

      return colleagues;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching colleagues: $e');
      }
      rethrow;
    }
  }

  /// Search colleagues
  Future<List<ColleagueModel>> searchColleagues(
    String organizationId,
    String query,
  ) async {
    try {
      final response = await _supabase
          .from('organization_colleagues')
          .select()
          .eq('organization_id', organizationId)
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%,display_name.ilike.%$query%,title.ilike.%$query%,specialization.ilike.%$query%')
          .order('first_name');

      return (response as List)
          .map((json) => ColleagueModel.fromJson(json))
          .toList();
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error searching colleagues: $e');
      }
      rethrow;
    }
  }

  /// Get colleagues by department
  Future<Map<String?, List<ColleagueModel>>> getColleaguesByDepartment(
    String organizationId,
  ) async {
    final colleagues = await getColleagues(organizationId);
    
    final Map<String?, List<ColleagueModel>> grouped = {};
    
    for (final colleague in colleagues) {
      final deptName = colleague.departmentName;
      if (!grouped.containsKey(deptName)) {
        grouped[deptName] = [];
      }
      grouped[deptName]!.add(colleague);
    }
    
    return grouped;
  }

  // ============================================================================
  // ORGANIZATION MANAGEMENT
  // ============================================================================

  /// Create a new organization
  Future<String> createOrganization({
    required String name,
    String type = 'hospital',
    String? description,
    String? city,
    String? state,
  }) async {
    try {
      if (AppConfig.debugMode) {
        print('🏢 Creating organization: $name');
      }

      final response = await _supabase.rpc('create_organization', params: {
        'p_name': name,
        'p_type': type,
        'p_description': description,
        'p_city': city,
        'p_state': state,
      });

      if (AppConfig.debugMode) {
        print('✅ Organization created: $response');
      }

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error creating organization: $e');
      }
      rethrow;
    }
  }

  /// Leave an organization
  Future<bool> leaveOrganization(String organizationId) async {
    try {
      if (AppConfig.debugMode) {
        print('🚪 Leaving organization: $organizationId');
      }

      final response = await _supabase.rpc('leave_organization', params: {
        'p_organization_id': organizationId,
      });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error leaving organization: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // INVITES
  // ============================================================================

  /// Get pending invites for current user
  Future<List<OrganizationInviteModel>> getMyPendingInvites() async {
    try {
      if (AppConfig.debugMode) {
        print('📬 Fetching pending invites...');
      }

      final response = await _supabase
          .from('my_pending_invites')
          .select()
          .order('created_at', ascending: false);

      final invites = (response as List)
          .map((json) => OrganizationInviteModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Pending invites loaded: ${invites.length}');
      }

      return invites;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching invites: $e');
      }
      rethrow;
    }
  }

  /// Create an invite code
  Future<String> createInvite({
    required String organizationId,
    String role = 'member',
    String? departmentId,
    String? email,
  }) async {
    try {
      if (AppConfig.debugMode) {
        print('📧 Creating invite for org: $organizationId');
      }

      final response = await _supabase.rpc('create_organization_invite', params: {
        'p_organization_id': organizationId,
        'p_role': role,
        'p_department_id': departmentId,
        'p_email': email,
      });

      if (AppConfig.debugMode) {
        print('✅ Invite code created: $response');
      }

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error creating invite: $e');
      }
      rethrow;
    }
  }

  /// Join organization using invite code
  Future<String> joinByInviteCode(String inviteCode) async {
    try {
      if (AppConfig.debugMode) {
        print('🔑 Joining with code: $inviteCode');
      }

      final response = await _supabase.rpc('join_organization_by_code', params: {
        'p_invite_code': inviteCode,
      });

      if (AppConfig.debugMode) {
        print('✅ Joined organization: $response');
      }

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error joining organization: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // MEMBER MANAGEMENT
  // ============================================================================

  /// Update member's department
  Future<bool> updateMemberDepartment({
    required String memberId,
    required String departmentId,
  }) async {
    try {
      final response = await _supabase.rpc('update_member_department', params: {
        'p_member_id': memberId,
        'p_department_id': departmentId,
      });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error updating member department: $e');
      }
      rethrow;
    }
  }
}
