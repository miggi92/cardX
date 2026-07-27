# CardX AI Agent Orchestrator

Diese Datei ist der zentrale Einstieg fuer KI-Assistenten in diesem Repo.

## Ziel

- Fuehre Aenderungen entlang der bestehenden Architektur aus.
- Vermeide Breaking Changes ohne klare Begruendung.
- Halte `.agents/*.md` aktuell ueber den Refresh-Workflow.

## Aufgabenverteilung

- Nutze `BACKEND.md` fuer Supabase, Datenmodell, RPC, Policies.
- Nutze `FRONTEND.md` fuer Flutter UI, State, UX und Localization.
- Nutze `ARCHITEKTURE.md` fuer Feature-Zustaendigkeiten und Modulgrenzen.

## Guardrails

- Bevorzuge Riverpod-Provider statt ad-hoc State in Widgets.
- Keine stillen Schema-Annahmen: bei DB-Aenderungen immer RPC/Policy-Folgen pruefen.
- Bei async UI-Flows `mounted` beruecksichtigen, bevor `BuildContext` genutzt wird.
- Keine `select('*')` Abfragen in neuen Repository-Queries.

## Definition of Done

- `flutter analyze` laeuft ohne neue Fehler.
- Relevante Tests sind aktualisiert oder bewusst als Gap dokumentiert.
- Falls Struktur geaendert wurde: `.agents` per Refresh aktualisiert.

## Aktualisierung

- Lokaler Refresh: `dart run tool/update_ai_docs.dart`
- Optional als VS Code Task: `Refresh AI docs`

