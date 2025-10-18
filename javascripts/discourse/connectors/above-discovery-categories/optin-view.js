import { getOwner } from "@ember/application";

export default {
  setupComponent(args, component) {
    const params = new URLSearchParams(window.location.search);
    const showOptinView = params.get("show_optin") === "true";

    const owner = getOwner(component);
    const siteService = owner && owner.lookup("service:site");
    const categories = (siteService && siteService.get("categories")) || [];

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
