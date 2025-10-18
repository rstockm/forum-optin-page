import Controller from "@ember/controller";
import { computed } from "@ember/object";

export default Controller.extend({
  groupedCategories: computed("model.@each.parent_category_id", function () {
    const categories = this.model || [];
    const parents = categories.filter((c) => !c.parent_category_id);
    return parents.map((parent) => ({
      parent,
      children: categories.filter((c) => c.parent_category_id === parent.id),
    }));
  }),
});
