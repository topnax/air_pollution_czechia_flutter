import 'dart:collection';
import 'dart:convert' as convert;
import 'dart:async';
import 'dart:ui';
import 'package:air_quality_flutter/model/Station.dart';
import 'package:bloc/bloc.dart';
import './bloc.dart';
import 'package:air_quality_flutter/util/constants.dart';
import 'airpollution_event.dart';
import 'package:http/http.dart' as http;
import 'package:latlong/latlong.dart';


class AirPollutionBloc extends Bloc<AirPollutionEvent, AirPollutionState> {
  @override
  AirPollutionState get initialState => InitialAirpollutionState();

  @override
  Stream<AirPollutionState> mapEventToState(AirPollutionEvent event,) async* {
    if (event is GetAirPollution) {
      yield AirPollutionLoading();

      final response = await _loadData();

      if (response.statusCode == 200) {
        yield getLoadedState(response);
      } else {
        yield AirPollutionNoNetwork();
      }
    }
  }

  Future<http.Response> _loadData() async {
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$APP_NAME $APP_VERSION";
    return http.get(DATASET_URL, headers: headers);
  }

  getLoadedState(http.Response response) {
    var jsonResponse =
    convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
    var legend = parseLegend(jsonResponse);
    var componentLegend = parseComponents(jsonResponse);
    List stations = parseStations(jsonResponse);
    return AirPollutionLoaded(stations, legend, componentLegend)
  }


  List parseStations(jsonResponse) {
    var requiredKeys = ["Name", "Owner", "Lat", "Lon", "Ix"];
    var stations = new List();
    for (int h = 0;
    h < (_showForeignStates ? jsonResponse["States"].length : 1);
    h++) {
      var regions = jsonResponse["States"][h]["Regions"];
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
              components));
        }
      }
    }
    return stations;
  }

  HashMap parseLegend(jsonResponse) {
    var legend = HashMap();
    for (int i = 0; i < jsonResponse["Legend"].length; i++) {
      var legendJson = jsonResponse["Legend"][i];
      var legendsItem = LegendItem(legendJson["Ix"],
          hexToColor("#" + legendJson["Color"]), legendJson["Description"]);
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


  Color hexToColor(String code) {
    return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }
}
