import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    // Auto-dismiss after 5 seconds
    this.timeout = setTimeout(() => {
      this.dismiss()
    }, 5000)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  dismiss() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }

    if (!this.element) return

    // Use a more robust way to hide before removal
    this.element.style.opacity = '0'
    this.element.style.transform = 'translateY(-0.5rem)'
    this.element.style.transition = 'opacity 300ms, transform 300ms'
    
    // Wait for transition to finish before removing
    setTimeout(() => {
      if (this.element) {
        this.element.remove()
      }
    }, 300)
  }
}
