import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["sidebar"];
  static classes = ["active"];
  connect() {}

  open() {
    this.sidebarTarget.classList.add(this.activeClass);
  }

  close() {
    this.sidebarTarget.classList.remove(this.activeClass);
  }
}
