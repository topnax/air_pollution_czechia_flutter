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

  AirPollutionLoaded(this.stations, this.legend, this.componentLegend, this.showForeignStations)
      : super([stations, legend, componentLegend, showForeignStations]);
}

class AirPollutionNoNetwork extends AirPollutionState {}
