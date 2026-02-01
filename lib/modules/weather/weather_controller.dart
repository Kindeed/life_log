import 'package:get/get.dart';
import 'package:life_log/modules/weather/weather_service.dart';

class WeatherController extends GetxController {
  final weatherData = Rxn<Map<String, dynamic>>();
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      // OpenMeteo is free and keyless
      final result = await WeatherService().getRealtimeWeather();
      if (result != null) {
        weatherData.value = result;
      }
    } catch (e) {
      // Clean up error message
      String msg = e.toString().replaceAll("Exception: ", "");
      if (msg.contains("Location")) msg = "定位失败，请检查权限";
      if (msg.contains("SocketException")) msg = "网络连接失败";
      errorMessage.value = msg;
    } finally {
      isLoading.value = false;
    }
  }
}
