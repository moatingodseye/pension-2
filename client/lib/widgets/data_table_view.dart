import 'package:flutter/material.dart';

class DataTableView extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;
  final List<MainAxisAlignment>? columnAlignments;
  final VoidCallback? onAdd;
  final String? addLabel;

  const DataTableView({
    super.key,
    required this.headers,
    required this.rows,
    this.columnAlignments,
    this.onAdd,
    this.addLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
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

    // Determine flex or width for columns? use Table widgets or Row+Expanded?
    // Using a Header Row + ListView of Rows is easier for scrolling.
    
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
                flex: index == 0 ? 3 : 2, // First column slightly wider (Name/Description)
                child: Row(
                  mainAxisAlignment: _getAlignment(index),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                        child:   Text(
                          headers[index],
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                        ),
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
              return InkWell(
                onTap: () {}, // Handle row tap? Or let cells handle it?
                hoverColor: Colors.grey.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Compact padding
                  child: Row(
                    children: List.generate(cells.length, (cellIndex) {
                      return Expanded(
                        flex: cellIndex == 0 ? 3 : 2,
                        child: Row(
                          mainAxisAlignment: _getAlignment(cellIndex),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                                child:
//                                  if (cellIndex < cells.length)
                                    cells[cellIndex], // No Expanded here, let cell take natural width or be flexible? 
                                    // Actually if cell is Text it might overflow.
                                    // We should wrap cell in Flexible or Expanded if possible. 
                                    // But widget passed is generic. Assuming text/row.
                                ),
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
