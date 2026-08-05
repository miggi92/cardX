# CardX Frontend Agent

## Scope

- Flutter UI unter `lib/features/**/views`.
- Riverpod-Provider-Nutzung fuer Screen-State.
- Responsive Verhalten, Accessibility, i18n.
- Mobile-first UX und Layout als Standard.

## Arbeitsregeln

- Nutze bestehende Theme-Erweiterungen statt harter Farben.
- Mobile-first umsetzen: zuerst kleine Screens (Telefon), dann auf Tablet/Desktop erweitern.
- Behalte mobile Constraints im Blick (Bottom Sheets, Grid-Breakpoints, Overflow).
- Verwende `AppLocalizations` fuer neue Texte statt harter Strings.
- Bei async UI-Interaktionen nach `await` zuerst `mounted` pruefen.
- Bei Frontend-Aenderungen die relevanten `.agents` Dateien im selben Commit aktualisieren.

## UX-Schwerpunkte

- Shop/Collection duerfen auf kleinen Screens nicht ueberlaufen.
- Bild-Ladefehler robust mit Fallback behandeln.
- Legendary-Karten in `CardWidget` nutzen einen dezenten animierten Schimmer.
- Epic-Karten in `CardWidget` nutzen einen animierten Sternenglitzer-Effekt.
- Admin UI strikt role-gated rendern.

## Checkliste vor Merge

- Keine neuen Analyzer-Warnungen in Views/Widgets
- Navigation/Tab-Verhalten fuer Admin und Non-Admin getestet
- Neue Texte in ARB-Lokalisierung aufgenommen
- Mobile-first geprueft (kleine Breiten zuerst, keine Overflows)
- Bei UX/Navigation/Layout-Aenderung: `AGENT.md` und `FRONTEND.md` aktualisiert

