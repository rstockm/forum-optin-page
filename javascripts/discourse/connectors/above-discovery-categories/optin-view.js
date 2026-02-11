import { getOwner } from "@ember/application";
import getURL from "discourse-common/lib/get-url";

export default {
  setupComponent(args, component) {
    const owner = getOwner(component);
    const router = owner.lookup("service:router");

    const updateProperties = () => {
      const params = new URLSearchParams(window.location.search);
      const showOptinView = params.get("show_optin") === "true";

      const siteService = owner && owner.lookup("service:site");
      const categories = (siteService && siteService.get("categories")) || [];

      const parents = categories.filter((c) => !c.parent_category_id);
      const groupedCategories = parents.map((parent) => ({
        parent,
        children: categories.filter((c) => c.parent_category_id === parent.id),
      }));

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
        router.transitionTo("discovery.categories", {
          queryParams: { show_optin: undefined },
        });
      }
    });

    component.set("switchToOptin", (event) => {
      event.preventDefault();
      if (router) {
        router.transitionTo("discovery.categories", {
          queryParams: { show_optin: "true" },
        });
      }
    });

    component.reopen({
      willDestroyElement() {
        this._super(...arguments);
        if (router) {
          router.off("routeDidChange", updateProperties);
        }
      }
    });
  },
};
