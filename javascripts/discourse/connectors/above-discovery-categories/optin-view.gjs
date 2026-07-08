import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { htmlSafe } from "@ember/template";
import { i18n } from "discourse-i18n";
import getURL from "discourse-common/lib/get-url";
import OptinNotificationButton from "../../components/optin-notification-button";

const HEX_COLOR = /^[0-9a-fA-F]{6}$/;

function readCategoryValue(category, key) {
  return typeof category?.get === "function" ? category.get(key) : category?.[key];
}

function safeCategoryColor(color) {
  const value = typeof color === "string" ? color.replace(/^#/, "") : "";
  return HEX_COLOR.test(value) ? value : "999999";
}

function configuredText(settingName, translationKey) {
  const settingValue =
    typeof themeSetting !== "undefined" ? themeSetting[settingName] : null;
  const trimmedValue =
    typeof settingValue === "string" ? settingValue.trim() : settingValue;

  return trimmedValue || i18n(themePrefix(translationKey));
}

export default class OptinView extends Component {
  @service router;
  @service site;

  @tracked searchTerm = "";
  @tracked routeVersion = 0;

  constructor() {
    super(...arguments);
    this.router?.on("routeDidChange", this.handleRouteDidChange);
    this.updateBodyClass();
  }

  get showOptinView() {
    this.routeVersion;

    const queryParams = this.router?.currentRoute?.queryParams || {};
    return (
      queryParams.show_optin === "true" ||
      (typeof window !== "undefined" &&
        new URLSearchParams(window.location.search).get("show_optin") === "true")
    );
  }

  get optinUrl() {
    return getURL("/categories?show_optin=true");
  }

  get standardUrl() {
    return getURL("/categories");
  }

  get viewSwitcherAriaLabel() {
    return configuredText("view_switcher_aria_label", "view_switcher_aria_label");
  }

  get standardLabel() {
    return configuredText("standard_label", "standard_label");
  }

  get standardTitle() {
    return configuredText("standard_title", "standard_title");
  }

  get optinLabel() {
    return configuredText("optin_label", "optin_label");
  }

  get optinTitle() {
    return configuredText("optin_title", "optin_title");
  }

  get searchPlaceholder() {
    return configuredText("search_placeholder", "search_placeholder");
  }

  get searchAriaLabel() {
    return configuredText("search_aria_label", "search_aria_label");
  }

  get clearSearchTitle() {
    return configuredText("clear_search_title", "clear_search_title");
  }

  get clearSearchAriaLabel() {
    return configuredText("clear_search_aria_label", "clear_search_aria_label");
  }

  get wholeCategoryLabel() {
    return configuredText("whole_category_label", "whole_category_label");
  }

  get subcategoriesLabel() {
    return configuredText("subcategories_label", "subcategories_label");
  }

  get infoIconLabel() {
    return configuredText("info_icon_label", "info_icon_label");
  }

  get allCategories() {
    return readCategoryValue(this.site, "categories") || [];
  }

  get groupedCategories() {
    const allCategories = this.allCategories;
    const parents = allCategories.filter(
      (category) => !readCategoryValue(category, "parent_category_id")
    );
    const searchTerm = this.searchTerm.toLowerCase();

    const groupedCategories = parents.map((parent) => {
      const children = allCategories
        .filter(
          (category) =>
            readCategoryValue(category, "parent_category_id") === readCategoryValue(parent, "id")
        )
        .slice()
        .sort((a, b) =>
          readCategoryValue(a, "name").localeCompare(readCategoryValue(b, "name"))
        );

      const parentWrapped = this.wrapCategory(parent);
      return {
        parent: parentWrapped,
        children: children.map((child) => this.wrapCategory(child, parentWrapped.color)),
      };
    });

    if (!searchTerm) {
      return groupedCategories;
    }

    return groupedCategories
      .map((group) => {
        const parentMatch =
          group.parent.name.toLowerCase().includes(searchTerm) ||
          group.parent.description.toLowerCase().includes(searchTerm);

        const matchingChildren = group.children.filter(
          (child) =>
            child.name.toLowerCase().includes(searchTerm) ||
            child.description.toLowerCase().includes(searchTerm)
        );

        if (parentMatch || matchingChildren.length > 0) {
          return { ...group, children: matchingChildren };
        }

        return null;
      })
      .filter(Boolean);
  }

  getCategoryUrl(category) {
    const categoryUrl = readCategoryValue(category, "url");
    if (categoryUrl) {
      return getURL(categoryUrl);
    }

    const categoryId = readCategoryValue(category, "id");
    const categorySlug = readCategoryValue(category, "slug");
    const fullSlug = readCategoryValue(category, "full_slug");
    const parentCategoryId = readCategoryValue(category, "parent_category_id");
    let slug = fullSlug || categorySlug;

    if (parentCategoryId && !fullSlug) {
      const parent = this.allCategories.find(
        (item) => readCategoryValue(item, "id") === parentCategoryId
      );
      const parentSlug = readCategoryValue(parent, "slug");
      slug = parent ? `${parentSlug}/${categorySlug}` : categorySlug;
    }

    return `${getURL("/c/")}${slug}/${categoryId}`;
  }

  wrapCategory(category, parentColor = null) {
    const color = safeCategoryColor(readCategoryValue(category, "color"));
    const inheritedColor = parentColor ? safeCategoryColor(parentColor) : color;

    return {
      model: category,
      name: readCategoryValue(category, "name"),
      description:
        readCategoryValue(category, "description_text") ||
        readCategoryValue(category, "description_excerpt") ||
        "",
      url: this.getCategoryUrl(category),
      color,
      parentColor: inheritedColor,
      cardStyle: htmlSafe(`border-left-color: #${color}`),
      chipStyle: htmlSafe(`border-color: #${inheritedColor}`),
      notificationLevel: readCategoryValue(category, "notification_level"),
    };
  }

  updateBodyClass() {
    if (typeof document === "undefined") {
      return;
    }

    document.body.classList.toggle("optin-mode", this.showOptinView);
  }

  @action
  handleRouteDidChange() {
    this.routeVersion++;
    this.updateBodyClass();
  }

  @action
  onSearchTermChange(event) {
    this.searchTerm = event.target.value;
  }

  @action
  clearSearch() {
    this.searchTerm = "";
  }

  @action
  switchToStandard(event) {
    event.preventDefault();
    this.router
      ?.transitionTo("discovery.categories", {
        queryParams: { show_optin: undefined },
      })
      .then(() => this.updateBodyClass());
  }

  @action
  switchToOptin(event) {
    event.preventDefault();
    this.router
      ?.transitionTo("discovery.categories", {
        queryParams: { show_optin: "true" },
      })
      .then(() => this.updateBodyClass());
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.router?.off("routeDidChange", this.handleRouteDidChange);

    if (typeof document !== "undefined") {
      document.body.classList.remove("optin-mode");
    }
  }

  <template>
    <div class="optin-controls">
      <nav class="optin-view-switcher" aria-label={{this.viewSwitcherAriaLabel}}>
        <a
          href={{this.standardUrl}}
          class="optin-view-link {{unless this.showOptinView "active"}}"
          title={{this.standardTitle}}
          {{on "click" this.switchToStandard}}
        >
          {{this.standardLabel}}
        </a>
        <a
          href={{this.optinUrl}}
          class="optin-view-link {{if this.showOptinView "active"}}"
          title={{this.optinTitle}}
          {{on "click" this.switchToOptin}}
        >
          {{this.optinLabel}}
        </a>
      </nav>

      {{#if this.showOptinView}}
        <div class="optin-search-wrap">
          <span class="optin-search-icon" aria-hidden="true">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="currentColor"
            >
              <path d="M15.5 14h-.79l-.28-.27A6.471 6.471 0 0 0 16 9.5 6.5 6.5 0 1 0 9.5 16c1.61 0 3.09-.59 4.23-1.57l.27.28v.79l5 4.99L20.49 19l-4.99-5zm-6 0C7.01 14 5 11.99 5 9.5S7.01 5 9.5 5 14 7.01 14 9.5 11.99 14 9.5 14z" />
            </svg>
          </span>
          <input
            type="text"
            value={{this.searchTerm}}
            placeholder={{this.searchPlaceholder}}
            class="optin-search-input"
            aria-label={{this.searchAriaLabel}}
            {{on "input" this.onSearchTermChange}}
          />
          {{#if this.searchTerm}}
            <button
              type="button"
              class="optin-search-clear"
              {{on "click" this.clearSearch}}
              title={{this.clearSearchTitle}}
              aria-label={{this.clearSearchAriaLabel}}
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="currentColor"
              >
                <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z" />
              </svg>
            </button>
          {{/if}}
        </div>
      {{/if}}
    </div>

    {{#if this.showOptinView}}
      <div class="optin-grid">
        {{#each this.groupedCategories as |group|}}
          <section
            class="optin-card"
            style={{group.parent.cardStyle}}
          >
            <div class="optin-card-header">
              <a href={{group.parent.url}} class="optin-category-link">{{group.parent.name}}</a>
            </div>

            {{#if group.parent.description}}
              <div class="optin-card-description">
                {{group.parent.description}}
              </div>
            {{/if}}

            <div class="optin-parent-actions">
              <OptinNotificationButton
                @category={{group.parent.model}}
                @children={{group.children}}
                @label={{this.wholeCategoryLabel}}
              />
            </div>

            {{#if group.children.length}}
              <div class="optin-subcats-label">
                <span class="optin-chevron">▼</span>
                {{this.subcategoriesLabel}}
              </div>
              <div class="optin-subcats">
                {{#each group.children as |sub|}}
                  <span
                    class="optin-chip"
                    data-notification-level={{sub.notificationLevel}}
                    style={{sub.chipStyle}}
                  >
                    <a href={{sub.url}} class="optin-category-link">{{sub.name}}</a>

                    {{#if sub.description}}
                      <span class="optin-info-icon">
                        <span class="optin-info-i">{{this.infoIconLabel}}</span>
                        <div class="optin-info-tooltip">
                          {{sub.description}}
                        </div>
                      </span>
                    {{/if}}

                    <OptinNotificationButton @category={{sub.model}} />
                  </span>
                {{/each}}
              </div>
            {{/if}}
          </section>
        {{/each}}
      </div>
    {{/if}}
  </template>
}
