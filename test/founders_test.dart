import 'package:flutter_test/flutter_test.dart';
import 'package:mt_alchemy/data/mock/founders.dart';
import 'package:mt_alchemy/data/models/founder.dart';
import 'package:mt_alchemy/state/catalog_store.dart';

import 'helpers/fake_backend.dart';

void main() {
  test('the three founders are listed with their names as given', () {
    expect(founders.map((f) => f.name), [
      'AJAY A.N',
      'MAAHIR FAHEEM',
      'TANUJ SAKTHI KUMAR',
    ]);
  });

  test('initials for the photo placeholder', () {
    expect(founders[0].initials, 'AA');
    expect(founders[1].initials, 'MF');
    expect(founders[2].initials, 'TS');
    expect(const Founder(id: 'x', name: 'Cher').initials, 'C');
  });

  test(
    'founders load live and an uploaded photo is saved and read back',
    () async {
      final s = await FakeSession.signedIn();
      final store = CatalogStore(s.backend);
      // Nothing in Firestore yet: the bundled founders show.
      expect(store.founders, hasLength(3));
      for (final f in founders) {
        await s.db.collection('founders').doc(f.id).set(f.toMap());
      }
      await settle();
      expect(store.founders.map((f) => f.id), founders.map((f) => f.id));
      const photo = 'data:image/jpeg;base64,/9j/4AAQSkZJRg==';
      expect(await store.setFounderPhoto(founders.first, photo), isNull);
      await settle();
      expect(store.founders.first.imageUrl, photo);
      expect(store.founders.first.name, 'AJAY A.N');
    },
  );
}
