import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="app"
export default class extends Controller {
  connect() {
    document.addEventListener("turbo:before-visit", this.showOverlay);
  }

  showOverlay(event) {
    const overlayEl = document.getElementById("overlay");
    overlayEl.classList.add("overlay--visible");
    console.log(event);
  }
}
