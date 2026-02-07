import { getOwner } from "@ember/application";

export default {
  async setupComponent(args, component) {
    const params = new URLSearchParams(window.location.search);
    const showOptinView = params.get("show_optin") === "true";

    const owner = getOwner(component);
    const siteService = owner && owner.lookup("service:site");
    const store = owner && owner.lookup("service:store");

    let categories = [];
    if (showOptinView && store && store.findAll) {
      try {
        const storeCategories = await store.findAll("category");
        categories = storeCategories.toArray
          ? storeCategories.toArray()
          : storeCategories;
      } catch (e) {
        categories = (siteService && siteService.get("categories")) || [];
      }
    } else {
      categories = (siteService && siteService.get("categories")) || [];
    }

    const parents = categories.filter((c) => !c.parent_category_id);
    const groupedCategories = parents.map((parent) => ({
      parent,
      children: categories.filter((c) => c.parent_category_id === parent.id),
    }));

    component.setProperties({ showOptinView, groupedCategories });

    if (showOptinView) {
      document.body.classList.add("optin-mode");
    } else {
      document.body.classList.remove("optin-mode");
    }
  },
};
