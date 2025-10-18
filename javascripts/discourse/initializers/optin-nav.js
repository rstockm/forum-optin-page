import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "optin-nav",
  initialize() {
    withPluginApi("1.2.0", (api) => {
      api.headerIcons.add("optin", {
        title: "Forum-Opt-in",
        icon: "bell",
        href: "/categories?show_optin=true",
      });
    });
  },
};
