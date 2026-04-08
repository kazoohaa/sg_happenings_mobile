import 'event_list_item.dart';

/// Client-side filter: [query] matches title, description, location, category, poster name.
bool eventMatchesSearchQuery(EventListItem e, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  bool contains(String? s) => (s ?? '').toLowerCase().contains(q);
  return contains(e.title) ||
      contains(e.description) ||
      contains(e.location) ||
      contains(e.postalCode) ||
      contains(e.categoryName) ||
      contains(e.categoryId) ||
      contains(e.eventPosterName);
}

/// When [categoryKey] is null or empty, all events pass. Otherwise matches [EventListItem.categoryId] or [categoryName] (case-insensitive).
bool eventMatchesCategoryKey(EventListItem e, String? categoryKey) {
  final key = categoryKey?.trim().toLowerCase();
  if (key == null || key.isEmpty) return true;
  if (e.categoryId.trim().toLowerCase() == key) return true;
  if (e.categoryName.trim().toLowerCase() == key) return true;
  return false;
}
