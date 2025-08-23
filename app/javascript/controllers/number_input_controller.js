import { Controller } from "@hotwired/stimulus";
import IMask from "imask";

export default class extends Controller {
  connect() {
    const config = {
      es: {
        scale: 10,
        thousandsSeparator: ".",
        radix: ",",
        padFractionalZeros: false,
        normalizeZeros: true,
        mapToRadix: [",", "."],
      },
      en: {
        thousandsSeparator: ",",
        padFractionalZeros: true,
        normalizeZeros: true,
        radix: ".",
        mapToRadix: [".", ","],
      },
    };
    const currentLng = document.documentElement.lang || "es";
    const currentConfig = config[currentLng];

    IMask(this.element, {
      mask: Number,
      scale: 0,
      min: 0,
      ...currentConfig,
    });
  }
}
