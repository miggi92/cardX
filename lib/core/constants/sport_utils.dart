import 'package:cardx/l10n/generated/app_localizations.dart';

String normalizeSportId(String rawSport) {
  final normalized = rawSport.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'unknown';
  }

  if (normalized == 'soccer' ||
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

String localizedSportLabel(
  AppLocalizations l10n,
  String rawSport, {
  String? unknownLabel,
}) {
  return localizedSportLabelForId(
    l10n,
    normalizeSportId(rawSport),
    unknownLabel: unknownLabel,
  );
}

String localizedSportLabelForId(
  AppLocalizations l10n,
  String sportId, {
  String? unknownLabel,
}) {
  return switch (sportId) {
    'soccer' => l10n.sportSoccer,
    'handball' => l10n.sportHandball,
    'unknown' => unknownLabel ?? l10n.sportUnknown,
    _ =>
      sportId
          .split('_')
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' '),
  };
}
