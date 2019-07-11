import 'dart:collection';

import 'package:air_quality_flutter/model/Component.dart';
import 'package:air_quality_flutter/model/ComponentLegendItem.dart';
import 'package:air_quality_flutter/model/Legend.dart';
import 'package:air_quality_flutter/model/Station.dart';
import 'package:air_quality_flutter/util/color.dart' as Color;
import 'package:air_quality_flutter/util/constants.dart';
import 'package:http/http.dart' as http;


Future<http.Response> loadData() {
  Map<String, String> headers = new Map<String, String>();
  headers["User-Agent"] = "$APP_NAME $APP_VERSION";
  Future <http.Response> response = http.get(DATASET_URL, headers: headers);
  print("henlo");
  return response;
}

List<Station> parseStations(jsonResponse) {
  var requiredKeys = ["Name", "Owner", "Lat", "Lon", "Ix"];
  var stations = new List<Station>();
//  for (int h = 0;
//      h < (showForeignStations ? jsonResponse["States"].length : 1);
//      h++) {
  for (int stateIndex = 0; stateIndex < (jsonResponse["States"].length); stateIndex++) {
    var regions = jsonResponse["States"][stateIndex]["Regions"];
    for (int i = 0; i < regions.length; i++) {
      var region = regions[i];
      for (var stationJson in region["Stations"]) {
        bool failed = false;
        for (var requiredKey in requiredKeys) {
          if (!stationJson.containsKey(requiredKey)) {
            failed = true;
            break;
          }
        }
        if (failed) {
          continue;
        }

        var components = List();

        if (stationJson["Components"] != null) {
          for (var componentJson in stationJson["Components"]) {
            var component = Component(componentJson["Code"],
                componentJson["Int"], componentJson["Ix"]);
            if (componentJson["Val"] != null) {
              component.value = double.tryParse(componentJson["Val"]) ?? 0;
            }
            components.add(component);
          }
        }

        stations.add(Station(
            stationJson["Name"],
            stationJson["Owner"],
            double.parse(stationJson["Lat"]),
            double.parse(stationJson["Lon"]),
            stationJson["Ix"],
            components,
        stateIndex));
      }
    }
  }
  return stations;
}

Map parseLegend(jsonResponse) {
  var legend = HashMap();
  for (int i = 0; i < jsonResponse["Legend"].length; i++) {
    var legendJson = jsonResponse["Legend"][i];
    var legendsItem = LegendItem(legendJson["Ix"],
        Color.hexToColor("#" + legendJson["Color"]), legendJson["Description"]);
    legend[legendsItem.ix] = legendsItem;
  }
  return legend;
}

Map parseComponents(jsonResponse) {
  var components = Map();
  for (var componentJson in jsonResponse["Components"]) {
    components[componentJson["Code"]] = ComponentLegendItem(
        componentJson["Code"], componentJson["Name"], componentJson["Unit"]);
  }
  return components;
}
