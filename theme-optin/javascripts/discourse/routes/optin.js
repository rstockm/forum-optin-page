import DiscourseRoute from "discourse/routes/discourse";

export default DiscourseRoute.extend({
  model() {
    return this.store.findAll("category");
  },
  setupController(controller, model) {
    controller.set("model", model);
  },
});
