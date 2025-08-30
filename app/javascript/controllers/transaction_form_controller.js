import { Controller } from "@hotwired/stimulus";
import { post } from "@rails/request.js";

// Connects to data-controller="transaction-form"
export default class extends Controller {
  static targets = ["summary", "amount", "rate", "costRate", "total", "profit"];

  connect() {}

  async calculate() {
    const costRate = this.costRateTarget.value;
    const rate = this.rateTarget.value;
    const amount = this.amountTarget.value;

    const url = "/madmin/transactions/calculate";

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
    const totalEvent = new CustomEvent("number-input:changed", {
      detail: total,
    });
    const profitEvent = new CustomEvent("number-input:changed", {
      detail: profit,
    });
    this.totalTarget.dispatchEvent(totalEvent);
    this.profitTarget.dispatchEvent(profitEvent);
  }
}
