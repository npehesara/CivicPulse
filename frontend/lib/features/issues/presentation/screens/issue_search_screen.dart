import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../users/presentation/screens/public_profile_screen.dart';
import '../../data/models/category_model.dart';
import '../../data/models/issue_model.dart';
import '../../data/models/status_model.dart';
import '../../data/models/territory_model.dart';
import '../../data/repositories/issue_repository.dart';
import '../widgets/issue_card.dart';
import 'issue_detail_screen.dart';

class IssueSearchScreen extends StatefulWidget {
  const IssueSearchScreen({super.key});

  @override
  State<IssueSearchScreen> createState() => _IssueSearchScreenState();
}

class _IssueSearchScreenState extends State<IssueSearchScreen> {
  final _searchController = TextEditingController();
  List<IssueModel> _searchResults = [];
  List<CategoryModel> _categories = [];
  List<TerritoryModel> _territories = [];
  List<StatusModel> _statuses = [];

  CategoryModel? _selectedCategory;
  TerritoryModel? _selectedTerritory;
  StatusModel? _selectedStatus;
  String? _selectedSeverity;

  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    final repo = context.read<IssueRepository>();
    try {
      final cats = await repo.getCategories();
      final terrs = await repo.getTerritories();
      final stats = await repo.getStatuses();
      if (mounted) {
        setState(() {
          _categories = cats;
          _territories = terrs;
          _statuses = stats;
        });
      }
    } catch (_) {}
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final repo = context.read<IssueRepository>();
      final results = await repo.getIssues(
        keyword: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        categoryId: _selectedCategory?.categoryId,
        territoryId: _selectedTerritory?.territoryId,
        statusId: _selectedStatus?.statusId,
        severity: _selectedSeverity,
        size: 50,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedTerritory = null;
      _selectedStatus = null;
      _selectedSeverity = null;
      _searchResults = [];
      _hasSearched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Search Civic Issues',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_hasSearched)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.background,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search by keyword (e.g. road, streetlight, trash)...',
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
                      onPressed: _performSearch,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderFocused, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Dropdowns Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Category Filter
                      _buildFilterChip<CategoryModel>(
                        label: _selectedCategory?.categoryName ?? 'Category',
                        isSelected: _selectedCategory != null,
                        items: _categories,
                        itemLabel: (c) => c.categoryName,
                        onSelected: (cat) {
                          setState(() => _selectedCategory = cat);
                          _performSearch();
                        },
                      ),
                      const SizedBox(width: 8),

                      // Severity Filter
                      _buildFilterChip<String>(
                        label: _selectedSeverity ?? 'Severity',
                        isSelected: _selectedSeverity != null,
                        items: const ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
                        itemLabel: (s) => s,
                        onSelected: (sev) {
                          setState(() => _selectedSeverity = sev);
                          _performSearch();
                        },
                      ),
                      const SizedBox(width: 8),

                      // Territory Filter
                      _buildFilterChip<TerritoryModel>(
                        label: _selectedTerritory?.territoryName ?? 'Territory',
                        isSelected: _selectedTerritory != null,
                        items: _territories,
                        itemLabel: (t) => t.territoryName,
                        onSelected: (terr) {
                          setState(() => _selectedTerritory = terr);
                          _performSearch();
                        },
                      ),
                      const SizedBox(width: 8),

                      // Status Filter
                      _buildFilterChip<StatusModel>(
                        label: _selectedStatus?.statusName ?? 'Status',
                        isSelected: _selectedStatus != null,
                        items: _statuses,
                        itemLabel: (st) => st.statusName,
                        onSelected: (st) {
                          setState(() => _selectedStatus = st);
                          _performSearch();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : !_hasSearched
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 54, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('Search civic issues across all public reports', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox_outlined, size: 54, color: AppColors.textMuted),
                                SizedBox(height: 12),
                                Text('No issues matched your search criteria', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final issue = _searchResults[index];
                              return IssueCard(
                                issue: issue,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => IssueDetailScreen(issueId: issue.issueId)),
                                  );
                                },
                                onReporterTap: () {
                                  if (issue.userId != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => PublicProfileScreen(userId: issue.userId!)),
                                    );
                                  }
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip<T>({
    required String label,
    required bool isSelected,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onSelected,
  }) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          return PopupMenuItem<T>(
            value: item,
            child: Text(itemLabel(item), style: const TextStyle(fontSize: 13)),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
