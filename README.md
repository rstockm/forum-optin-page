# forum-optin-page

Discourse Theme Component for an alternative category overview with opt-in controls for category notification levels.

This component extends the Discourse categories page with a switchable opt-in view. In this view, parent categories are displayed as cards and subcategories as chips. Signed-in users can set their notification level for individual categories or for an entire parent category including its direct subcategories.

## Important Visibility Note

The opt-in button or view switcher is only visible on the Discourse categories page.

For users to see the button directly on their homepage, their user setting for the homepage must be set to `Categories`. The relevant target page is the categories URL, for example:

https://d3o.wolkenbar.de/categories

If a user has configured a different homepage, such as `Latest` or a topic list, the opt-in button will not appear there. In that case, the user must navigate to the categories page manually.

## User Documentation

### Purpose

The component gives users a simpler overview of subscribable categories. Instead of searching through the standard category list, users can view categories and subcategories in a compact opt-in view and set notification levels directly.

### Switching Views

On the categories page, a switcher appears above the standard category list:

- `Standard`: shows the normal Discourse category view.
- `Opt-in`: shows the alternative opt-in view.

Technically, the opt-in view is activated through the `show_optin=true` query parameter:

```text
/categories?show_optin=true
```

The standard view is loaded through the normal categories URL:

```text
/categories
```

### Filtering Categories

The opt-in view includes a search field. The search runs client-side and filters by:

- Parent category name
- Parent category description
- Subcategory name
- Subcategory description

No additional API requests are triggered.

### Setting Notifications

Signed-in users see a notification button for categories and subcategories. The dropdown allows them to select one of the Discourse notification levels:

- `Watching`
- `Tracking`
- `Watching first post`
- `Normal`
- `Muted`

For parent categories, there is an additional `Ganze Kategorie` button. This action applies the selected notification level to the parent category and all direct subcategories below it.

Users who are not signed in do not see notification buttons.

## Installation

This repository is structured as a Discourse Theme Component.

In Discourse:

1. Open the admin area.
2. Open `Customize` / `Themes`.
3. Import a new Theme Component from GitHub.
4. Use this repository URL:

```text
https://github.com/rstockm/forum-optin-page
```

5. Add the component to an active theme.
6. Update the theme.
7. Open the categories page:

```text
/categories
```

8. Optionally test the opt-in view directly:

```text
/categories?show_optin=true
```

## Technical Overview

### File Structure

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

### Discourse Integration

The component uses this plugin outlet:

```text
above-discovery-categories
```

This outlet is located on the Discourse categories page above the category view. This is why the feature is tied to the categories page.

The main connector file is:

```text
javascripts/discourse/connectors/above-discovery-categories/optin-view.gjs
```

The connector is implemented as a modern `.gjs` Glimmer component. The previous classic `.hbs` plus `.js` structure has been removed.

### Data Source

Categories are read from the Discourse `site` service:

```js
@service site;
```

The category list is derived from `site.categories`. There are no custom backend endpoints and no additional network requests.

### Routing

The view uses Discourse SPA navigation through the router service:

```js
@service router;
```

Switching between the standard and opt-in views uses:

```text
/categories
/categories?show_optin=true
```

The `show_optin=true` query parameter activates the opt-in view.

### UI Logic

The opt-in view groups categories by:

- Parent categories: categories without `parent_category_id`
- Subcategories: categories with `parent_category_id`

Subcategories are sorted alphabetically by name.

For template output, category models are wrapped in simple view objects. The original model remains available under `model`, so Discourse APIs such as `setNotification()` can still be used.

### Notification API

The `optin-notification-button.gjs` component uses the existing Discourse category API:

```js
category.setNotification(levelId);
```

No custom write endpoints are implemented.

The supported levels are:

```js
[
  { id: 3, label: "Watching" },
  { id: 2, label: "Tracking" },
  { id: 4, label: "Watching first post" },
  { id: 1, label: "Normal" },
  { id: 0, label: "Muted" },
]
```

### Cascading for Parent Categories

The `Ganze Kategorie` button applies the notification level to:

- the parent category
- all direct subcategories below it

This is intentional custom behavior and not a standard Discourse feature.

## Security Notes

### Category Descriptions

Category descriptions are not rendered as raw HTML.

Output prefers:

```text
description_text
description_excerpt
```

Raw `description` is not rendered with `htmlSafe()`. This avoids injecting unchecked HTML from category descriptions into the opt-in view.

### Inline-Styles

Category colors are validated before use. Only six-digit hex colors are allowed:

```js
/^[0-9a-fA-F]{6}$/
```

Invalid values fall back to `999999`.

For style bindings, `htmlSafe()` is only applied to locally constructed strings based on validated colors:

```js
htmlSafe(`border-left-color: #${color}`)
htmlSafe(`border-color: #${inheritedColor}`)
```

`htmlSafe()` is not used for user text, category descriptions, or SVG strings.

### External Resources

The component does not load external scripts, fonts, or assets.

### Secrets und Tokens

The component does not contain API keys, secrets, tokens, or credentials.

### CSP

No custom CSP extensions are defined in `about.json`. The component relies on the regular Discourse CSP.

## Intentional Technical Deviations

These points are especially relevant for code reviewers:

- `document.body.classList.toggle("optin-mode")` is used to hide the standard category list with CSS in the opt-in view.
- `common/common.scss` intentionally uses `!important` to override Discourse core styles.
- `common/common.scss` is larger than 400 lines. A later split into SCSS modules is useful once the target environment reliably confirms how local SCSS partials are loaded in this Theme Component.
- `optin-notification-button.gjs` uses a module-level `activeDropdown` variable so only one dropdown remains open at a time.
- `Ganze Kategorie` cascades notification changes to direct subcategories.
- Search runs fully client-side on `site.categories`.

## Review Guide for External Companies

The goal of an external review should be to assess production readiness as a Discourse Theme Component.

### Functional Review Points

- Is the switcher displayed on `/categories`?
- Is it expected only on the categories page and not on other homepages?
- Does `/categories?show_optin=true` work?
- Does the opt-in view correctly hide the standard category list?
- Does search work for category names and description text?
- Are parent categories and subcategories grouped correctly?
- Does a subcategory button affect only that subcategory?
- Does `Ganze Kategorie` affect the parent category and all direct subcategories?
- Are notification buttons visible only to signed-in users?

### Technical Review Points

- Is the `.gjs` connector compatible with current Discourse conventions?
- Is the import path to `OptinNotificationButton` correct?
- Is the use of `@service router` and `@service site` compatible with the target Discourse version?
- Is the `routeDidChange` listener reliably removed?
- Is the `optin-mode` body class reliably removed when the component is destroyed?
- Are there unwanted side effects from `.optin-mode` and `!important`?
- Are the CSS selectors scoped narrowly enough?
- Does `:has()` work in the browsers supported by the target Discourse environment?

### Security Review Points

- No raw HTML output for category descriptions.
- No use of `htmlSafe()` for user or admin text.
- Inline styles only with validated hex colors.
- No external scripts.
- No secrets or tokens in the repository.
- No custom API calls that would introduce CSRF or authorization concerns.

### Compatibility Review Points

- Test with the current Discourse version.
- Test with signed-in and signed-out users.
- Test with categories without descriptions.
- Test with categories without subcategories.
- Test with many categories and subcategories.
- Test with Discourse in subfolder installations, because URLs are generated through `getURL()`.
- Test with different theme colors, light/dark mode, and responsive viewports.

## Manual Test Instructions

1. Update the Theme Component in Discourse.
2. Sign in as an administrator.
3. Ensure that the test user's homepage is set to `Categories`.
4. Open `/categories`.
5. Check whether the `Standard` / `Opt-in` switcher is visible.
6. Click `Opt-in`.
7. Check whether the URL contains `show_optin=true`.
8. Test the search field.
9. Change the notification level of a subcategory.
10. Change the notification level through `Ganze Kategorie`.
11. Reload the page and verify that the state remains consistent.
12. Check as a signed-out user that no notification buttons are visible.
13. Check the browser console for JavaScript errors.

## Known Limitations

- The opt-in view is tied to the categories page.
- The button does not automatically appear on other Discourse homepages.
- Cascading affects direct subcategories, not arbitrarily deep category hierarchies.
- There is no server-side search.
- There is no custom persistence layer; persistence runs through Discourse `category.setNotification()`.

## License

See `about.json`. It currently references the Discourse license URL.
