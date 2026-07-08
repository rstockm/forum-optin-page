/**
 * OptinNotificationButton
 *
 * Glimmer component for category notification level selection (watch, track, mute, etc.).
 * Uses Discourse d-icon helper for bell icons (works in component context).
 *
 * DISCOURSE CONVENTIONS:
 * - @glimmer/component, @tracked, @action, @service
 * - Uses category.setNotification() for persistence
 * - Uses btn btn-default for button styling
 *
 * DEVIATION: Module-level activeDropdown variable
 * Discourse typically avoids global/shared state. We use it to ensure only one
 * dropdown is open at a time and to handle click-outside. Alternative would be
 * a service or parent coordination; this keeps the component self-contained.
 */
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";
import icon from "discourse-common/helpers/d-icon";

const LEVEL_DATA = [
  {
    id: 3,
    icon: "d-watching",
    settingName: "level_watching_label",
    translationKey: "level_watching_label",
  },
  {
    id: 2,
    icon: "d-tracking",
    settingName: "level_tracking_label",
    translationKey: "level_tracking_label",
  },
  {
    id: 4,
    icon: "d-watching-first",
    settingName: "level_watching_first_label",
    translationKey: "level_watching_first_label",
  },
  {
    id: 1,
    icon: "d-regular",
    settingName: "level_normal_label",
    translationKey: "level_normal_label",
  },
  {
    id: 0,
    icon: "d-muted",
    settingName: "level_muted_label",
    translationKey: "level_muted_label",
  },
];

function configuredText(settingName, translationKey) {
  const settingValue =
    typeof themeSetting !== "undefined" ? themeSetting[settingName] : null;
  const trimmedValue =
    typeof settingValue === "string" ? settingValue.trim() : settingValue;

  return trimmedValue || i18n(themePrefix(translationKey));
}

/* DEVIATION: Shared state for single-dropdown rule. See file header. */
let activeDropdown = null;

export default class OptinNotificationButton extends Component {
  @service currentUser;

  @tracked dropdownOpen = false;

  get category() {
    return this.args.category;
  }

  get notificationLevel() {
    return this.category?.get
      ? this.category.get("notification_level")
      : this.category?.notification_level;
  }

  get currentLevelInfo() {
    return (
      this.levels.find((l) => l.id === this.notificationLevel) ||
      this.levels.find((l) => l.id === 1)
    );
  }

  get levels() {
    const current = this.notificationLevel;
    return LEVEL_DATA.map((l) => ({
      ...l,
      label: configuredText(l.settingName, l.translationKey),
      selected: l.id === current,
      cssClass:
        "optin-notification-dropdown-item" +
        (l.id === current ? " selected" : ""),
    }));
  }

  @action
  toggleDropdown(event) {
    event.preventDefault();
    event.stopPropagation();

    if (activeDropdown && activeDropdown !== this) {
      activeDropdown.close();
    }

    this.dropdownOpen = !this.dropdownOpen;

    if (this.dropdownOpen) {
      activeDropdown = this;
      window.addEventListener("click", this.outsideClick);
    } else {
      this.close();
    }
  }

  @action
  outsideClick() {
    this.close();
  }

  @action
  close() {
    this.dropdownOpen = false;
    window.removeEventListener("click", this.outsideClick);
    if (activeDropdown === this) {
      activeDropdown = null;
    }
  }

  @action
  handleItemClick(event) {
    event.preventDefault();
    event.stopPropagation();
    const levelId = parseInt(event.currentTarget.dataset.level, 10);
    this.close();

    // Update parent category (Discourse category model API)
    if (this.category?.setNotification) {
      this.category.setNotification(levelId);
    }

    // DEVIATION: Cascade to subcategories. Not standard Discourse behaviour;
    // we extend it for the whole-category action.
    if (this.args.children) {
      this.args.children.forEach((child) => {
        const childModel = child.model || child;
        if (childModel?.setNotification) {
          childModel.setNotification(levelId);
        }
      });
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    /* Cleanup: remove global listener and shared state reference */
    window.removeEventListener("click", this.outsideClick);
    if (activeDropdown === this) {
      activeDropdown = null;
    }
  }

  <template>
    {{#if this.currentUser}}
      <div class="optin-notification-btn-wrap {{if this.dropdownOpen "is-dropdown-open"}}">
        <button
          class="btn btn-default optin-notification-btn {{if @label "has-label"}} level-{{this.currentLevelInfo.id}}"
          title={{this.currentLevelInfo.label}}
          {{on "click" this.toggleDropdown}}
        >
          {{#if @label}}
            <span class="optin-btn-text">{{@label}}</span>
          {{/if}}
          {{icon this.currentLevelInfo.icon}}
        </button>

        {{#if this.dropdownOpen}}
          <div class="optin-notification-dropdown">
            {{#each this.levels as |lvl|}}
              <button
                class={{lvl.cssClass}}
                data-level={{lvl.id}}
                {{on "click" this.handleItemClick}}
              >
                {{icon lvl.icon}}
                <span>{{lvl.label}}</span>
              </button>
            {{/each}}
          </div>
        {{/if}}
      </div>
    {{/if}}
  </template>
}
