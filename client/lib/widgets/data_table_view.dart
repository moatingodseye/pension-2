import 'package:flutter/material.dart';

class DataTableView extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<MainAxisAlignment>? columnAlignments;
  final VoidCallback? onAdd;
  final String? addLabel;
  final Function(int)? onRowTap;
  final int? selectedRowIndex;

  const DataTableView({
    super.key,
    required this.headers,
    required this.rows,
    this.columnAlignments,
    this.onAdd,
    this.addLabel,
    this.onRowTap,
    this.selectedRowIndex,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      // ... (keep existing empty state)
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No data available', style: TextStyle(color: Colors.grey)),
            if (onAdd != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(addLabel ?? 'Add Item'),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: List.generate(headers.length, (index) {
              return Expanded(
                flex: index == 0 ? 3 : 2,
                child: Row(
                  mainAxisAlignment: _getAlignment(index),
                  children: [
                    Text(
                      headers[index],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        
        // Rows
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, rowIndex) {
              final cells = rows[rowIndex];
              final isSelected = selectedRowIndex == rowIndex;
              
              return InkWell(
                onTap: onRowTap != null ? () => onRowTap!(rowIndex) : null,
                hoverColor: Colors.grey.shade50,
                child: Container(
                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: List.generate(cells.length, (cellIndex) {
                      return Expanded(
                        flex: cellIndex == 0 ? 3 : 2,
                        child: Row(
                          mainAxisAlignment: _getAlignment(cellIndex),
                          children: [
                             // Wrap cell in flexible if needed, but for now specific widgets handle it
                             cells[cellIndex],
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  MainAxisAlignment _getAlignment(int index) {
    if (columnAlignments != null && index < columnAlignments!.length) {
      return columnAlignments![index];
    }
    return MainAxisAlignment.start;
  }
}
