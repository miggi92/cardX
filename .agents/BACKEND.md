# CardX Backend Agent

## Scope

- Supabase Integrationen in Repositories unter `lib/core/repositories/`.
- Auth-Datenzugriff unter `lib/features/auth/data/`.
- RPC-Verwendung, Query-Felder, Fehlerbehandlung und Performance.

## Arbeitsregeln

- Bevorzuge serverseitige Logik per RPC fuer komplexe Selektion/Randomisierung.
- Fordere nur benoetigte Spalten an, kein `select('*')` in neuen Queries.
- Beruecksichtige bestehende Optimistic-UI-Flows mit Rollback in Providern.
- Storage-Zugriffe extension-agnostisch und mit Caching nutzen.
- Bei Backend-Aenderungen die relevanten `.agents` Dateien im selben Commit aktualisieren.

## DB-Domains (wichtig)

- Coins/Rewards: `profiles.coins`, `profiles.last_free_pack`
- Karten/Pool: `user_cards`, `player_pool`, `player_stats`
- Mannschaften: `club_season_teams`, `player_team_memberships`
- Externe Sportdaten: `player_external_identities`, `player_team_stats`
- Referenzdaten: `external_data_providers`; Mannschaftsgeschlecht nutzt den Enum `team_gender`
- Taxonomien: `sports`, `positions`, `leagues`, `seasons`
- Admin: Rollen + Requests via RPC-Workflow

## Checkliste vor Merge

- RPC-Namen und Parametertypen gegen App-Modelle geprueft
- Query-Performance und Index-Nutzung beruecksichtigt
- Fehlerpfade (null/leer/missing assets) getestet
- Bei RPC/Schema/Repository-Aenderung: `AGENT.md` und `BACKEND.md` aktualisiert

## Mannschaften und externe Statistiken

- `player_pool` enthaelt saisonale Spielerzeilen; innerhalb derselben Saison wird ein Spieler nicht pro Mannschaft dupliziert.
- `player_team_memberships` bildet Mehrfachzuordnungen zu saisonalen Mannschaften ab.
- Externe IDs werden mit Provider in `player_external_identities` gespeichert.
- Provider werden zentral in `external_data_providers` gepflegt und per Foreign Key von Mannschaften und Spieleridentitaeten referenziert.
- Externe Spieleridentitaeten und Sync-Zuordnungen sind saisonbezogen; ein Sync darf keine Spielerzeile einer anderen Saison verwenden.
- Unbekannte API-Spieler werden beim Sync in der Mannschaftssaison angelegt. Fehlt eine verwertbare Position, wird die normalisierte Position `unknown` verwendet.
- Geschlechterwerte sind mit `team_gender` auf `male`, `female` und `mixed` begrenzt; sportabhaengige Altersklassen und Statistikschluessel bleiben erweiterbar.
- Sportartspezifische Werte liegen als JSON-Objekt in `player_team_stats.stats`; gemeinsame Kartenwerte bleiben in `player_stats` kompatibel.
- Handball-Lineups werden ueber die JWT-geschuetzte Edge Function `sync-team-lineup` geladen und durch `sync_team_lineup` geschrieben.
- Platzhalter wie `N.N.` werden beim Sync ignoriert. Unbekannte Namen werden automatisch fuer die Mannschaftssaison angelegt; fehlende Berechtigungen werden als nicht zugeordnet gemeldet.
