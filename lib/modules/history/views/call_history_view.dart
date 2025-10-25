import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/widget/history/call_tile.dart';
import '../../../core/widget/history/filter_chip_pill.dart';
import '../../../core/widget/history/search_field.dart';
import '../models/call_history_item.dart';





class CallHistoryView extends StatelessWidget {
  const CallHistoryView({
    super.key,
    required this.items,
    required this.isLoading,
    required this.selectedFilter,
    required this.onFilterChange,
    required this.onSearchChanged,
    required this.onBack,
    required this.navBar, // pass your external bottom nav widget
    this.searchController,
    this.filterLabels = const [
      'All',
      'Call Back',
      'Intro Call',
      'Interested',
      'Demo',
      'Send Info',      
    ],
  });

  // Data
  final List<CallHistoryItem> items;
  final bool isLoading;
  final String selectedFilter;
  final List<String> filterLabels;

  // Callbacks
  final ValueChanged<String> onFilterChange;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onBack;

  // Search controller (optional, provided by parent for persistence)
  final TextEditingController? searchController;

  // External bottom navigation (design keeps it injected)
  final Widget navBar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Call History'),
          centerTitle: true,
          backgroundColor: cs.surface,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Search + filter icon
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          hintText: 'Search',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterIconButton(onTap: () {
                        // Optionally open advanced filter; parent can provide a callback if desired
                      }),
                    ],
                  ),
                ),
              ),

              // Status filter chips
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      for (final label in filterLabels) ...[
                        FilterChipPill(
                          label: label,
                          selected: selectedFilter == label,
                          onTap: () => onFilterChange(label),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),

              // Loading / Empty / List
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (items.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No history found')),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => Padding(
                    padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 0, 16, i == items.length - 1 ? 12 : 0),
                    child: CallTile(row: items[i]),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: navBar,
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const SizedBox(
          height: 48,
          width: 48,
          child: Center(child: Icon(Icons.filter_list)),
        ),
      ),
    );
  }
}
