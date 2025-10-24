import { Controller } from "@hotwired/stimulus";
import { post } from "@rails/request.js";

// Connects to data-controller="transaction-form"
export default class extends Controller {
  static targets = ["summary", "amount", "rate", "costRate", "total", "profit"];

  connect() {
    console.log(this.element);
  }

  async calculate() {
    const rate = this.rateTarget.value;
    const amount = this.amountTarget.value;
    const costRate = this.costRateTarget.value;

    const url = "/transactions/calculate";

    const query = new URLSearchParams([
      ["amount", amount],
      ["rate", rate],
      ["cost_rate", costRate],
    ]);

    const { response } = await post(url, {
      responseKind: "json",
      query,
    });
    const body = await response.json();
    const { total, profit } = body;
    const costRateEvent = new CustomEvent("number-input:changed", {
      detail: costRate,
    });
    const totalEvent = new CustomEvent("number-input:changed", {
      detail: total,
    });
    const profitEvent = new CustomEvent("number-input:changed", {
      detail: profit,
    });

    this.costRateTarget.dispatchEvent(costRateEvent);
    this.totalTarget.dispatchEvent(totalEvent);
    this.profitTarget.dispatchEvent(profitEvent);
  }
}
