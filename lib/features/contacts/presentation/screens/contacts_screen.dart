import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Mock Data
  final List<Map<String, String>> _allContacts = [
    {
      'name': 'Dr. Sarah Wilson',
      'specialty': 'Cardiologist',
      'hospital': 'Mayo Clinic',
      'status': 'add'
    },
    {
      'name': 'Dr. James Chen',
      'specialty': 'Neurologist',
      'hospital': 'Johns Hopkins',
      'status': 'added'
    },
    {
      'name': 'Dr. Emily Blunt',
      'specialty': 'Pediatrician',
      'hospital': 'Boston Childrens',
      'status': 'add'
    },
    {
      'name': 'Dr. Michael Ross',
      'specialty': 'Surgeon',
      'hospital': 'Mount Sinai',
      'status': 'add'
    },
    {
      'name': 'Dr. Linda Kim',
      'specialty': 'Dermatologist',
      'hospital': 'Cleveland Clinic',
      'status': 'added'
    },
  ];

  List<Map<String, String>> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = _allContacts;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredContacts = _allContacts
          .where((contact) =>
              contact['name']!.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ) ||
              contact['specialty']!.toLowerCase().contains(
                    _searchController.text.toLowerCase(),
                  ))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Find Colleagues',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search doctors, specialties...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Quick Add / List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100), // Space for bottom bar
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                final isAdded = contact['status'] == 'added';

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surfaceLight,
                    child: Text(
                      contact['name']![0],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Text(
                    contact['name']!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${contact['specialty']} • ${contact['hospital']}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isAdded
                          ? AppColors.surfaceLight
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        isAdded ? 'Added' : 'Add',
                        style: TextStyle(
                          color: isAdded
                              ? AppColors.textSecondary
                              : AppColors.textInverse,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
