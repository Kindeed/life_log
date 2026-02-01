import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'weather_controller.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Put controller if not exists
    final controller = Get.put(WeatherController());

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3383FD), Color(0xFF1A73E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white70,
              ),
            ),
          );
        }

        if (controller.errorMessage.isNotEmpty) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.white70, size: 18),
              SizedBox(width: 8.w),
              Text(
                controller.errorMessage.value,
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: controller.fetchWeather,
                child: const Icon(Icons.refresh, color: Colors.white, size: 18),
              ),
            ],
          );
        }

        final data = controller.weatherData.value;
        if (data == null) return const SizedBox.shrink();

        final temp = data['temperature']?.toStringAsFixed(1) ?? "--";
        // Caiyun gives skycon id like 'CLEAR_DAY', map to text/icon if needed
        // Simplification for now
        final skycon = data['skycon'] ?? "UNKNOWN";

        return Row(
          children: [
            // Temp
            Text(
              "$temp°",
              style: TextStyle(
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16.w),

            // Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _skyconToText(skycon),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "空气质量: ${data['air_quality']?['description']?['chn'] ?? '良'}",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(_skyconToIcon(skycon), size: 40.sp, color: Colors.white),
          ],
        );
      }),
    );
  }

  String _skyconToText(String skycon) {
    switch (skycon) {
      case 'CLEAR_DAY':
        return '晴';
      case 'CLEAR_NIGHT':
        return '晴夜';
      case 'PARTLY_CLOUDY_DAY':
        return '多云';
      case 'PARTLY_CLOUDY_NIGHT':
        return '多云';
      case 'CLOUDY':
        return '阴';
      case 'LIGHT_HAZE':
        return '轻霾';
      case 'MODERATE_HAZE':
        return '中霾';
      case 'HEAVY_HAZE':
        return '重霾';
      case 'LIGHT_RAIN':
        return '小雨';
      case 'MODERATE_RAIN':
        return '中雨';
      case 'HEAVY_RAIN':
        return '大雨';
      case 'STORM_RAIN':
        return '暴雨';
      case 'FOG':
        return '雾';
      case 'LIGHT_SNOW':
        return '小雪';
      case 'MODERATE_SNOW':
        return '中雪';
      case 'HEAVY_SNOW':
        return '大雪';
      case 'STORM_SNOW':
        return '暴雪';
      case 'DUST':
        return '浮尘';
      case 'SAND':
        return '沙尘';
      case 'WIND':
        return '大风';
      default:
        return skycon;
    }
  }

  IconData _skyconToIcon(String skycon) {
    switch (skycon) {
      case 'CLEAR_DAY':
        return Icons.wb_sunny_rounded;
      case 'CLEAR_NIGHT':
        return Icons.nightlight_round;
      case 'PARTLY_CLOUDY_DAY':
      case 'PARTLY_CLOUDY_NIGHT':
        return Icons.cloud_queue_rounded;
      case 'CLOUDY':
        return Icons.cloud_rounded;
      case 'LIGHT_RAIN':
      case 'MODERATE_RAIN':
        return Icons.grain_rounded;
      case 'HEAVY_RAIN':
      case 'STORM_RAIN':
        return Icons.thunderstorm_rounded;
      case 'FOG':
      case 'LIGHT_HAZE':
      case 'MODERATE_HAZE':
        return Icons.foggy;
      case 'LIGHT_SNOW':
      case 'MODERATE_SNOW':
        return Icons.ac_unit_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }
}
