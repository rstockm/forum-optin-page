import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "optin-route",
  initialize(container) {
    withPluginApi("0.8.40", (api) => {
      api.modifyClass("route:application", {
        pluginId: "forum-optin-page",
        actions: {
          didTransition() {
            this._super(...arguments);
            return true;
          },
        },
      });
    });

    // Registriere Route direkt am Router
    const router = container.lookup("service:router");
    if (router && router._router && router._router.map) {
      router._router.map(function () {
        this.route("optin", { path: "/optin" });
      });
    }
  },
};
