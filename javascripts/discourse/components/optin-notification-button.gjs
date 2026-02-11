import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import icon from "discourse-common/helpers/d-icon";

const LEVEL_DATA = [
  { id: 3, icon: "d-watching", label: "Beobachten" },
  { id: 2, icon: "d-tracking", label: "Verfolgen" },
  { id: 4, icon: "d-watching-first", label: "Ersten Beitrag beobachten" },
  { id: 1, icon: "d-regular", label: "Normal" },
  { id: 0, icon: "d-muted", label: "Stummgeschaltet" },
];

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
      LEVEL_DATA.find((l) => l.id === this.notificationLevel) ||
      LEVEL_DATA.find((l) => l.id === 1)
    );
  }

  get levels() {
    const current = this.notificationLevel;
    return LEVEL_DATA.map((l) => ({
      ...l,
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
    if (this.category?.setNotification) {
      this.category.setNotification(levelId);
    }
  }

  willDestroy() {
    super.willDestroy(...arguments);
    window.removeEventListener("click", this.outsideClick);
    if (activeDropdown === this) {
      activeDropdown = null;
    }
  }

  <template>
    {{#if this.currentUser}}
      <div class="optin-notification-btn-wrap">
        <button
          class="btn btn-default optin-notification-btn level-{{this.currentLevelInfo.id}}"
          title={{this.currentLevelInfo.label}}
          {{on "click" this.toggleDropdown}}
        >
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
