import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="app"
export default class extends Controller {
  connect() {}

  showOverlay(event) {
    const overlayEl = document.getElementById("overlay");
    overlayEl.classList.add("overlay--visible");
    console.log(event);
  }
}
