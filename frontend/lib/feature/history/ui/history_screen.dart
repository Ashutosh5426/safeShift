import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/history_repository.dart';
import '../data/trip_model.dart';
import 'package:frontend/feature/common/common_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryRepository _repository = HistoryRepository();
  List<TripModel> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await _repository.getHistory();
    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(title: "Travel History"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text("No travel history yet."))
              : ListView.separated(
                  itemCount: _history.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final trip = _history[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.blue),
                      title: Text(trip.destinationName),
                      subtitle: Text(
                        "${DateFormat.yMMMd().add_jm().format(trip.startTime)}",
                      ),
                      // trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
    );
  }
}
