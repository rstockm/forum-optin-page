# Code Review: Discourse Conventions

## Summary

This theme component adds an Opt-in view to the categories page. It follows current Discourse theme component conventions where possible and documents remaining deviations.

## Conventions Followed

- **Plugin outlet**: Uses a `.gjs` connector in `above-discovery-categories`
- **SPA navigation**: `router.transitionTo()` instead of full page reloads
- **URL handling**: `getURL()` from `discourse-common` for subfolder support
- **Data source**: `site.categories` (no extra API calls)
- **Glimmer components**: `.gjs` with `@tracked`, `@action`, `@service`
- **CSS variables**: `var(--primary)`, `var(--tertiary)`, `--d-border-radius`, etc.
- **Category API**: `category.setNotification()` for persistence
- **Safe descriptions**: Uses `description_text` / `description_excerpt`, not raw `description` with `html-safe`
- **Color validation**: Category colors are restricted to six-digit hex values before inline style use

## Documented Deviations

| Location | Deviation | Rationale |
|----------|-----------|-----------|
| `optin-view.gjs` | `document.body.classList.toggle("optin-mode")` | Broad CSS scoping to hide default category list. Cleanup in `willDestroy`. |
| `optin-view.gjs` | POJO wrappers for categories (`wrapCategory()`) | Template needs `url`, safe `description`, `parentColor`; keeps `.model` for `setNotification`. |
| `optin-view.gjs` | Inline SVG search/clear icons | Avoids `html-safe` string rendering while keeping connector-local icons simple. |
| `optin-notification-button.gjs` | Module-level `activeDropdown` | Single-dropdown rule; keeps component self-contained. |
| `optin-notification-button.gjs` | `@children` cascade | Parent change cascades to subcategories; custom UX. |
| `common/common.scss` | `.optin-mode` with `!important` | Override Discourse core visibility. Use sparingly. |
| `common/common.scss` | Input `border: none !important` | Discourse default styles cause double border on search field. |
| `common/common.scss` | `:has()` selector | Chip z-index when dropdown open. No fallback. |
| `common/common.scss` | File exceeds 400 lines | Keep as one file until the target theme build pipeline confirms reliable SCSS partial loading. |

## File Structure

```
javascripts/discourse/
  connectors/above-discovery-categories/
    optin-view.gjs   # Class-based connector component
  components/
    optin-notification-button.gjs
common/
  common.scss
about.json
```
