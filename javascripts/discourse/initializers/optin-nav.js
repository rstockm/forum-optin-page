import { withPluginApi } from "discourse/lib/plugin-api";
import { h } from "virtual-dom";

export default {
  name: "optin-nav",
  initialize() {
    withPluginApi("0.8.40", (api) => {
      api.addToHeaderIcons((helper) => {
        return {
          title: "Forum-Opt-in",
          icon: "bell",
          href: "/categories?show_optin=true",
          className: "optin-link-icon",
        };
      });
    });
  },
};
