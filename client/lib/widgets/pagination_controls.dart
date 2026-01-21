import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int page;
  final int totalCount;
  final int limit;
  final Function(int) onPageChanged;
  final bool isLoading;

  const PaginationControls({
    super.key,
    required this.page,
    required this.totalCount,
    required this.limit,
    required this.onPageChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalCount / limit).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: page > 1 && !isLoading ? () => onPageChanged(page - 1) : null,
        ),
        Text('Page $page of $totalPages ($totalCount items)'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: page < totalPages && !isLoading ? () => onPageChanged(page + 1) : null,
        ),
      ],
    );
  }
}
