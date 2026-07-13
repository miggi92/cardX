String normalizeSportId(String rawSport) {
  final normalized = rawSport.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'unknown';
  }

  if (normalized == 'soccer' ||
      normalized == 'football' ||
      normalized == 'fussball' ||
      normalized == 'fu\u00dfball') {
    return 'soccer';
  }

  if (normalized == 'handball') {
    return 'handball';
  }

  return normalized
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
