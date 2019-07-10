import 'dart:collection';
import 'dart:convert' as convert;
import 'dart:async';
import 'dart:ui';
import 'package:air_quality_flutter/model/Component.dart';
import 'package:air_quality_flutter/model/ComponentLegendItem.dart';
import 'package:air_quality_flutter/model/Station.dart';
import 'package:air_quality_flutter/services/station_fetcher.dart'
    as StationFetcher;
import 'package:bloc/bloc.dart';
import './bloc.dart';
import 'package:air_quality_flutter/util/constants.dart';
import 'airpollution_event.dart';
import 'package:latlong/latlong.dart';
import "package:air_quality_flutter/services/preferences.dart" as preferences;
import 'package:http/http.dart' as http;

class AirPollutionBloc extends Bloc<AirPollutionEvent, AirPollutionState> {
  var legend;
  var componentLegend;
  List stations;

  @override
  AirPollutionState get initialState =>
      InitialAirpollutionState(preferences.getForeignStations);

  @override
  Stream<AirPollutionState> mapEventToState(
    AirPollutionEvent event,
  ) async* {
    if (event is GetAirPollution) {
      bool showForeignStations = true;

      if (currentState is InitialAirpollutionState) {
        showForeignStations =
            (currentState as InitialAirpollutionState).showForeignStations;
      }
      yield AirPollutionLoading();

      final response = await StationFetcher.loadData();

      yield AirPollutionNoNetwork();
      print("XOXOXO");
      if (response.statusCode == 200) {
        print("XOXOXO1");
        yield getLoadedState(response, showForeignStations);
//        yield AirPollutionLoaded(null, null, null, false);
      } else {
        print("XOXOXO2");
        yield AirPollutionNoNetwork();
      }
      print("XOEND");
    }
  }

  getLoadedState(http.Response response, bool showForeignStations) {
    var jsonResponse =
        convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
    var legend = StationFetcher.parseLegend(jsonResponse);
    var componentLegend = StationFetcher.parseComponents(jsonResponse);
    List<Station> stations =
        StationFetcher.parseStations(jsonResponse, showForeignStations);
    return AirPollutionLoaded(
        stations, legend, componentLegend, showForeignStations);
//            return AirPollutionLoaded(null, null, null, false);
  }
}
