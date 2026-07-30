import 'package:isar/isar.dart';

part 'cached_search_model.g.dart';

@collection
class CachedSearchModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  late String query;

  late String resultsJson;

  @Index()
  late DateTime cachedAt;

  int? ttlMinutes;

  bool get isExpired {
    if (ttlMinutes == null) return false;
    return DateTime.now().isAfter(cachedAt.add(Duration(minutes: ttlMinutes!)));
  }

  static String normalizeQuery(String query) {
    return query.trim().toLowerCase();
  }
}
