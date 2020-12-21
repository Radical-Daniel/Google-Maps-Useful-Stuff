import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationDispatcher {
  //Earth’s radius, sphere
  static const int EARTH_RADIUS_IN_KM = 6378137;

  static LatLng offsetByMeters(LatLng startPosition, double dx, double dy) {
    var dLat = dy / EARTH_RADIUS_IN_KM;
    var dLon =
        dx / (EARTH_RADIUS_IN_KM * cos(pi * startPosition.latitude / 180));

    var latO = startPosition.latitude + dLat * 180 / pi;
    var lonO = startPosition.longitude + dLon * 180 / pi;
    return LatLng(latO, lonO);
  }

  static offsetByKm(LatLng startPosition, double dx, double dy) =>
      offsetByMeters(startPosition, dx * 1000, dy * 1000);

  static double getDistanceInKm(
      double lat1, double lon1, double lat2, double lon2) {
    double earthRadius = 6378.137 /* 6371*/; // Radius of the earth in km
    double dLat = deg2rad(lat2 - lat1);
    double dLon = deg2rad(lon2 - lon1);
    double a = sin(dLat / 2.0) * sin(dLat / 2.0) +
        cos(deg2rad(lat1)) *
            cos(deg2rad(lat2)) *
            sin(dLon / 2.0) *
            sin(dLon / 2.0);

    double c = 2.0 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double getDistanceInKmOfLatLng(LatLng location1, LatLng location2) =>
      getDistanceInKm(location1.latitude, location1.longitude,
          location2.latitude, location2.longitude);

  static double deg2rad(double deg) => deg * (pi / 180);

  static LatLngBounds extremePoints(List<LatLng> points) {
    double south = points[0].latitude;
    double north = points[0].latitude;
    double west = points[0].longitude;
    double east = points[0].longitude;

    for (LatLng point in points) {
      if (point.longitude > east) {
        east = point.longitude;
      } else if (point.longitude < west) {
        west = point.longitude;
      }
      if (point.latitude > north) {
        north = point.latitude;
      } else if (point.latitude < south) {
        south = point.latitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  static LatLngBounds alignToCenterPoint(
      LatLng centerLatLng, LatLng sideLatLng) {
    double south = centerLatLng.latitude < sideLatLng.latitude
        ? (2 * centerLatLng.latitude - sideLatLng.latitude)
        : sideLatLng.latitude;
    double north = centerLatLng.latitude > sideLatLng.latitude
        ? (2 * centerLatLng.latitude - sideLatLng.latitude)
        : sideLatLng.latitude;
    double west = centerLatLng.longitude < sideLatLng.longitude
        ? (2 * centerLatLng.longitude - sideLatLng.longitude)
        : sideLatLng.longitude;
    double east = centerLatLng.longitude > sideLatLng.longitude
        ? (2 * centerLatLng.longitude - sideLatLng.longitude)
        : sideLatLng.longitude;

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }
}
