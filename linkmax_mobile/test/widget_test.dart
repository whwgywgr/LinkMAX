import 'package:flutter_test/flutter_test.dart';
import 'package:linkmax_mobile/models.dart';
import 'package:linkmax_mobile/store.dart';

LinkItem mk(String id, String name, {int opens = 0, int? lastOpened}) => LinkItem(
      id: id,
      name: name,
      url: 'https://$id.example.com',
      categoryId: null,
      favicon: '',
      pinned: false,
      createdAt: 1000,
      openCount: opens,
      lastOpenedAt: lastOpened,
    );

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

  test('visible filters and sorts recent / most', () {
    final store = LinkStore();
    final now = DateTime.now().millisecondsSinceEpoch;
    store.links = [
      mk('a', 'A'),
      mk('b', 'B', opens: 3, lastOpened: now - 1000),
      mk('c', 'C', opens: 5, lastOpened: now - 5000),
      mk('d', 'D', opens: 1, lastOpened: now - 100),
    ];

    final recent = store.visible(
        categoryFilter: 'recent', query: '', sortMode: 'name');
    expect(recent.map((l) => l.name).toList(), ['D', 'B', 'C']);

    final most = store.visible(categoryFilter: 'most', query: '', sortMode: 'name');
    expect(most.map((l) => l.name).toList(), ['C', 'B', 'D']);

    store.recordOpen(store.links.firstWhere((l) => l.name == 'A'));
    expect(store.countForSmart('recent'), 4);
    expect(
      store.visible(categoryFilter: 'recent', query: '', sortMode: 'name')
          .first
          .name,
      'A',
    );
  });
}
