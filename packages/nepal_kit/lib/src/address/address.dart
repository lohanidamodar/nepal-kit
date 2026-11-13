// Nepal's provinces, districts and local levels (palikas), for address
// pickers. Data: sagautam5/local-states-nepal (MIT), generated into
// address_data.dart by tool/gen_address_data.dart.
library;

import 'address_data.dart';

/// The kind of a local level (स्थानीय तह).
enum LocalLevelType {
  /// महानगरपालिका, Metropolitan City.
  metropolitan('Metropolitan City', 'महानगरपालिका'),

  /// उपमहानगरपालिका, Sub-Metropolitan City.
  subMetropolitan('Sub-Metropolitan City', 'उपमहानगरपालिका'),

  /// नगरपालिका, Municipality.
  municipality('Municipality', 'नगरपालिका'),

  /// गाउँपालिका, Rural Municipality.
  rural('Rural Municipality', 'गाउँपालिका');

  const LocalLevelType(this.nameEn, this.nameNe);

  /// English name.
  final String nameEn;

  /// Nepali name.
  final String nameNe;
}

/// One of Nepal's seven provinces.
class Province {
  /// A province; use [NepalAddress.provinces].
  const Province(this.id, this.nameEn, this.nameNe, this.headquarter);

  /// 1..7, the constitutional order (1 = Koshi).
  final int id;

  /// `Koshi Province`.
  final String nameEn;

  /// `कोशी प्रदेश`.
  final String nameNe;

  /// Capital, in English.
  final String headquarter;

  /// The name in [nepali] or English.
  String name({bool nepali = false}) => nepali ? nameNe : nameEn;

  /// Districts of this province.
  List<District> get districts => NepalAddress.districtsOf(id);

  @override
  String toString() => nameEn;
}

/// One of Nepal's 77 districts.
class District {
  /// A district; use [NepalAddress.districts].
  const District(
    this.id,
    this.provinceId,
    this.nameEn,
    this.nameNe,
    this.headquarter,
  );

  /// 1..77.
  final int id;

  /// [Province.id] of its province.
  final int provinceId;

  /// English name.
  final String nameEn;

  /// Nepali name.
  final String nameNe;

  /// District headquarters, in English (may be empty).
  final String headquarter;

  /// The name in [nepali] or English.
  String name({bool nepali = false}) => nepali ? nameNe : nameEn;

  /// Its province.
  Province get province => NepalAddress.province(provinceId)!;

  /// Its local levels.
  List<LocalLevel> get localLevels => NepalAddress.localLevelsOf(id);

  @override
  String toString() => nameEn;
}

/// One of Nepal's 753 local levels (municipalities and rural
/// municipalities).
class LocalLevel {
  /// A local level; use [NepalAddress.localLevels].
  const LocalLevel(
    this.id,
    this.districtId,
    this.nameEn,
    this.nameNe,
    this.type,
    this.wards,
  );

  /// 1..753, the dataset's id.
  final int id;

  /// [District.id] of its district.
  final int districtId;

  /// English name, without the type (`Kathmandu`).
  final String nameEn;

  /// Nepali name, without the type (`काठमाडौं`).
  final String nameNe;

  /// Metropolitan, sub-metropolitan, municipality or rural municipality.
  final LocalLevelType type;

  /// Number of wards.
  final int wards;

  /// The name in [nepali] or English, with the type when [withType]:
  /// `Kathmandu Metropolitan City`, `काठमाडौं महानगरपालिका`.
  String name({bool nepali = false, bool withType = false}) {
    final n = nepali ? nameNe : nameEn;
    return withType ? '$n ${nepali ? type.nameNe : type.nameEn}' : n;
  }

  /// Its district.
  District get district => NepalAddress.district(districtId)!;

  @override
  String toString() => '$nameEn ${type.nameEn}';
}

/// A structured Nepali address, as an address picker returns it.
class NepaliAddress {
  /// An address; every part is optional.
  const NepaliAddress({
    this.province,
    this.district,
    this.localLevel,
    this.ward,
    this.street,
  });

  /// Province.
  final Province? province;

  /// District.
  final District? district;

  /// Municipality or rural municipality.
  final LocalLevel? localLevel;

  /// Ward number.
  final int? ward;

  /// Tole / street, free text.
  final String? street;

  /// One line, most specific first:
  /// `Baneshwor, Kathmandu-10, Kathmandu, Bagmati Province`.
  String format({bool nepali = false, bool includeProvince = true}) {
    final parts = <String>[
      if (street != null && street!.trim().isNotEmpty) street!.trim(),
      if (localLevel != null)
        ward == null
            ? localLevel!.name(nepali: nepali)
            : '${localLevel!.name(nepali: nepali)}-${nepali ? _ne(ward!) : ward}',
      if (district != null) district!.name(nepali: nepali),
      if (includeProvince && province != null) province!.name(nepali: nepali),
    ];
    return parts.join(', ');
  }

  static String _ne(int n) =>
      n.toString().split('').map((c) => '०१२३४५६७८९'[int.parse(c)]).join();

  @override
  String toString() => format();
}

/// Lookups over the province, district and local-level tables.
abstract final class NepalAddress {
  /// The seven provinces, in order.
  static List<Province> get provinces => provinceData;

  /// All 77 districts.
  static List<District> get districts => districtData;

  /// All 753 local levels.
  static List<LocalLevel> get localLevels => localLevelData;

  /// The province with [id], or null.
  static Province? province(int id) =>
      id >= 1 && id <= provinceData.length ? provinceData[id - 1] : null;

  /// The district with [id], or null.
  static District? district(int id) => _districtById[id];

  /// The local level with [id], or null.
  static LocalLevel? localLevel(int id) => _localById[id];

  /// Districts of [provinceId], by English name.
  static List<District> districtsOf(int provinceId) =>
      _districtsByProvince[provinceId] ?? const [];

  /// Local levels of [districtId], by English name.
  static List<LocalLevel> localLevelsOf(int districtId) =>
      _localByDistrict[districtId] ?? const [];

  /// Local levels whose English or Nepali name contains [query] (case and
  /// spaces ignored), names that start with it first. Narrow with
  /// [districtId] or [provinceId].
  static List<LocalLevel> searchLocalLevels(
    String query, {
    int? districtId,
    int? provinceId,
    int limit = 20,
  }) {
    final q = _norm(query);
    if (q.isEmpty) return const [];
    final hits = <(int, LocalLevel)>[];
    for (final l in localLevelData) {
      if (districtId != null && l.districtId != districtId) continue;
      if (provinceId != null && l.district.provinceId != provinceId) continue;
      final en = _norm(l.nameEn), ne = _norm(l.nameNe);
      final rank = en.startsWith(q) || ne.startsWith(q)
          ? 0
          : en.contains(q) || ne.contains(q)
          ? 1
          : -1;
      if (rank >= 0) hits.add((rank, l));
    }
    hits.sort(
      (a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2.nameEn.compareTo(b.$2.nameEn),
    );
    return [for (final h in hits.take(limit)) h.$2];
  }

  /// Districts whose English or Nepali name contains [query].
  static List<District> searchDistricts(String query) {
    final q = _norm(query);
    if (q.isEmpty) return const [];
    return [
      for (final d in districtData)
        if (_norm(d.nameEn).contains(q) || _norm(d.nameNe).contains(q)) d,
    ];
  }

  static String _norm(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[\s\-]'), '');

  static final Map<int, District> _districtById = {
    for (final d in districtData) d.id: d,
  };

  static final Map<int, LocalLevel> _localById = {
    for (final l in localLevelData) l.id: l,
  };

  static final Map<int, List<District>> _districtsByProvince = () {
    final m = <int, List<District>>{};
    for (final d in districtData) {
      (m[d.provinceId] ??= []).add(d);
    }
    for (final l in m.values) {
      l.sort((a, b) => a.nameEn.compareTo(b.nameEn));
    }
    return m;
  }();

  static final Map<int, List<LocalLevel>> _localByDistrict = () {
    final m = <int, List<LocalLevel>>{};
    for (final l in localLevelData) {
      (m[l.districtId] ??= []).add(l);
    }
    for (final l in m.values) {
      l.sort((a, b) => a.nameEn.compareTo(b.nameEn));
    }
    return m;
  }();
}
