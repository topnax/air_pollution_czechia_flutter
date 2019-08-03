import 'package:shared_preferences/shared_preferences.dart';

const String SHOW_FOREIGN_STATIONS_KEY = "show_foreign_states";
const bool DEFAULT_FOREIGN_STATIONS_VALUE = false;

Future<bool> getForeignStations() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool showForeingStations = prefs.getBool(SHOW_FOREIGN_STATIONS_KEY) ?? false;
  return showForeingStations;
}

void setForeignStations(bool value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setBool(SHOW_FOREIGN_STATIONS_KEY, value);
}

