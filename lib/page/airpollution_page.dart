import 'package:air_quality_flutter/bloc/airpollution_event.dart';
import 'package:air_quality_flutter/bloc/bloc.dart';
import 'package:air_quality_flutter/model/Component.dart';
import 'package:air_quality_flutter/model/Station.dart';
import 'package:air_quality_flutter/widget/map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AirPollutionPage extends StatefulWidget {
  AirPollutionPage({Key key}) : super(key: key);

  @override
  _AirPollutionPageState createState() => _AirPollutionPageState();
}

class _AirPollutionPageState extends State<AirPollutionPage> {
  final airPollutionBloc = AirPollutionBloc();

  @override
  void initState() {
    super.initState();
    airPollutionBloc.dispatch(GetAirPollution());
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      title: Text("Kvalita ovzduší v ČR"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _buildBar(context),
        body: BlocBuilder(
            bloc: airPollutionBloc,
            builder: (BuildContext context, AirPollutionState state) {
              // loading state
              if (state is AirPollutionLoading) {
                return Stack(
                  children: [
                    getMap(airPollutionBloc),
                    Container(
                        color: Colors.black54, child: Center(child: CircularProgressIndicator()))
                  ],
                );
              }

              // loaded state
              if (state is AirPollutionLoaded) {
                if (state.showDetail) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => onStationTapped(state.legend,
                      state.componentLegend, state.station, context, airPollutionBloc));
                } else if (state.controller != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => hideModalSheet(state));
                }
                return getMap(airPollutionBloc, state);
              }

              // no network
              if (state is AirPollutionNoNetwork) {
                return Container(
                    child: Center(
                        child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.signal_cellular_connected_no_internet_4_bar, size: 30),
                    Padding(padding: EdgeInsets.only(top: 10)),
                    Text(
                        state.connectionDisabled
                            ? "Není dostupné připojení k internetu"
                            : "Nelze se připojit k databázi",
                        style: TextStyle(fontSize: 20)),
                  ],
                )));
              }

              return Text("Vyskytla se neočekávaná chyba");
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            airPollutionBloc.dispatch(GetAirPollution());
          },
          tooltip: 'Aktualizovat',
          child: Icon(Icons.refresh),
        ),
        drawer: Drawer(
          child: Column(
            children: [
              _buildMenu(),
              Padding(
                padding: const EdgeInsets.all(1.0),
                child: Text("Zdroj dat: ČHMÚ"),
              ),
              Padding(
                padding: const EdgeInsets.all(1.0),
                child: Text("Zdroj map: mapy.cz"),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Stanislav Král " + DateTime.now().year.toString()),
              )
            ],
          ),
        ));
  }

  Widget _buildMenu() {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.all(0),
        children: <Widget>[
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('graphics/material_forest.png'), fit: BoxFit.fill)),
            accountName: Text("Další nastavení",
                style: TextStyle(
                    fontSize: 18, shadows: [Shadow(offset: Offset(0.0, 0.0), blurRadius: 5.0)])),
          ),
          BlocBuilder(
              bloc: airPollutionBloc,
              builder: (BuildContext context, AirPollutionState state) {
                if (state is AirPollutionLoaded) {
                  return CheckboxListTile(
                    value: state.showForeignStations,
                    secondary: Icon(Icons.language),
                    title: Text("Zobrazit sousední státy"),
                    onChanged: (bool value) =>
                        airPollutionBloc.dispatch(ForeignStationsToggle(value)),
                  );
                }
                return Container(
                  child: Center(child: Text("Nedostupné")),
                );
              }),
        ],
      ),
    );
  }

  hideModalSheet(AirPollutionLoaded state) {
    state.controller.close();
    state.controller = null;
  }
}

void onStationTapped(var _legend, var _componentLegend, Station station, BuildContext context,
    AirPollutionBloc bloc) async {
  PersistentBottomSheetController<void> controller =
      _buildStationDetailBottomSheet(context, station, _legend, _componentLegend);

  bloc.dispatch(DetailControllerRetrieved(controller));

  await controller.closed;
  AirPollutionState state = bloc.currentState;
  if (state is AirPollutionLoaded) {
    bloc.dispatch(HideStationDetail());
  }
}

PersistentBottomSheetController<void> _buildStationDetailBottomSheet(
    BuildContext context, Station station, _legend, _componentLegend) {
  print(station);
  var controller = showBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.black12))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Wrap(children: <Widget>[
                  Padding(
                      padding: EdgeInsets.all(20), child: Text(station.name, textScaleFactor: 2))
                ]),
                Text(
                  "Vlastník: " + station.owner,
                  style: Theme.of(context).textTheme.body1,
                ),
                _buildBottomSheetBody(_legend, station),
                Divider(),
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                  child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 10,
                      children: _buildComponentsWidget(station, _componentLegend, _legend)),
                )
              ],
            ),
          ),
        );
      });
  return controller;
}

Widget _buildBottomSheetBody(_legend, Station station) {
  return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: Container(
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.cloud,
                    color:
                        _legend.containsKey(station.ix) ? _legend[station.ix].color : Colors.grey),
              ),
            ),
          ),
          Text(_legend[station.ix].description + (station.ix != 0 ? " kvalita ovzduší" : ""))
        ],
      ),
    ),
  );
}

List<Widget> _buildComponentsWidget(Station station, _componentLegend, _legend) {
  var componentsWidgets = List<Widget>();

  for (Component component in station.components) {
    if (component.value >= 0) {
      componentsWidgets.add(Tooltip(
        message: _componentLegend[component.code].name,
        child: Chip(
            backgroundColor:
                _legend.containsKey(component.ix) ? _legend[component.ix].color : Colors.grey,
            label: Text(_componentLegend[component.code].code +
                (" - " +
                    component.value.toString() +
                    " " +
                    _componentLegend[component.code].unit))),
      ));
    }
  }
  return componentsWidgets;
}
