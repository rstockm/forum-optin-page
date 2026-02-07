import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import icon from "discourse-common/helpers/d-icon";

const LEVELS = [
  { id: 3, icon: "d-watching", label: "Beobachten" },
  { id: 2, icon: "d-tracking", label: "Verfolgen" },
  { id: 1, icon: "d-normal", label: "Normal" },
  { id: 0, icon: "d-muted", label: "Stummgeschaltet" },
];

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
      LEVELS.find((l) => l.id === this.notificationLevel) ||
      LEVELS.find((l) => l.id === 1)
    );
  }

  get levels() {
    return LEVELS;
  }

  @action
  toggleDropdown(event) {
    event.preventDefault();
    event.stopPropagation();
    this.dropdownOpen = !this.dropdownOpen;
  }

  @action
  closeDropdown() {
    this.dropdownOpen = false;
  }

  @action
  async selectLevel(levelId, event) {
    event.preventDefault();
    event.stopPropagation();
    this.dropdownOpen = false;
    if (this.category?.setNotification) {
      await this.category.setNotification(levelId);
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
                class="optin-notification-dropdown-item {{if (eq lvl.id this.notificationLevel) 'selected'}}"
                {{on "click" (fn this.selectLevel lvl.id)}}
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
