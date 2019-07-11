class Station {
  String name;
  String owner;
  double lat, long;
  int ix;
  bool clicked = false;
  List components;
  int state;

  Station(this.name, this.owner, this.lat, this.long, this.ix, this.components, this.state);

}