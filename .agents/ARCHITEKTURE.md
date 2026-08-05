# CardX Architektur Agent

## Architekturprinzipien

- UI in `lib/features/*/views`
- Domain/Modelle in `lib/features/*/models` und `lib/features/*/domain`
- Datenzugriff in `lib/core/repositories`
- App-State in `lib/core/providers`

## Integrationsgrenzen

- Screens sprechen mit Providern, nicht direkt mit Supabase.
- Repositories kapseln Remote/Local Details.
- Wiederverwendbare Infrastruktur lebt unter `lib/core`.
- Eine Spielerkarte referenziert eine saisonale Spielerzeile; Mannschaften und Statistiken muessen derselben Saison angehoeren.
- Externe Sport-APIs werden nur serverseitig ueber Supabase Edge Functions aufgerufen.

## Qualitaetsziele

- Kleine, klar getrennte Feature-Module.
- Vorhersehbare Datenfluesse ueber Provider.
- Tests mindestens fuer kritische Flows (Auth, Shop, Collection, Admin).

## Aenderungsstrategie

- Erst bestehendes Muster suchen, dann erweitern.
- Neue Features entlang `model -> repository -> provider -> view` aufbauen.
- Strukturupdates in den Agent-Dateien dokumentieren.
- Bei Architektur- oder Modulgrenzen-Aenderungen `.agents` im selben Change-Set aktualisieren.

## Team-Datenfluss

`Verein -> saisonale Mannschaft -> Spielerzuordnung -> sportartspezifische Statistik`

Die Admin-UI pflegt Mannschaftsmetadaten und externe Team-IDs. Der Sync ordnet zuerst ueber die externe Spieler-ID plus Saison, danach nur ueber einen vorhandenen exakten Namen im selben Verein, Sport und derselben Saison zu. Unbekannte Spieler werden fuer die Mannschaftssaison angelegt; dieselbe saisonale Spielerzeile kann mehreren Mannschaften dieser Saison angehoeren.

