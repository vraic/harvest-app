import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modeInput", "platformFields", "manualFields", "platformInput", "manualInput"]

  connect() {
    this.switchMode()
  }

  switchMode() {
    const manualEntry = this.selectedMode() === "manual_entry"

    this.platformFieldsTarget.classList.toggle("hidden", manualEntry)
    this.manualFieldsTarget.classList.toggle("hidden", !manualEntry)

    this.platformInputTargets.forEach((target) => {
      target.disabled = manualEntry
    })

    this.manualInputTargets.forEach((target) => {
      target.disabled = !manualEntry
    })
  }

  selectedMode() {
    return this.modeInputTargets.find((target) => target.checked)?.value || "platform_store"
  }
}