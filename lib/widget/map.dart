import 'package:air_quality_flutter/bloc/airpollution_state.dart';
import 'package:air_quality_flutter/bloc/bloc.dart';
import 'package:air_quality_flutter/util/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';
import 'station_marker.dart';

Widget getMap(AirPollutionBloc bloc, [AirPollutionLoaded state]) {
  return FlutterMap(
    options: MapOptions(
        center: LatLng(49.770126, 15.0),
        onTap: (point) => bloc.dispatch(HideStationDetail()),
        zoom: 6.75,
        plugins: [
          MarkerClusterPlugin(),
        ]),
    layers: [
      TileLayerOptions(
        urlTemplate: MAP_TILES_URL_TEMPLATE,
        additionalOptions: {
          'accessToken': MAPBOX_TOKEN,
          'id': MAPBOX_ID,
        },
      ),
      getMarkerClusterLayerOptions(state, bloc)
    ],
  );
}

MarkerClusterLayerOptions getMarkerClusterLayerOptions(
    AirPollutionLoaded state, AirPollutionBloc bloc) {
  return MarkerClusterLayerOptions(
    maxClusterRadius: 100,
    height: 40,
    width: 40,
    fitBoundsOptions: FitBoundsOptions(
      padding: EdgeInsets.all(50),
    ),
    markers: state != null
        ? StationMarker.getStationMarkers(state, bloc)
        : List<Marker>(),
    polygonOptions: PolygonOptions(
        borderColor: Colors.blueAccent,
        color: Colors.black12,
        borderStrokeWidth: 3),
    builder: (context, markers) {
      StationMarker maximalIxMarker = StationMarker.getMaximalIx(markers);
      return FloatingActionButton(
        child: Text(maximalIxMarker.ix.toString()),
        backgroundColor:
            state.legend[maximalIxMarker.ix].color.withOpacity(0.8),
        onPressed: null,
      );
    },
  );
}
