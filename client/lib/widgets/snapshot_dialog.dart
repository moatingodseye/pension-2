import 'package:flutter/material.dart';
import 'package:shared/models.dart';
import 'package:shared/models/account.dart';
import '../services/snapshotService.dart';
import 'package:intl/intl.dart';

class SnapshotsDialog extends StatefulWidget {
  final Account account;

  const SnapshotsDialog({super.key, required this.account});

  @override
  State<SnapshotsDialog> createState() => _SnapshotsDialogState();
}

class _SnapshotsDialogState extends State<SnapshotsDialog> {
  final SnapshotService _service = SnapshotService();
  List<AccountSnapshot> _snapshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _service.getSnapshots(widget.account.id!);
      setState(() => _snapshots = list);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _takeSnapshot() async {
    setState(() => _isLoading = true);
    try {
      await _service.createSnapshot(AccountSnapshot(
        accountId: widget.account.id!,
        value: widget.account.amount,
        date: DateTime.now(),
      ));
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Snapshots: ${widget.account.name}'),
      content: SizedBox(
        width: 400,
        height: 400,
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _takeSnapshot,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Snapshot (Current Value)'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _snapshots.isEmpty
                      ? const Center(child: Text('No snapshots yet.'))
                      : ListView.builder(
                          itemCount: _snapshots.length,
                          itemBuilder: (ctx, i) {
                            final s = _snapshots[i];
                            return ListTile(
                              leading: const Icon(Icons.history),
                              title: Text('£${s.value.toStringAsFixed(2)}'),
                              subtitle: Text(DateFormat('yyyy-MM-dd HH:mm').format(s.date)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}
