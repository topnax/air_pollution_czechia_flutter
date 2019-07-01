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
