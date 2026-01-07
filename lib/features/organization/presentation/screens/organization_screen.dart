import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';

class OrganizationScreen extends ConsumerStatefulWidget {
  const OrganizationScreen({super.key});

  @override
  ConsumerState<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends ConsumerState<OrganizationScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Mock Data for Organization Members
  final List<Map<String, dynamic>> _departments = [
    {
      'name': 'Cardiology',
      'members': [
        {
          'id': '101',
          'name': 'Dr. Sarah Wilson',
          'role': 'Head of Cardiology',
          'status': 'online',
          'image': 'SW',
        },
        {
          'id': '102',
          'name': 'Dr. James Chen',
          'role': 'Senior Cardiologist',
          'status': 'offline',
          'image': 'JC',
        },
      ]
    },
    {
      'name': 'Neurology',
      'members': [
        {
          'id': '103',
          'name': 'Dr. Gregory House',
          'role': 'Head of Diagnostics',
          'status': 'busy',
          'image': 'GH',
        },
        {
          'id': '104',
          'name': 'Dr. Lisa Cuddy',
          'role': 'Dean of Medicine',
          'status': 'online',
          'image': 'LC',
        },
      ]
    },
    {
      'name': 'Emergency',
      'members': [
        {
          'id': '105',
          'name': 'Dr. Allison Cameron',
          'role': 'Immunologist',
          'status': 'online',
          'image': 'AC',
        },
      ]
    },
  ];

  List<Map<String, dynamic>> _filteredDepartments = [];

  @override
  void initState() {
    super.initState();
    _filteredDepartments = List.from(_departments);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _filteredDepartments = List.from(_departments);
      } else {
        _filteredDepartments = _departments.map((dept) {
          final filteredMembers = (dept['members'] as List<Map<String, dynamic>>)
              .where((m) => 
                m['name'].toString().toLowerCase().contains(query) ||
                m['role'].toString().toLowerCase().contains(query))
              .toList();
          
          if (filteredMembers.isEmpty) return null;
          
          return {
            'name': dept['name'],
            'members': filteredMembers,
          };
        }).whereType<Map<String, dynamic>>().toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Organization',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mayo Clinic • San Fransisco',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search colleagues, departments...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    isDense: true,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _filteredDepartments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            'No members found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: _filteredDepartments.length,
                      itemBuilder: (context, index) {
                        final dept = _filteredDepartments[index];
                        return _buildDepartmentSection(dept);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentSection(Map<String, dynamic> dept) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Text(
            dept['name'].toString().toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...(dept['members'] as List<Map<String, dynamic>>).map((member) => _buildMemberCard(member)),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final statusColor = _getStatusColor(member['status']);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            // Navigate to Chat
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        member['image'],
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: statusColor,
                          border: Border.all(color: AppColors.surface, width: 2),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member['name'],
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        member['role'],
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Actions
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online': return AppColors.success;
      case 'busy': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }
}
