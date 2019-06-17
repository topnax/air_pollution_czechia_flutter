import 'dart:collection';

import 'package:air_quality_flutter/model/Station.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
// import 'package:flutter/services.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;

import 'model/Component.dart';
import 'model/ComponentLegendItem.dart';
import 'model/Legend.dart';

void main() => runApp(MyApp());

String appName = "Fluddit";
String appVersion = "0.1";

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kvalita vzduchu v ČR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: "Kvalita ovzduší v ČR"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String DATASET_URL =
      "http://portal.chmi.cz/files/portal/docs/uoco/web_generator/aqindex_cze.json";

  List stations;
  Map legend;
  bool loading = true;

  Map componentLegend;

  @override
  void initState() {
    super.initState();
    loadDataset();
  }

  @override
  Widget build(BuildContext context) {
    var map = buildFlutterMap(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(children: <Widget>[
        map,
        loading
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
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void loadDataset() async {
    setState(() {
      loading = true;
    });
    Map<String, String> headers = new Map<String, String>();
    headers["User-Agent"] = "$appName $appVersion";

    var response = await http.get(DATASET_URL, headers: headers);

    // Await the http get response, then decode the json-formatted response.
    if (response.statusCode == 200) {
      var jsonResponse =
          convert.jsonDecode(convert.utf8.decode(response.bodyBytes));
      legend = parseLegend(jsonResponse);
      componentLegend = parseComponents(jsonResponse);
      List stations = parseStations(jsonResponse);
      setState(() {
        this.loading = false;
        this.stations = stations;
      });
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
  }

  List parseStations(jsonResponse) {
    var requiredKeys = ["Name", "Owner", "Lat", "Lon", "Ix"];
    var stations = new List();
    var regions = jsonResponse["States"][0]["Regions"];
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
    return stations;
  }

  FlutterMap buildFlutterMap(BuildContext context) {
    return FlutterMap(
      options: new MapOptions(
        center: new LatLng(49.770126, 13.368221),
        zoom: 13.0,
      ),
      layers: [
        new TileLayerOptions(
          urlTemplate: "https://api.tiles.mapbox.com/v4/"
              "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
          additionalOptions: {
            'accessToken':
                'pk.eyJ1IjoidG9wbmF4IiwiYSI6ImNqd3lwdms1NzB0MWM0NXBtbjYycmpyZ2QifQ.ZacRcqj5LhfmQBy6MlP4ew',
            'id': 'mapbox.streets',
          },
        ),
        new MarkerLayerOptions(
          markers: getStationMarkers(context),
        ),
      ],
    );
  }

  List<Marker> getStationMarkers(BuildContext context) {

    var markers = List<Marker>();
    if (stations != null) {
      for (var station in stations) {
        markers.add(new Marker(
          width: 40.0,
          height: 40.0,
          point: new LatLng(station.lat, station.long),
          builder: (ctx) => InkWell(
              onTap: () => onStationTapped(station, ctx),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 500),
                child: Center(child: Text(station.ix.toString())),
                curve: Curves.fastOutSlowIn,
                decoration: BoxDecoration(
                  color:
                      station.clicked ? Colors.red : legend[station.ix].color,
                  border: Border.all(width: 2.0, color: Colors.black),
                  borderRadius: station.clicked
                      ? BorderRadius.circular(10)
                      : BorderRadius.circular(45),
                ),
              )),
        ));
      }
    }
    return markers;
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

  onStationTapped(Station station, BuildContext context) async {

    setState(() {
      station.clicked = true;
    });

    var componentsWidgets = List<Widget>();

    for (Component component in station.components) {
      if (component.value >= 0) {
        componentsWidgets.add(InkWell(
          onTap: () {},
          child: Chip(
              backgroundColor: legend.containsKey(component.ix)
                  ? legend[component.ix].color
                  : Colors.grey,
              label: Text(componentLegend[component.code].code +
                  (" - " +
                      component.value.toString() +
                      " " +
                      componentLegend[component.code].unit))),
        ));
      }

//      componentsWidgets.add(ListTile(
//          leading: new Icon(Icons.info_outline),
//          title: new Text(component.code + " - " + component.value.toString())));
    }
    await showBottomSheet<void>(
        context: context,

        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black12))
              ),
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
                                  shape: BoxShape.circle, color: Colors.black54),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Icon(Icons.cloud,
                                    color: legend.containsKey(station.ix)
                                        ? legend[station.ix].color
                                        : Colors.grey),
                              ),
                            ),
                          ),
                          Text(
                              legend[station.ix].description + " kvalita ovzduší")
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.only(left:4.0, right:4.0),
                    child: Wrap(alignment:WrapAlignment.start, spacing: 10, children: componentsWidgets),
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

  onRefreshTapped() {
    loadDataset();
  }

  parseComponents(jsonResponse) {
    var components = Map();
    for (var componentJson in jsonResponse["Components"]) {
      components[componentJson["Code"]] = ComponentLegendItem(
          componentJson["Code"], componentJson["Name"], componentJson["Unit"]);
    }
    return components;
  }
}
