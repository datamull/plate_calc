import 'package:flutter_test/flutter_test.dart';
import 'package:plate_calc/utils/format.dart';

void main() {
  test('fmtWeight quita ceros sobrantes sin romper decimales', () {
    expect(fmtWeight(100), '100');
    expect(fmtWeight(2.5), '2.5');
    expect(fmtWeight(1.25), '1.25');
    expect(fmtWeight(1.05), '1.05'); // la v1 mostraba "15"
    expect(fmtWeight(100.05), '100.05'); // la v1 mostraba "10005"
    expect(fmtWeight(0), '0');
  });

  test('parseNumber acepta coma y punto', () {
    expect(parseNumber('102,5'), 102.5);
    expect(parseNumber(' 80 % '), 80);
    expect(parseNumber('abc'), isNull);
  });
}
