import 'package:flutter_test/flutter_test.dart';
import 'package:lastcheck_app/core/gcj.dart';

void main() {
  group('GCJ-02 坐标转换', () {
    test('境外坐标不偏移', () {
      final p = wgsToGcj(40.7128, -74.0060); // 纽约
      expect(p.latitude, closeTo(40.7128, 1e-9));
      expect(p.longitude, closeTo(-74.0060, 1e-9));
    });

    test('国内坐标会产生偏移（火星坐标）', () {
      final p = wgsToGcj(28.228209, 112.938814); // 长沙
      // 偏移量通常几百米（约 0.002~0.005 度）
      expect((p.latitude - 28.228209).abs(), greaterThan(0.001));
      expect((p.longitude - 112.938814).abs(), greaterThan(0.001));
    });

    test('wgs->gcj->wgs 往返误差 < 1e-4 度', () {
      final gcj = wgsToGcj(28.228209, 112.938814);
      final back = gcjToWgs(gcj.latitude, gcj.longitude);
      expect(back.latitude, closeTo(28.228209, 1e-4));
      expect(back.longitude, closeTo(112.938814, 1e-4));
    });

    test('gcj->wgs->gcj 往返误差 < 1e-4 度', () {
      final wgs = gcjToWgs(28.2300, 112.9400);
      final back = wgsToGcj(wgs.latitude, wgs.longitude);
      expect(back.latitude, closeTo(28.2300, 1e-4));
      expect(back.longitude, closeTo(112.9400, 1e-4));
    });
  });
}
