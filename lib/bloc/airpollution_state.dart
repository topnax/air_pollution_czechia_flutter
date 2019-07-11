import 'package:air_quality_flutter/model/Station.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class AirPollutionState extends Equatable {
  AirPollutionState([List props = const []]) : super(props);
}

class InitialAirpollutionState extends AirPollutionState {
  bool showForeignStations;

  InitialAirpollutionState(this.showForeignStations) : super([showForeignStations]);
}

class AirPollutionLoading extends AirPollutionState {}

class AirPollutionLoaded extends AirPollutionState {
  final List<Station> stations;
  var legend;
  var componentLegend;
  final bool showForeignStations;
  final bool showDetail;
  var station;
  var controller = null;

  AirPollutionLoaded(this.stations, this.legend, this.componentLegend, this.showForeignStations, this.showDetail, {station: Station})
      : super([stations, legend, componentLegend, showForeignStations, showDetail, station]){
    this.station = station;
  }
}

class AirPollutionNoNetwork extends AirPollutionState {}
