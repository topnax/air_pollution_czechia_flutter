import 'package:air_quality_flutter/bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong/latlong.dart';
import 'package:air_quality_flutter/model/Station.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class StationMarker extends Marker {
  int ix;

  StationMarker(this.ix,
      {point, builder, width = 30.0, height = 30.0, AnchorPos anchorPos})
      : super(
            point: point,
            builder: builder,
            width: width,
            height: height,
            anchorPos: anchorPos);

  static List<StationMarker> getStationMarkers(
      AirPollutionLoaded state, AirPollutionBloc bloc) {
    var stations = state.stations;
    var showDetail = state.showDetail;
    var showForeignStations = state.showForeignStations;
    var markers = List<StationMarker>();
    var legend = state.legend;
    if (stations != null) {
      for (Station station in stations) {
        if (!showForeignStations && station.state != 0) {
          continue;
        }
        bool highlight = false;
        var size = 40.0;
        if (showDetail &&
            state.station != null && state.station is Station &&
            station.name == state.station.name) {
          highlight = true;
          size = 45.0;
        }
        markers.add(new StationMarker(
          station.ix,
          width: size,
          height: size,
          point: new LatLng(station.lat, station.long),
          builder: (ctx) => InkWell(
              onTap: () => bloc.dispatch(ShowStationDetail(station)),
              child: Container(
                child: Center(
                    child: Text(station.ix == 0 ? "?" : station.ix.toString())),
                decoration: BoxDecoration(
                  color: legend[station.ix].color,
                  boxShadow: highlight
                      ? [
                          new BoxShadow(
                            color: Colors.black87,
                            offset: new Offset(0.0, 0.0),
                            blurRadius: 7.0,
                          )
                        ]
                      : [],
                  border: Border.all(
                      width: highlight ? 3.0 : 2.0, color: Colors.black),
                  borderRadius: highlight
                      ? BorderRadius.circular(10)
                      : BorderRadius.circular(45),
                ),
              )),
        ));
      }
    }
    return markers;
  }

  static StationMarker getMaximalIx(List<Marker> markers) {
    return ((markers.reduce((curr, next) =>
        (curr as StationMarker).ix > (next as StationMarker).ix
            ? curr
            : next))) as StationMarker;
  }
}
