class WishListStore {
  WishListStore._();
  static final WishListStore _i = WishListStore._();
  factory WishListStore() => _i;

  final Set<String> _ids = <String>{};

  bool contains(String id) => _ids.contains(id);

  /// Returns the new state (true = added, false = removed).
  bool toggle(String id) {
    if (_ids.remove(id)) return false;
    _ids.add(id);
    return true;
  }

  Set<String> get ids => _ids;
}
