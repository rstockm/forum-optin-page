import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "optin-nav",
  initialize() {
    withPluginApi("0.8.40", (api) => {
      api.addNavigationBarItem({
        name: "optin",
        displayName: "Forum-Opt-in",
        title: "Forum-Opt-in",
        route: "optin",
      });
    });
  },
};
