import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  // Mock Data with Location/Surroundings info
  final List<Map<String, dynamic>> _allContacts = [
    {
      'id': '1',
      'name': 'Dr. Sarah Wilson',
      'specialty': 'Cardiologist',
      'hospital': 'Mayo Clinic',
      'distance': '0.8 km',
      'mutual': 12,
      'status': 'new', // new, pending, added
      'image': 'SW',
    },
    {
      'id': '2',
      'name': 'Dr. James Chen',
      'specialty': 'Neurologist',
      'hospital': 'Johns Hopkins',
      'distance': '1.2 km',
      'mutual': 5,
      'status': 'added',
      'image': 'JC',
    },
    {
      'id': '3',
      'name': 'Dr. Emily Blunt',
      'specialty': 'Pediatrician',
      'hospital': 'Boston Childrens',
      'distance': '2.5 km',
      'mutual': 8,
      'status': 'new',
      'image': 'EB',
    },
    {
      'id': '4',
      'name': 'Dr. Michael Ross',
      'specialty': 'Surgeon',
      'hospital': 'Mount Sinai',
      'distance': '3.0 km',
      'mutual': 3,
      'status': 'new',
      'image': 'MR',
    },
    {
      'id': '5',
      'name': 'Dr. Linda Kim',
      'specialty': 'Dermatologist',
      'hospital': 'Cleveland Clinic',
      'distance': '5.0 km',
      'mutual': 15,
      'status': 'added',
      'image': 'LK',
    },
    {
      'id': '6',
      'name': 'Dr. Robert House',
      'specialty': 'Diagnostician',
      'hospital': 'Princeton Plainsboro',
      'distance': '0.5 km',
      'mutual': 42,
      'status': 'new',
      'image': 'RH',
    },
  ];

  List<Map<String, dynamic>> _filteredSuggestions = [];
  List<Map<String, dynamic>> _filteredNetwork = [];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTab = _tabController.index;
          _onSearchChanged(); // Re-filter based on new tab
        });
      }
    });

    _refreshLists();
    _searchController.addListener(_onSearchChanged);
  }

  void _refreshLists() {
    // Split into two lists based on status
    final allSuggestions = _allContacts.where((c) => c['status'] == 'new' || c['status'] == 'pending').toList();
    final allNetwork = _allContacts.where((c) => c['status'] == 'added').toList();

    setState(() {
      _filteredSuggestions = allSuggestions;
      _filteredNetwork = allNetwork;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      if (query.isEmpty) {
        _refreshLists();
      } else {
        // Filter Suggestions
        _filteredSuggestions = _allContacts
            .where((c) => (c['status'] == 'new' || c['status'] == 'pending') &&
                (c['name'].toLowerCase().contains(query) ||
                 c['specialty'].toLowerCase().contains(query)))
            .toList();

        // Filter Network
        _filteredNetwork = _allContacts
            .where((c) => c['status'] == 'added' &&
                (c['name'].toLowerCase().contains(query) ||
                 c['specialty'].toLowerCase().contains(query)))
            .toList();
      }
    });
  }

  void _connectWithDoctor(String id) {
    HapticFeedback.mediumImpact();
    
    setState(() {
      final index = _allContacts.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        // Optimistically update status
        _allContacts[index]['status'] = 'pending'; // Or 'added' directly for demo
        _refreshLists();
        _onSearchChanged(); // Re-apply search if active
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connection request sent'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'People',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  // Settings / Filter Icon could go here
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
                    onPressed: () {},
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
                    hintText: 'Search for doctors, hospitals...',
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

            // Custom Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                   AnimatedAlign(
                    alignment: _selectedTab == 0 ? Alignment.centerLeft : Alignment.centerRight,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 32) / 2,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Text(
                              'Suggestions',
                              style: TextStyle(
                                color: _selectedTab == 0 ? AppColors.textInverse : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Text(
                              'My Network',
                              style: TextStyle(
                                color: _selectedTab == 1 ? AppColors.textInverse : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedTab == 0
                    ? _buildSuggestionsList()
                    : _buildNetworkList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_filteredSuggestions.isEmpty) {
      return _buildEmptyState('No suggestions found nearby');
    }

    return ListView.builder(
      key: const ValueKey('Suggestions'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSuggestions.length + 1, // +1 for "Nearby" header
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Doctors in your area',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        }

        final doctor = _filteredSuggestions[index - 1];
        return _buildSuggestionCard(doctor);
      },
    );
  }

  Widget _buildNetworkList() {
    if (_filteredNetwork.isEmpty) {
      return _buildEmptyState('Your network is empty');
    }

    return ListView.builder(
      key: const ValueKey('Network'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredNetwork.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
           return const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Your colleagues',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        }
        final doctor = _filteredNetwork[index - 1];
        return _buildNetworkCard(doctor);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> doctor) {
    final bool isPending = doctor['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              doctor['image'],
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor['name'],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doctor['specialty']} • ${doctor['hospital']}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      doctor['distance'],
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                     Text(
                      '${doctor['mutual']} connections',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Button
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: isPending
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                    ),
                    child: const Text('Pending', style: TextStyle(fontSize: 12)),
                  )
                : ElevatedButton(
                    onPressed: () => _connectWithDoctor(doctor['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textInverse,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: const Text('Connect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(Map<String, dynamic> doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
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
                  doctor['image'],
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
                    color: Colors.green,
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
                  doctor['name'],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  doctor['specialty'],
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          
          // Message Button
          IconButton(
            onPressed: () {
               // Haptic feedback
               HapticFeedback.selectionClick();
               // TODO: Navigate to chat
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
