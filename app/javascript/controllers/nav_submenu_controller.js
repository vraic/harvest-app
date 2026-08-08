import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "menu", "indicator"]
  static values = { expanded: Boolean }

  connect() {
    this.render()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
    this.render()
  }

  render() {
    this.toggleTarget.setAttribute("aria-expanded", this.expandedValue)
    this.menuTarget.classList.toggle("hidden", !this.expandedValue)
    this.indicatorTarget.classList.toggle("rotate-90", this.expandedValue)
  }
}