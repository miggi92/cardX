# CardX AI Agent Orchestrator

Diese Datei ist der zentrale Einstieg fuer KI-Assistenten in diesem Repo.

## Ziel

- Fuehre Aenderungen entlang der bestehenden Architektur aus.
- Vermeide Breaking Changes ohne klare Begruendung.
- Halte `.agents/*.md` bei jeder KI-Aenderung aktiv aktuell (Pflicht).

## Aufgabenverteilung

- Nutze `BACKEND.md` fuer Supabase, Datenmodell, RPC, Policies.
- Nutze `FRONTEND.md` fuer Flutter UI, State, UX und Localization.
- Nutze `ARCHITEKTURE.md` fuer Feature-Zustaendigkeiten und Modulgrenzen.

## Guardrails

- Bevorzuge Riverpod-Provider statt ad-hoc State in Widgets.
- Keine stillen Schema-Annahmen: bei DB-Aenderungen immer RPC/Policy-Folgen pruefen.
- Bei async UI-Flows `mounted` beruecksichtigen, bevor `BuildContext` genutzt wird.
- Keine `select('*')` Abfragen in neuen Repository-Queries.
- `player_pool` ist saisonbezogen; innerhalb derselben Saison Spieler nicht pro Mannschaft duplizieren, sondern ueber `player_team_memberships` zuordnen.
- Externe Sportdaten nur serverseitig synchronisieren; unbekannte Spieler in der Mannschaftssaison anlegen, Platzhalter wie `N.N.` ignorieren.

## Definition of Done

- `flutter analyze` laeuft ohne neue Fehler.
- Relevante Tests sind aktualisiert oder bewusst als Gap dokumentiert.
- Betroffene `.agents` Dateien sind im selben Change-Set angepasst.

## Pflicht fuer KIs: .agents aktuell halten

- Jede KI-Aenderung an Architektur, Datenfluss, Feature-Verhalten oder UX muss passende Updates in `.agents` enthalten.
- Kein Merge mit veralteten Agent-Dateien.
- Mindestens pruefen: `AGENT.md` plus die betroffene Fachdatei (`BACKEND.md`, `FRONTEND.md`, `ARCHITEKTURE.md`).
- Wenn unklar ist, welche Datei betroffen ist, alle vier Dateien kurz gegenpruefen.

## Aktualisierung

- Lokaler Refresh: `dart run tool/update_ai_docs.dart`
- Optional als VS Code Task: `Refresh AI docs`

