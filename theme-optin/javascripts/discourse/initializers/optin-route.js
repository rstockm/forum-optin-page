import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "optin-route",
  initialize() {
    withPluginApi("0.8.40", (api) => {
      api.addRoute("optin", { path: "/optin" });
    });
  },
};
