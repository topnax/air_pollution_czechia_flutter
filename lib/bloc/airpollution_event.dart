import 'package:air_quality_flutter/model/Station.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

@immutable
abstract class AirPollutionEvent extends Equatable {
  AirPollutionEvent([List props = const []]) : super(props);
}

class GetAirPollution extends AirPollutionEvent {}

class ForeignStationsToggle extends AirPollutionEvent {
  final bool showForeignStations;

  ForeignStationsToggle(this.showForeignStations) : super([showForeignStations]);
}

class ShowStationDetail extends AirPollutionEvent {
  final Station station;

  ShowStationDetail(this.station) : super([station]);
}

class HideStationDetail extends AirPollutionEvent {
  HideStationDetail() : super();
}

class DetailControllerRetrieved extends AirPollutionEvent {
  final bottomSheetController;

  DetailControllerRetrieved(this.bottomSheetController) : super([bottomSheetController]);
}
