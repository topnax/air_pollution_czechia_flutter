import 'dart:async';
import 'dart:convert' as convert;

import 'package:air_quality_flutter/model/Station.dart';
import "package:air_quality_flutter/services/preferences.dart" as preferences;
import 'package:air_quality_flutter/services/station_fetcher.dart' as StationFetcher;
import 'package:bloc/bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import './bloc.dart';
import 'airpollution_event.dart';

class AirPollutionBloc extends Bloc<AirPollutionEvent, AirPollutionState> {
  var legend;
  var componentLegend;
  List<Station> stations;
  var bottomSheetController = null;

  MapController mapController = new MapController();

  @override
  AirPollutionState get initialState => InitialAirpollutionState(false);

  @override
  Stream<AirPollutionState> mapEventToState(
    AirPollutionEvent event,
  ) async* {
    if (event is GetAirPollution) {
      bool showForeignStations = true;

      if (currentState is InitialAirpollutionState) {
        showForeignStations = await preferences.getForeignStations();
      }
      yield AirPollutionLoading();

      // Await the http get response, then decode the json-formatted response.
      try {
        var response = await StationFetcher.loadData();
        if (response.statusCode == 200) {
          parseResponse(response);
          yield AirPollutionLoaded(stations, legend, componentLegend, showForeignStations, false);
        } else {
          yield AirPollutionNoNetwork(false);
        }
      } on Exception {
        yield AirPollutionNoNetwork(true);
      }
    }

    if (event is HideStationDetail) {
      AirPollutionLoaded state = AirPollutionLoaded(
          stations,
          legend,
          componentLegend,
          currentState is AirPollutionLoaded
              ? (currentState as AirPollutionLoaded).showForeignStations
              : false,
          false);
      if (currentState is AirPollutionLoaded) {
        state.controller = (currentState as AirPollutionLoaded).controller;
      }
      yield state;
    }

    if (event is ShowStationDetail) {
      yield AirPollutionLoaded(
          stations,
          legend,
          componentLegend,
          currentState is AirPollutionLoaded
              ? (currentState as AirPollutionLoaded).showForeignStations
              : false,
          true,
          station: event.station);
    }

    if (event is DetailControllerRetrieved && currentState is AirPollutionLoaded) {
      (currentState as AirPollutionLoaded).controller = event.bottomSheetController;
    }

    if (event is ForeignStationsToggle) {
      yield AirPollutionLoaded(
          stations,
          legend,
          componentLegend,
          event.showForeignStations,
          currentState is AirPollutionLoaded
              ? (currentState as AirPollutionLoaded).showDetail
              : false);
      preferences.setForeignStations(event.showForeignStations);
    }
  }

  void parseResponse(http.Response response) {
    var jsonResponse = convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
    this.legend = StationFetcher.parseLegend(jsonResponse);
    this.componentLegend = StationFetcher.parseComponents(jsonResponse);
    this.stations = StationFetcher.parseStations(jsonResponse);
  }
}
