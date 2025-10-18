import { computed } from "@ember/object";

export default {
  setupComponent(args, component) {
    const categories = this.site.get("categories") || [];
    
    component.setProperties({
      showOptinView: window.location.search.includes("show_optin=true"),
      groupedCategories: computed(function () {
        const parents = categories.filter((c) => !c.parent_category_id);
        return parents.map((parent) => ({
          parent,
          children: categories.filter((c) => c.parent_category_id === parent.id),
        }));
      }),
    });
  },
};
