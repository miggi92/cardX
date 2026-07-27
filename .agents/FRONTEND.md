# CardX Frontend Agent

## Scope

- Flutter UI unter `lib/features/**/views`.
- Riverpod-Provider-Nutzung fuer Screen-State.
- Responsive Verhalten, Accessibility, i18n.

## Arbeitsregeln

- Nutze bestehende Theme-Erweiterungen statt harter Farben.
- Behalte mobile Constraints im Blick (Bottom Sheets, Grid-Breakpoints, Overflow).
- Verwende `AppLocalizations` fuer neue Texte statt harter Strings.
- Bei async UI-Interaktionen nach `await` zuerst `mounted` pruefen.

## UX-Schwerpunkte

- Shop/Collection duerfen auf kleinen Screens nicht ueberlaufen.
- Bild-Ladefehler robust mit Fallback behandeln.
- Admin UI strikt role-gated rendern.

## Checkliste vor Merge

- Keine neuen Analyzer-Warnungen in Views/Widgets
- Navigation/Tab-Verhalten fuer Admin und Non-Admin getestet
- Neue Texte in ARB-Lokalisierung aufgenommen

