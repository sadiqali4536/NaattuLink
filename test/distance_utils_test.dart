import 'package:flutter_test/flutter_test.dart';
import 'package:naattulink/MVVM/utils/service_functions/distance_utils.dart';

void main() {
  group('DistanceUtils', () {
    test('Calculates correct distance between Kozhikode and Kochi (Approx 150-160km)', () {
      const latKozhikode = 11.2588;
      const lonKozhikode = 75.7804;

      const latKochi = 9.9312;
      const lonKochi = 76.2673;

      final distance = DistanceUtils.calculateDistanceKm(
        latKozhikode,
        lonKozhikode,
        latKochi,
        lonKochi,
      );

      // Distance should be around 157 km
      expect(distance, greaterThan(150.0));
      expect(distance, lessThan(165.0));
    });

    test('Distance to same point should be 0', () {
      const lat = 11.2588;
      const lon = 75.7804;

      final distance = DistanceUtils.calculateDistanceKm(
        lat, lon, lat, lon
      );

      expect(distance, 0.0);
    });

    test('Calculates correct distance between two close points (Approx 1km)', () {
      const lat1 = 11.2588;
      const lon1 = 75.7804;

      // Moving roughly 0.009 degrees latitude is ~1km
      const lat2 = 11.2678;
      const lon2 = 75.7804;

      final distance = DistanceUtils.calculateDistanceKm(
        lat1, lon1, lat2, lon2
      );

      expect(distance, closeTo(1.0, 0.05));
    });
  });
}
