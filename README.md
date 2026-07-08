# forum-optin-page

Discourse Theme Component für eine alternative Kategorie-Übersicht mit Opt-in-Steuerung für Kategorie-Benachrichtigungen.

Das Component erweitert die Discourse-Kategorieseite um eine umschaltbare Opt-in-Ansicht. In dieser Ansicht werden Hauptkategorien als Karten und Unterkategorien als Chips dargestellt. Angemeldete Nutzer können dort ihre Benachrichtigungsstufe für einzelne Kategorien oder für eine ganze Hauptkategorie inklusive Unterkategorien setzen.

## Wichtiger Hinweis zur Sichtbarkeit

Der Opt-in Button bzw. Umschalter ist nur auf der Discourse-Kategorieseite sichtbar.

Damit Nutzer den Button direkt auf der Startseite sehen, muss in den Nutzereinstellungen als Startseite `Kategorie` aktiviert sein. Die relevante Zielseite ist die Kategorien-URL, zum Beispiel:

https://d3o.wolkenbar.de/categories

Wenn ein Nutzer eine andere Startseite verwendet, zum Beispiel `Latest` oder eine Topic-Liste, erscheint der Opt-in Button dort nicht. In diesem Fall muss der Nutzer manuell zur Kategorienseite wechseln.

## Nutzer-Dokumentation

### Zweck

Das Component soll Nutzern eine einfachere Übersicht über abonnierbare Kategorien geben. Statt die Standard-Kategorieliste einzeln zu durchsuchen, können sie Kategorien und Unterkategorien in einer kompakten Opt-in-Ansicht sehen und Benachrichtigungen direkt setzen.

### Ansicht wechseln

Auf der Kategorienseite erscheint oberhalb der normalen Kategorieliste ein Umschalter:

- `Standard`: zeigt die normale Discourse-Kategorieansicht.
- `Opt-in`: zeigt die alternative Opt-in-Ansicht.

Technisch wird die Opt-in-Ansicht über den Query-Parameter `show_optin=true` aktiviert:

```text
/categories?show_optin=true
```

Die Standardansicht wird über die normale Kategorien-URL aufgerufen:

```text
/categories
```

### Kategorien filtern

In der Opt-in-Ansicht steht ein Suchfeld zur Verfügung. Die Suche filtert clientseitig nach:

- Name der Hauptkategorie
- Beschreibung der Hauptkategorie
- Name der Unterkategorie
- Beschreibung der Unterkategorie

Es werden keine zusätzlichen API-Requests ausgelöst.

### Benachrichtigungen setzen

Angemeldete Nutzer sehen an Kategorien und Unterkategorien einen Benachrichtigungsbutton. Über das Dropdown kann eine der Discourse-Benachrichtigungsstufen ausgewählt werden:

- `Beobachten`
- `Verfolgen`
- `Ersten Beitrag beobachten`
- `Normal`
- `Stummgeschaltet`

Bei Hauptkategorien gibt es zusätzlich den Button `Ganze Kategorie`. Diese Aktion setzt die gewählte Benachrichtigungsstufe auf die Hauptkategorie und alle direkt darunterliegenden Unterkategorien.

Nicht angemeldete Nutzer sehen die Benachrichtigungsbuttons nicht.

## Installation

Das Repository ist als Discourse Theme Component aufgebaut.

In Discourse:

1. Adminbereich öffnen.
2. `Anpassen` / `Themes` öffnen.
3. Neues Theme Component aus GitHub importieren.
4. Repository-URL verwenden:

```text
https://github.com/rstockm/forum-optin-page
```

5. Component einem aktiven Theme hinzufügen.
6. Theme aktualisieren.
7. Kategorienseite öffnen:

```text
/categories
```

8. Optional direkt die Opt-in-Ansicht testen:

```text
/categories?show_optin=true
```

## Technische Übersicht

### Dateistruktur

```text
about.json
CODE_REVIEW.md
README.md
common/
  common.scss
javascripts/discourse/
  components/
    optin-notification-button.gjs
  connectors/
    above-discovery-categories/
      optin-view.gjs
```

### Discourse-Integration

Das Component nutzt den Plugin Outlet:

```text
above-discovery-categories
```

Dieser Outlet liegt auf der Discourse-Kategorieseite oberhalb der Kategorieansicht. Deshalb ist die Funktion an die Kategorienseite gebunden.

Die zentrale Connector-Datei ist:

```text
javascripts/discourse/connectors/above-discovery-categories/optin-view.gjs
```

Der Connector ist als moderne `.gjs` Glimmer-Komponente umgesetzt. Die frühere klassische Struktur aus `.hbs` und `.js` wurde entfernt.

### Datenquelle

Die Kategorien werden aus dem Discourse-Service `site` gelesen:

```js
@service site;
```

Die Kategorie-Liste wird aus `site.categories` abgeleitet. Es gibt keine eigenen Backend-Endpunkte und keine zusätzlichen Netzwerk-Requests.

### Routing

Die Ansicht verwendet Discourse SPA-Navigation über den Router-Service:

```js
@service router;
```

Die Umschaltung zwischen Standard- und Opt-in-Ansicht erfolgt über:

```text
/categories
/categories?show_optin=true
```

Der Query-Parameter `show_optin=true` aktiviert die Opt-in-Ansicht.

### UI-Logik

Die Opt-in-Ansicht gruppiert Kategorien nach:

- Hauptkategorien: Kategorien ohne `parent_category_id`
- Unterkategorien: Kategorien mit `parent_category_id`

Unterkategorien werden alphabetisch nach Name sortiert.

Für die Template-Ausgabe werden Kategorie-Modelle in einfache View-Objekte gewrappt. Das Originalmodell bleibt unter `model` erhalten, damit Discourse APIs wie `setNotification()` weiter genutzt werden können.

### Benachrichtigungs-API

Die Komponente `optin-notification-button.gjs` nutzt die vorhandene Discourse-Kategorie-API:

```js
category.setNotification(levelId);
```

Es werden keine eigenen Schreib-Endpunkte implementiert.

Die unterstützten Level sind:

```js
[
  { id: 3, label: "Beobachten" },
  { id: 2, label: "Verfolgen" },
  { id: 4, label: "Ersten Beitrag beobachten" },
  { id: 1, label: "Normal" },
  { id: 0, label: "Stummgeschaltet" },
]
```

### Cascading für Hauptkategorien

Der Button `Ganze Kategorie` setzt die Benachrichtigungsstufe auf:

- die Hauptkategorie
- alle direkt darunterliegenden Unterkategorien

Das ist bewusstes Custom-Verhalten und keine Standardfunktion von Discourse.

## Security-Hinweise

### Kategorie-Beschreibungen

Kategorie-Beschreibungen werden nicht als raw HTML gerendert.

Die Ausgabe bevorzugt:

```text
description_text
description_excerpt
```

Raw `description` wird nicht mit `htmlSafe()` ausgegeben. Dadurch wird vermieden, dass HTML aus Kategorie-Beschreibungen ungeprüft in die Opt-in-Ansicht gelangt.

### Inline-Styles

Kategorie-Farben werden vor der Nutzung validiert. Zulässig sind nur sechsstellige Hex-Farben:

```js
/^[0-9a-fA-F]{6}$/
```

Ungültige Werte fallen auf `999999` zurück.

Für Style-Bindings wird `htmlSafe()` nur auf lokal zusammengesetzte Strings aus validierten Farben angewendet:

```js
htmlSafe(`border-left-color: #${color}`)
htmlSafe(`border-color: #${inheritedColor}`)
```

`htmlSafe()` wird nicht für Nutzertexte, Kategorie-Beschreibungen oder SVG-Strings verwendet.

### Externe Ressourcen

Das Component lädt keine externen Skripte, Fonts oder Assets nach.

### Secrets und Tokens

Das Component enthält keine API-Keys, Secrets, Tokens oder Zugangsdaten.

### CSP

Es werden keine eigenen CSP-Erweiterungen in `about.json` definiert. Das Component verlässt sich auf die reguläre Discourse-CSP.

## Bewusste technische Abweichungen

Diese Punkte sind für Code-Reviewer besonders relevant:

- `document.body.classList.toggle("optin-mode")` wird verwendet, um die Standard-Kategorieliste in der Opt-in-Ansicht per CSS auszublenden.
- `common/common.scss` nutzt gezielt `!important`, um Discourse-Core-Styles zu übersteuern.
- `common/common.scss` ist größer als 400 Zeilen. Eine spätere Aufteilung in SCSS-Module ist sinnvoll, sobald die Zielumgebung zuverlässig bestätigt, wie lokale SCSS-Partials in diesem Theme Component geladen werden.
- `optin-notification-button.gjs` nutzt eine modulweite Variable `activeDropdown`, damit immer nur ein Dropdown geöffnet bleibt.
- `Ganze Kategorie` kaskadiert Benachrichtigungsänderungen auf direkte Unterkategorien.
- Die Suche läuft rein clientseitig auf `site.categories`.

## Review-Leitfaden für externe Firmen

Ziel eines externen Reviews sollte sein, die Produktionsreife als Discourse Theme Component zu bewerten.

### Funktionale Prüfpunkte

- Wird der Umschalter auf `/categories` angezeigt?
- Wird er nur auf der Kategorienseite erwartet und nicht auf anderen Startseiten?
- Funktioniert `/categories?show_optin=true`?
- Blendet die Opt-in-Ansicht die Standard-Kategorieliste korrekt aus?
- Funktioniert die Suche nach Kategorie- und Beschreibungstexten?
- Werden Hauptkategorien und Unterkategorien korrekt gruppiert?
- Setzt der Button einer Unterkategorie nur diese Unterkategorie?
- Setzt `Ganze Kategorie` die Hauptkategorie und alle direkten Unterkategorien?
- Sind Benachrichtigungsbuttons nur für angemeldete Nutzer sichtbar?

### Technische Prüfpunkte

- Ist der `.gjs` Connector mit aktuellen Discourse-Konventionen kompatibel?
- Ist der Importpfad zu `OptinNotificationButton` korrekt?
- Ist die Nutzung von `@service router` und `@service site` für die Zielversion von Discourse kompatibel?
- Wird der `routeDidChange` Listener zuverlässig entfernt?
- Wird die Body-Klasse `optin-mode` zuverlässig entfernt, wenn die Komponente zerstört wird?
- Gibt es unerwünschte Nebeneffekte durch `.optin-mode` und `!important`?
- Sind die CSS-Selektoren ausreichend eng scoped?
- Funktioniert `:has()` in den von Discourse unterstützten Browsern der Zielumgebung?

### Security-Prüfpunkte

- Keine raw HTML-Ausgabe von Kategorie-Beschreibungen.
- Keine Verwendung von `htmlSafe()` für Nutzer- oder Admin-Texte.
- Inline-Styles nur mit validierten Hex-Farben.
- Keine externen Skripte.
- Keine Secrets oder Tokens im Repository.
- Keine eigenen API-Calls, die CSRF- oder Berechtigungsfragen eröffnen.

### Kompatibilitäts-Prüfpunkte

- Test mit aktueller Discourse-Version.
- Test mit aktivierter und deaktivierter Anmeldung.
- Test mit Kategorien ohne Beschreibung.
- Test mit Kategorien ohne Unterkategorien.
- Test mit vielen Kategorien und Unterkategorien.
- Test mit Discourse in Subfolder-Installationen, weil URLs über `getURL()` erzeugt werden.
- Test mit unterschiedlichen Theme-Farben, Hell-/Dunkelmodus und responsiven Viewports.

## Manuelle Testanleitung

1. Theme Component in Discourse aktualisieren.
2. Als Administrator anmelden.
3. Sicherstellen, dass die Startseite des Testnutzers auf `Kategorie` steht.
4. `/categories` öffnen.
5. Prüfen, ob der Umschalter `Standard` / `Opt-in` sichtbar ist.
6. `Opt-in` anklicken.
7. Prüfen, ob die URL `show_optin=true` enthält.
8. Suchfeld testen.
9. Benachrichtigungsstufe einer Unterkategorie ändern.
10. Benachrichtigungsstufe über `Ganze Kategorie` ändern.
11. Seite neu laden und prüfen, ob der Zustand konsistent bleibt.
12. Als nicht angemeldeter Nutzer prüfen, ob keine Benachrichtigungsbuttons sichtbar sind.
13. Browser-Konsole auf JavaScript-Fehler prüfen.

## Bekannte Grenzen

- Die Opt-in-Ansicht ist an die Kategorienseite gebunden.
- Der Button erscheint nicht automatisch auf anderen Discourse-Startseiten.
- Die Kaskadierung betrifft direkte Unterkategorien, nicht beliebig tiefe Kategoriehierarchien.
- Es gibt keine serverseitige Suche.
- Es gibt keine eigene Persistenzschicht; Persistenz läuft über Discourse `category.setNotification()`.

## Lizenz

Siehe `about.json`. Dort ist aktuell die Discourse-Lizenz-URL hinterlegt.
