import 'package:shared_preferences/shared_preferences.dart';
import 'trip_model.dart';

class HistoryRepository {
  static const String _key = 'trip_history';

  Future<void> saveTrip(TripModel trip) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    
    // Add new trip to the beginning of the list
    history.insert(0, trip.toJson());
    
    await prefs.setStringList(_key, history);
  }

  Future<List<TripModel>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_key) ?? [];
    
    return history.map((e) => TripModel.fromJson(e)).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
