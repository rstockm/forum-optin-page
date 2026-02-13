/**
 * Opt-in View Connector
 *
 * Injects the category opt-in switcher and grid into the discovery.categories route
 * via the above-discovery-categories plugin outlet.
 *
 * DISCOURSE CONVENTIONS:
 * - Uses setupComponent (connector API)
 * - Uses getURL from discourse-common for subfolder-safe URLs
 * - Uses router.transitionTo for SPA navigation (no full reloads)
 * - Uses site.categories for data (no extra API calls)
 *
 * DEVIATIONS:
 * - document.body.classList manipulation: We add/remove "optin-mode" to toggle
 *   visibility of default Discourse UI. Discourse typically avoids body class
 *   injection from theme components; we do it for broad CSS scoping (.optin-mode).
 *   Cleanup in willDestroyElement is required.
 * - Actions via component.set(): Connectors use component.set("actionName", fn)
 *   rather than class methods. This is the standard connector pattern.
 */
import { getOwner } from "@ember/application";
import getURL from "discourse-common/lib/get-url";

export default {
  setupComponent(args, component) {
    const owner = getOwner(component);
    const router = owner.lookup("service:router");

    const updateProperties = () => {
      const queryParams = router?.currentRoute?.queryParams || {};
      const showOptinView =
        queryParams.show_optin === "true" ||
        new URLSearchParams(window.location.search).get("show_optin") === "true";

      const searchTerm = (component.get("searchTerm") || "").toLowerCase();

      const siteService = owner && owner.lookup("service:site");
      const allCategories = (siteService && siteService.get("categories")) || [];

      /**
       * Build canonical category URL. Uses Discourse path format /c/slug/id.
       */
      const getCategoryUrl = (cat) => {
        if (cat.url) return getURL(cat.url);
        let slug = cat.full_slug || cat.slug;
        if (cat.parent_category_id && !cat.full_slug) {
          const parent = allCategories.find((c) => c.id === cat.parent_category_id);
          slug = parent ? parent.slug + "/" + cat.slug : cat.slug;
        }
        return getURL("/c/") + slug + "/" + cat.id;
      };

      const parents = allCategories.filter((c) => !c.parent_category_id);
      const groupedCategories = parents.map((parent) => {
        const children = allCategories
          .filter((c) => c.parent_category_id === parent.id)
          .slice()
          .sort((a, b) => a.name.localeCompare(b.name));

        /**
         * Wrap raw category for template. Keeps .model (Ember object) for
         * setNotification; adds display props. DEVIATION: We create POJOs
         * for template convenience; Discourse typically passes models directly.
         */
        const wrap = (cat, parentColor = null) => {
          return {
            model: cat,
            name: cat.name,
            description:
              cat.description || cat.description_text || cat.description_excerpt,
            url: getCategoryUrl(cat),
            color:
              cat.color ||
              (typeof cat.get === "function" ? cat.get("color") : "999999"),
            parentColor: parentColor,
          };
        };

        const parentWrapped = wrap(parent);
        return {
          parent: parentWrapped,
          children: children.map((c) => wrap(c, parentWrapped.color)),
        };
      });

      let filteredCategories = groupedCategories;
      if (searchTerm) {
        /* Client-side filter: match parent/child name or description. */
        filteredCategories = groupedCategories
          .map((group) => {
            const parentMatch =
              group.parent.name.toLowerCase().includes(searchTerm) ||
              (group.parent.description || "").toLowerCase().includes(searchTerm);

            const matchingChildren = group.children.filter(
              (child) =>
                child.name.toLowerCase().includes(searchTerm) ||
                (child.description || "").toLowerCase().includes(searchTerm)
            );

            if (parentMatch || matchingChildren.length > 0) {
              return { ...group, children: matchingChildren };
            }
            return null;
          })
          .filter(Boolean);
      }

      component.setProperties({
        showOptinView,
        groupedCategories: filteredCategories,
        optinUrl: getURL("/categories?show_optin=true"),
        standardUrl: getURL("/categories"),
      });

      if (showOptinView) {
        /* DEVIATION: Body class for broad CSS scoping. Must be removed in willDestroyElement. */
        document.body.classList.add("optin-mode");
      } else {
        document.body.classList.remove("optin-mode");
      }
    };

    component.set("onSearchTermChange", (event) => {
      component.set("searchTerm", event.target.value);
      updateProperties();
    });

    component.set("clearSearch", () => {
      component.set("searchTerm", "");
      updateProperties();
    });

    updateProperties();

    // Listen for route changes to update view state without full reload
    if (router) {
      router.on("routeDidChange", updateProperties);
    }

    component.set("switchToStandard", (event) => {
      event.preventDefault();
      if (router) {
        router
          .transitionTo("discovery.categories", {
            queryParams: { show_optin: undefined },
          })
          .then(() => updateProperties());
      }
    });

    component.set("switchToOptin", (event) => {
      event.preventDefault();
      if (router) {
        router
          .transitionTo("discovery.categories", {
            queryParams: { show_optin: "true" },
          })
          .then(() => updateProperties());
      }
    });

    component.reopen({
      willDestroyElement() {
        this._super(...arguments);
        if (router) {
          router.off("routeDidChange", updateProperties);
        }
        /* Required cleanup: remove body class added by this connector */
        document.body.classList.remove("optin-mode");
      },
    });
  },
};
