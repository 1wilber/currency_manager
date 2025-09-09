import { Controller } from "@hotwired/stimulus";
import flatpickr from "flatpickr";
import { Spanish } from "flatpickr/dist/l10n/es.js";

// Connects to data-controller="date-picker"
export default class extends Controller {
  static values = {
    defaultDate: { type: String, default: "" },
  };
  connect() {
    flatpickr.localize(Spanish);
    flatpickr(this.element, {
      maxDate: "today",
      dateFormat: "d/m/Y",
      defaultDate: this.defaultDateValue,
    });
  }
}
