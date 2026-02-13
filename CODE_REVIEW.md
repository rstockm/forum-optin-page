# Code Review: Discourse Conventions

## Summary

This theme component adds an Opt-in view to the categories page. It follows Discourse conventions where possible and documents deviations.

## Conventions Followed

- **Plugin outlet**: Uses `above-discovery-categories` connector
- **SPA navigation**: `router.transitionTo()` instead of full page reloads
- **URL handling**: `getURL()` from `discourse-common` for subfolder support
- **Data source**: `site.categories` (no extra API calls)
- **Glimmer components**: `.gjs` with `@tracked`, `@action`, `@service`
- **CSS variables**: `var(--primary)`, `var(--tertiary)`, `--d-border-radius`, etc.
- **Category API**: `category.setNotification()` for persistence

## Documented Deviations

| Location | Deviation | Rationale |
|----------|-----------|-----------|
| `optin-view.js` | `document.body.classList.add("optin-mode")` | Broad CSS scoping to hide default category list. Cleanup in `willDestroyElement`. |
| `optin-view.js` | POJO wrappers for categories (`wrap()`) | Template needs `url`, `description`, `parentColor`; keeps `.model` for `setNotification`. |
| `optin-view.hbs` | Inline SVG instead of `d-icon` | `d-icon` does not render in connector template context. |
| `optin-notification-button.gjs` | Module-level `activeDropdown` | Single-dropdown rule; keeps component self-contained. |
| `optin-notification-button.gjs` | `@children` cascade | Parent change cascades to subcategories; custom UX. |
| `common/common.scss` | `.optin-mode` with `!important` | Override Discourse core visibility. Use sparingly. |
| `common/common.scss` | Input `border: none !important` | Discourse default styles cause double border on search field. |
| `common/common.scss` | `:has()` selector | Chip z-index when dropdown open. No fallback. |

## File Structure

```
javascripts/discourse/
  connectors/above-discovery-categories/
    optin-view.hbs   # Template
    optin-view.js    # Connector setupComponent
  components/
    optin-notification-button.gjs
common/
  common.scss
about.json
```
