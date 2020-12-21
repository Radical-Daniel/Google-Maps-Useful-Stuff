import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../mate/BitmapMate.dart';
import '../mate/LocationMate.dart';

typedef OnMapReady = void Function();
typedef ClusterMarkerBuilder = Future<Marker> Function(Cluster<Marker>);

class MapWidget extends StatefulWidget {
  MapWidget({
    Key key,
    this.onMapReady,
  }) : super(key: key);

  final OnMapReady onMapReady;

  @override
  MapWidgetState createState() => MapWidgetState();
}

class MapWidgetState extends State<MapWidget> {
  static final CameraPosition initCameraPosition = CameraPosition(
    target: const LatLng(47.9632688, 24.1855044),
    zoom: 7.0,
  );

  StreamSubscription _currentLocationStreamSubscription;
  LatLng _currentLocationLatLng;
  GoogleMapController _mapController;
  ClusterManager _clusterManager;
  bool _alreadyAnimatedCamera = false;
  Set<Marker> _markerSet;
  Set<Marker> _defaultMarkerSet;
  Set<Polyline> _polylines;
  bool _showClusters = true;
  bool _showPolylines = false;

  @override
  void initState() {
    _initGeolocator();
    _initClusterManager();
    super.initState();
  }

  void _initGeolocator() {
    final Stream<Position> positionStream = Geolocator().getPositionStream(
        LocationOptions(accuracy: LocationAccuracy.medium, timeInterval: 3000));
    _currentLocationStreamSubscription =
        positionStream.listen((Position position) {
      _currentLocationLatLng = LatLng(position.latitude, position.longitude);
      _animateCameraToCurrentLocation();
    });
  }

  void _initClusterManager() {
    _clusterManager = ClusterManager<Marker>(
      [],
      _updateMarkersSet,
      markerBuilder: _markerBuilder,
      initialZoom: initCameraPosition.zoom,
      levels: [1, 3, 5, 6, 8.25, 10, 11.5, 13, 14.5, 16, 16.5, 20, 23, 27, 30],
    );
  }

  @override
  Widget build(BuildContext context) {
    Set<Marker> markers = _showClusters ? _markerSet : _defaultMarkerSet;
    Set<Circle> circles = {};
    Set<Polyline> polylines = _showPolylines ? _polylines : {};

    return GoogleMap(
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      mapType: MapType.normal,
      initialCameraPosition: initCameraPosition,
      onMapCreated: _onMapCreated,
      onCameraMove: _clusterManager.onCameraMove,
      onCameraIdle: _clusterManager.updateMap,
      markers: markers,
      circles: circles,
      polylines: polylines,
    );
  }

  @override
  void dispose() {
    _currentLocationStreamSubscription?.cancel();
    super.dispose();
  }

  void setMarkers(Set<Marker> markersSet) {
    this._defaultMarkerSet = markersSet.toSet();
    Set<Polyline> polylines = {};
    Marker previousMarker;
    for (Marker marker in markersSet) {
      if (previousMarker == null) {
        previousMarker = marker;
        continue;
      }
      final Polyline route = new Polyline(
          polylineId: PolylineId(marker.markerId.value),
          geodesic: false,
          points: [previousMarker.position, marker.position],
          width: 3,
          patterns: [
            PatternItem.dash(25),
            PatternItem.gap(25),
            PatternItem.dash(25)
          ],
          color: Colors.blue);
      polylines.add(route);
    }
    _polylines = polylines;
    _clusterManager.setItems(markersSet
        .map((Marker marker) =>
            ClusterItem<Marker>(marker.position, item: marker))
        .toList(growable: false));
    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _clusterManager.setMapController(controller);
    _animateCameraToCurrentLocation();
    widget.onMapReady?.call();
  }

  void _animateCameraToCurrentLocation() {
    if (_alreadyAnimatedCamera ||
        _mapController == null ||
        _currentLocationLatLng == null) {
      return;
    }
    _alreadyAnimatedCamera = true;
    _mapController
        .animateCamera(CameraUpdate.newLatLng(_currentLocationLatLng));
  }

  void _updateMarkersSet(Set<Marker> markersSet) {
    if (!mounted) {
      return;
    }
    setState(() {
      this._markerSet = markersSet;
    });
  }

  ClusterMarkerBuilder get _markerBuilder =>
      (cluster) async => !cluster.isMultiple
          ? cluster.items.first
          : Marker(
              markerId: MarkerId(cluster.getId()),
              position: cluster.location,
              consumeTapEvents: true,
              icon: await getMarkerBitmap(80 + cluster.count * 5,
                  text: cluster.count.toString()),
              onTap: () {
                LatLngBounds latLngBounds = LocationDispatcher.extremePoints(
                    cluster.items.map((item) => item.position).toList());
                _mapController.animateCamera(
                    CameraUpdate.newLatLngBounds(latLngBounds, 25));
              },
            );

  void setClusterMode(bool show) {
    if (!mounted) {
      return;
    }
    setState(() {
      _showClusters = show;
    });
  }

  void setPolylinesMode(bool show) {
    if (!mounted) {
      return;
    }
    setState(() {
      _showPolylines = show;
    });
  }
}
