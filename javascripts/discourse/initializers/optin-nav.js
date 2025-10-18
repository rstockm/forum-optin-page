import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "optin-nav",
  initialize() {
    withPluginApi("0.8.40", (api) => {
      api.decorateWidget("header-icons:before", (helper) => {
        return helper.attach("link", {
          href: "/categories?show_optin=true",
          contents: "Forum-Opt-in",
          className: "optin-link",
        });
      });
    });
  },
};
