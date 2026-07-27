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

## DB-Domains (wichtig)

- Coins/Rewards: `profiles.coins`, `profiles.last_free_pack`
- Karten/Pool: `user_cards`, `player_pool`, `player_stats`
- Taxonomien: `sports`, `positions`, `leagues`, `seasons`
- Admin: Rollen + Requests via RPC-Workflow

## Checkliste vor Merge

- RPC-Namen und Parametertypen gegen App-Modelle geprueft
- Query-Performance und Index-Nutzung beruecksichtigt
- Fehlerpfade (null/leer/missing assets) getestet
