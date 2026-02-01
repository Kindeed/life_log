import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // Singleton
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  /// Fetches realtime weather data using OpenMeteo (No Key required)
  Future<Map<String, dynamic>?> getRealtimeWeather() async {
    try {
      double lng;
      double lat;

      try {
        // 1. Try get Location
        final position = await _determinePosition();
        lng = position.longitude;
        lat = position.latitude;
      } catch (e) {
        // Fallback: Beijing Zhongnanhai
        debugPrint("Location error: $e. Using default.");
        lng = 116.3975;
        lat = 39.9087;
      }

      // 2. Call OpenMeteo API (Free, No Key)
      final url =
          "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lng&current=temperature_2m,weather_code,is_day&timezone=auto";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];

        // Map WMO code to our internal Skycon format
        final wmoCode = current['weather_code'] as int;
        final isDay = current['is_day'] == 1;
        final skycon = _mapWmoToSkycon(wmoCode, isDay);

        return {
          'temperature': current['temperature_2m'],
          'skycon': skycon,
          'air_quality': {
            'description': {'chn': 'OpenMeteo'}, // No AQI in this endpoint
          },
        };
      } else {
        throw "Http Error: ${response.statusCode}";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  String _mapWmoToSkycon(int code, bool isDay) {
    // WMO Weather interpretation codes (WW)
    // 0: Clear sky
    if (code == 0) return isDay ? 'CLEAR_DAY' : 'CLEAR_NIGHT';

    // 1, 2, 3: Mainly clear, partly cloudy, and overcast
    if (code <= 3) return isDay ? 'PARTLY_CLOUDY_DAY' : 'PARTLY_CLOUDY_NIGHT';

    // 45, 48: Fog
    if (code == 45 || code == 48) return 'FOG';

    // 51, 53, 55: Drizzle
    if (code >= 51 && code <= 55) return 'LIGHT_RAIN';

    // 61, 63, 65: Rain
    if (code >= 61 && code <= 65) return 'MODERATE_RAIN';

    // 66, 67: Freezing Rain
    if (code == 66 || code == 67) return 'SLEET';

    // 71, 73, 75: Snow fall
    if (code >= 71 && code <= 77) return 'LIGHT_SNOW';

    // 80, 81, 82: Rain showers
    if (code >= 80 && code <= 82) return 'HEAVY_RAIN';

    // 85, 86: Snow showers
    if (code == 85 || code == 86) return 'HEAVY_SNOW';

    // 95, 96, 99: Thunderstorm
    if (code >= 95) return 'STORM_RAIN';

    return 'CLOUDY'; // Default
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return await Geolocator.getCurrentPosition();
  }
}
