import 'package:flutter/foundation.dart';

/// A schedule category. One category per schedule; a schedule without one is
/// shown as Uncategorized (spec section 9.1).
@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.colorKey,
    required this.builtIn,
    required this.sortOrder,
  });

  final String id;
  final String name;

  /// Key into the tested category palette, or null for no color.
  final String? colorKey;
  final bool builtIn;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      other is Category &&
      other.id == id &&
      other.name == name &&
      other.colorKey == colorKey &&
      other.builtIn == builtIn &&
      other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(id, name, colorKey, builtIn, sortOrder);
}

/// Category visibility filter with OR semantics. "All" has no restriction
/// and includes Uncategorized. Filters never change alert activation.
@immutable
class CategoryFilter {
  const CategoryFilter.all()
      : categoryIds = const {},
        includeUncategorized = true,
        isAll = true;

  const CategoryFilter.only(this.categoryIds, {this.includeUncategorized = false}) : isAll = false;

  final Set<String> categoryIds;
  final bool includeUncategorized;
  final bool isAll;

  bool matches(String? categoryId) {
    if (isAll) return true;
    if (categoryId == null) return includeUncategorized;
    return categoryIds.contains(categoryId);
  }

  /// Drops ids that no longer exist; an empty selection becomes All.
  CategoryFilter retainExisting(Iterable<String> existingIds) {
    if (isAll) return this;
    final kept = categoryIds.intersection(existingIds.toSet());
    if (kept.isEmpty && !includeUncategorized) return const CategoryFilter.all();
    return CategoryFilter.only(kept, includeUncategorized: includeUncategorized);
  }

  /// Null encodes All (widget snapshot and settings storage).
  Map<String, Object?>? toJson() => isAll
      ? null
      : {
          'categoryIds': (categoryIds.toList()..sort()),
          'includeUncategorized': includeUncategorized,
        };

  static CategoryFilter fromJson(Object? json) {
    if (json is! Map) return const CategoryFilter.all();
    final ids = json['categoryIds'];
    final include = json['includeUncategorized'] == true;
    final set = ids is List ? {for (final id in ids) if (id is String) id} : <String>{};
    if (set.isEmpty && !include) return const CategoryFilter.all();
    return CategoryFilter.only(set, includeUncategorized: include);
  }

  @override
  bool operator ==(Object other) =>
      other is CategoryFilter &&
      other.isAll == isAll &&
      other.includeUncategorized == includeUncategorized &&
      setEquals(other.categoryIds, categoryIds);

  @override
  int get hashCode => Object.hash(isAll, includeUncategorized, Object.hashAllUnordered(categoryIds));
}
