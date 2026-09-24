/// Initials for a Hero who has a name and no portrait.
///
/// One word uses its first letter. Several words use the first and last.
String heroMonogram(String displayName) {
  final parts = displayName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '';
  }
  if (parts.length == 1) {
    return _initial(parts.first);
  }
  return '${_initial(parts.first)}${_initial(parts.last)}';
}

String _initial(String word) {
  final iterator = word.runes.iterator;
  if (!iterator.moveNext()) {
    return '';
  }
  return String.fromCharCode(iterator.current).toUpperCase();
}
