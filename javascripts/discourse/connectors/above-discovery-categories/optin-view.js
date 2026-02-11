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

      const siteService = owner && owner.lookup("service:site");
      const categories = (siteService && siteService.get("categories")) || [];

      const getCategoryUrl = (cat) => {
        if (cat.url) return getURL(cat.url);
        let slug = cat.full_slug || cat.slug;
        if (cat.parent_category_id && !cat.full_slug) {
          const parent = categories.find((c) => c.id === cat.parent_category_id);
          slug = parent ? parent.slug + "/" + cat.slug : cat.slug;
        }
        return getURL("/c/") + slug + "/" + cat.id;
      };

      const parents = categories.filter((c) => !c.parent_category_id);
      const groupedCategories = parents.map((parent) => {
        const children = categories.filter(
          (c) => c.parent_category_id === parent.id
        );

        const wrap = (cat) => {
          return {
            model: cat,
            name: cat.name,
            description:
              cat.description || cat.description_text || cat.description_excerpt,
            url: getCategoryUrl(cat),
            color:
              cat.color ||
              (typeof cat.get === "function" ? cat.get("color") : "999999"),
          };
        };

        return {
          parent: wrap(parent),
          children: children.map((c) => wrap(c)),
        };
      });

      component.setProperties({
        showOptinView,
        groupedCategories,
        optinUrl: getURL("/categories?show_optin=true"),
        standardUrl: getURL("/categories"),
      });

      if (showOptinView) {
        document.body.classList.add("optin-mode");
      } else {
        document.body.classList.remove("optin-mode");
      }
    };

    updateProperties();

    // Listen for transitions to update the view without full reload
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
        document.body.classList.remove("optin-mode");
      },
    });
  },
};
