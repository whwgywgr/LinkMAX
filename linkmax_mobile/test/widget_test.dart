import 'package:flutter_test/flutter_test.dart';
import 'package:linkmax_mobile/store.dart';

void main() {
  test('normalizeUrl adds https scheme', () {
    expect(normalizeUrl('github.com'), 'https://github.com');
    expect(normalizeUrl('https://x.com'), 'https://x.com');
  });

  test('hostOf strips www', () {
    expect(hostOf('https://www.github.com/a'), 'github.com');
    expect(hostOf('not a url'), '');
  });

  test('deriveName capitalizes domain', () {
    expect(deriveName('https://stackoverflow.com/q'), 'Stackoverflow');
  });
}
