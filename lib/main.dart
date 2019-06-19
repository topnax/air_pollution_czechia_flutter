import 'dart:collection';
import 'dart:convert' as convert;

import 'package:air_quality_flutter/model/Station.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:http/http.dart' as http;
import 'package:latlong/latlong.dart';

import 'model/Component.dart';
import 'model/ComponentLegendItem.dart';
import 'model/Legend.dart';

const APP_VERSION = "0.1";
const APP_NAME = "air_pollution_cz";
const MAP_TILES_URL_TEMPLATE =
    "https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}";
const MAPBOX_TOKEN =
    'pk.eyJ1IjoidG9wbmF4IiwiYSI6ImNqd3lwdms1NzB0MWM0NXBtbjYycmpyZ2QifQ.ZacRcqj5LhfmQBy6MlP4ew';
const MAPBOX_ID = 'mapbox.streets';
const DATASET_URL =
    "http://portal.chmi.cz/files/portal/docs/uoco/web_generator/aqindex_cze.json";

void main() => runApp(AirPollutionApp());

class AirPollutionApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kvalita vzduchu v ČR',
      theme: ThemeData.light(),
      home: HomePage(title: "Kvalita ovzduší v ČR"),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //// List of stations
  List _stations;

  // A legend for quality levels
  Map _legend;

  //// a flag indicating whether we are loading stations
  bool _loading = true;

  //// a flag indicating whetehr we should display stations from foreign states
  bool _showForeignStates = false;

  //// a legend for components for measurements
  Map _componentLegend;

  //// a list of station markers
  List<StationMarker> _markers;

  //// cluster layer options
  var _markerClusterLayerOptions;

  @override
  void initState() {
    super.initState();
    loadDataset();
  }

  @override
  Widget build(BuildContext context) {
    var map = _stations != null ? getMap(context) : Container();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(children: <Widget>[
        map,
        _loading
            ? Container(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()))
            : Container()
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          onRefreshTapped();
        },
        tooltip: 'Aktualizovat',
        child: Icon(Icons.refresh),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName:
                  Text("Další nastavení", style: TextStyle(fontSize: 16)),
            ),
            CheckboxListTile(
              value: _showForeignStates,
              secondary: Icon(Icons.language),
              title: Text("Zobrazit sousední státy"),
              onChanged: (bool value) {
                loadDataset();
                _showForeignStates = value;
              },
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  FlutterMap getMap(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
          center: LatLng(49.770126, 13.368221),
          zoom: 13.0,
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
        _markerClusterLayerOptions,
      ],
    );
  }

  MarkerClusterLayerOptions getMarkerClusterLayerOptions() {
    return MarkerClusterLayerOptions(
      maxClusterRadius: 20,
      height: 40,
      width: 40,
      fitBoundsOptions: FitBoundsOptions(
        padding: EdgeInsets.all(50),
      ),
      markers: _markers,
      polygonOptions: PolygonOptions(
          borderColor: Colors.blueAccent,
          color: Colors.black12,
          borderStrokeWidth: 3),
      builder: (context, markers) {
        return FloatingActionButton(
          child: Text(getMaximalIx(markers)),
          backgroundColor: Colors.blue.withOpacity(0.8),
          onPressed: null,
        );
      },
    );
  }

  List<StationMarker> getStationMarkers() {
    var markers = List<StationMarker>();
    if (_stations != null) {
      for (Station station in _stations) {
        markers.add(new StationMarker(
          station.ix,
          width: 40.0,
          height: 40.0,
          point: new LatLng(station.lat, station.long),
          builder: (ctx) => InkWell(
              onTap: () => onStationTapped(station, ctx),
              child: Container(
                child: Center(child: Text(station.ix.toString())),
                decoration: BoxDecoration(
                  color:
                  station.clicked ? Colors.red : _legend[station.ix].color,
                  border: Border.all(width: 2.0, color: Colors.black),
                  borderRadius: station.clicked
                      ? BorderRadius.circular(10)
                      : BorderRadius.circular(45),
                ),
              )),
        ));
      }
    }

    print("markers len " + markers.length.toString());
    return markers;
  }

  void loadDataset() async {
    setState(() {
      _loading = true;
    });
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$APP_NAME $APP_VERSION";

    var response = await http.get(DATASET_URL, headers: headers);

    // Await the http get response, then decode the json-formatted response.
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
      _legend = parseLegend(jsonResponse);
      _componentLegend = parseComponents(jsonResponse);
      List stations = parseStations(jsonResponse);
      setState(() {
        this._loading = false;
        this._stations = stations;
        this._markers = getStationMarkers();
        this._markerClusterLayerOptions = getMarkerClusterLayerOptions();
      });
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
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

  Color hexToColor(String code) {
    return new Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
  }

  void onStationTapped(Station station, BuildContext context) async {
    setState(() {
      station.clicked = true;
    });

    var componentsWidgets = List<Widget>();

    for (Component component in station.components) {
      if (component.value >= 0) {
        componentsWidgets.add(InkWell(
          onTap: () {},
          child: Chip(
              backgroundColor: _legend.containsKey(component.ix)
                  ? _legend[component.ix].color
                  : Colors.grey,
              label: Text(_componentLegend[component.code].code +
                  (" - " +
                      component.value.toString() +
                      " " +
                      _componentLegend[component.code].unit))),
        ));
      }
    }

    await showBottomSheet<void>(
        context: context,
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black12))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Wrap(children: <Widget>[
                    Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(station.name, textScaleFactor: 2))
                  ]),
                  Text(
                    "Vlastník: " + station.owner,
                    style: Theme.of(context).textTheme.body1,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black54),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.cloud,
                                    color: _legend.containsKey(station.ix)
                                        ? _legend[station.ix].color
                                        : Colors.grey),
                              ),
                            ),
                          ),
                          Text(_legend[station.ix].description +
                              " kvalita ovzduší")
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                    child: Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 10,
                        children: componentsWidgets),
                  )
                ],
              ),
            ),
          );
        }).closed;
    setState(() {
      station.clicked = false;
    });
  }

  void onRefreshTapped() {
    loadDataset();
  }

  Map parseComponents(jsonResponse) {
    var components = Map();
    for (var componentJson in jsonResponse["Components"]) {
      components[componentJson["Code"]] = ComponentLegendItem(
          componentJson["Code"], componentJson["Name"], componentJson["Unit"]);
    }
    return components;
  }

  String getMaximalIx(List<Marker> markers) {
    return ((markers.reduce((curr, next) =>
            (curr as StationMarker).ix > (next as StationMarker).ix
                ? curr
                : next)) as StationMarker)
        .ix
        .toString();
  }
}

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
}
