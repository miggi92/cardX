# CardX

CardX ist eine Flutter-App zum Sammeln und Oeffnen von Sport-Karten mit Coins,
Shop-Packs und taeglichem Gratis-Pack.

## Voraussetzungen

- Flutter SDK (stable)
- Zugriff auf ein Supabase-Projekt mit den benoetigten Tabellen/Buckets

## Starten

1. Abhaengigkeiten laden:

```bash
flutter pub get
```

2. App starten:

```bash
flutter run
```

Optional mit Umgebungswerten statt Defaults:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://your-project.supabase.co \
	--dart-define=SUPABASE_PUBLISHABLE_KEY=your_key
```

## Tests und Analyse

```bash
flutter analyze
flutter test
```

## Architektur (Kurzueberblick)

- State-Management: Riverpod
- Persistenz: Supabase
- Features: Dashboard, Sammlung, Shop
- Daily Reward: serverseitig ueber `profiles.last_free_pack`

## Hinweise zur Datenbank

Erwartete zentrale Spalten/Tabellen:

- `profiles.coins`
- `profiles.last_free_pack`
- `user_cards`
- `player_pool`
- `clubs`

Erwartete Storage-Buckets:

- `club-logos`
- `player-images`
