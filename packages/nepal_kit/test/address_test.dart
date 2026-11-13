import 'package:nepal_kit/nepal_kit.dart';
import 'package:test/test.dart';

void main() {
  test('7 provinces, 77 districts, 753 local levels', () {
    expect(NepalAddress.provinces, hasLength(7));
    expect(NepalAddress.districts, hasLength(77));
    expect(NepalAddress.localLevels, hasLength(753));
  });

  test('local levels by type match the official counts', () {
    int count(LocalLevelType t) =>
        NepalAddress.localLevels.where((l) => l.type == t).length;
    expect(count(LocalLevelType.metropolitan), 6);
    expect(count(LocalLevelType.subMetropolitan), 11);
    expect(count(LocalLevelType.municipality), 276);
    expect(count(LocalLevelType.rural), 460);
  });

  test('provinces in constitutional order, names in both languages', () {
    expect(NepalAddress.provinces.map((p) => p.nameEn), [
      'Koshi Province',
      'Madhesh Province',
      'Bagmati Province',
      'Gandaki Province',
      'Lumbini Province',
      'Karnali Province',
      'Sudurpaschim Province',
    ]);
    // The dataset types को as का + े; the generator fixes it.
    expect(NepalAddress.province(1)!.nameNe, 'कोशी प्रदेश');
    for (final p in NepalAddress.provinces) {
      expect(hasDevanagari(p.nameNe), isTrue);
    }
  });

  test('districts per province', () {
    expect(
      [for (final p in NepalAddress.provinces) p.districts.length],
      [14, 8, 13, 11, 12, 10, 9],
    );
  });

  test('every link resolves and every name is filled in', () {
    for (final d in NepalAddress.districts) {
      expect(d.province.id, d.provinceId);
      expect(d.nameEn, isNotEmpty);
      expect(hasDevanagari(d.nameNe), isTrue, reason: d.nameEn);
      expect(d.localLevels, isNotEmpty, reason: d.nameEn);
    }
    for (final l in NepalAddress.localLevels) {
      expect(l.district.id, l.districtId);
      expect(l.wards, inInclusiveRange(1, 40), reason: l.nameEn);
      expect(hasDevanagari(l.nameNe), isTrue, reason: l.nameEn);
      expect(l.nameNe.contains('ाे'), isFalse, reason: l.nameEn);
    }
  });

  test('Kathmandu', () {
    final ktm = NepalAddress.searchDistricts('kathmandu').single;
    expect(ktm.province.nameEn, 'Bagmati Province');
    final metro = ktm.localLevels.firstWhere(
      (l) => l.type == LocalLevelType.metropolitan,
    );
    expect(metro.nameEn, 'Kathmandu');
    expect(metro.wards, 32);
    expect(metro.name(withType: true), 'Kathmandu Metropolitan City');
    expect(ktm.localLevels, hasLength(11));
  });

  test('search ranks prefix matches first, works in Nepali, can narrow', () {
    final hits = NepalAddress.searchLocalLevels('pokhara');
    expect(hits.first.nameEn, 'Pokhara');
    expect(hits.first.type, LocalLevelType.metropolitan);
    expect(NepalAddress.searchLocalLevels('पोखरा').first.nameEn, 'Pokhara');
    expect(
      NepalAddress.searchLocalLevels(
        'nagar',
        provinceId: 1,
      ).every((l) => l.district.provinceId == 1),
      isTrue,
    );
    expect(NepalAddress.searchLocalLevels(''), isEmpty);
    expect(NepalAddress.searchLocalLevels('a', limit: 5), hasLength(5));
  });

  test('address formatting', () {
    final ktm = NepalAddress.searchDistricts('kathmandu').single;
    final metro = ktm.localLevels.firstWhere(
      (l) => l.type == LocalLevelType.metropolitan,
    );
    final a = NepaliAddress(
      province: ktm.province,
      district: ktm,
      localLevel: metro,
      ward: 10,
      street: 'Baneshwor',
    );
    expect(a.format(), 'Baneshwor, Kathmandu-10, Kathmandu, Bagmati Province');
    expect(
      a.format(nepali: true, includeProvince: false),
      'Baneshwor, ${metro.nameNe}-१०, ${ktm.nameNe}',
    );
  });
}
