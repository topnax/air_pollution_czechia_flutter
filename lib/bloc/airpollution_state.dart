import 'package:air_quality_flutter/model/Station.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class AirPollutionState extends Equatable {
  AirPollutionState([List props = const []]) : super(props);
}

class InitialAirpollutionState extends AirPollutionState {
  final bool showForeignStations;

  InitialAirpollutionState(this.showForeignStations) : super([showForeignStations]);
}

class AirPollutionLoading extends AirPollutionState {}

class AirPollutionLoaded extends AirPollutionState {
  final bool search = false;
  final List<Station> stations;
  final legend;
  final componentLegend;
  final bool showForeignStations;
  final bool showDetail;
  var station;
  var controller;

  AirPollutionLoaded(
      this.stations, this.legend, this.componentLegend, this.showForeignStations, this.showDetail,
      {station: Station})
      : super([stations, legend, componentLegend, showForeignStations, showDetail, station]) {
    this.station = station;
  }
}

class AirPollutionNoNetwork extends AirPollutionState {
  final connectionDisabled;

  AirPollutionNoNetwork(this.connectionDisabled) : super([connectionDisabled]);
}
