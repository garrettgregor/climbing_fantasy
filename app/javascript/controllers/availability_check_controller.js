import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["displayNameInput", "emailInput", "displayNameStatus", "emailStatus"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
    this.abortController = null
  }

  disconnect() {
    this.clearDebounce()
    this.abortInFlightRequest()
  }

  check() {
    this.clearDebounce()
    this.debounceTimer = setTimeout(() => this.fetchAvailability(), 300)
  }

  async fetchAvailability() {
    const params = new URLSearchParams({
      display_name: this.displayNameInputTarget.value,
      email: this.emailInputTarget.value,
    })

    this.abortInFlightRequest()
    this.abortController = new AbortController()

    try {
      const response = await fetch(`${this.urlValue}?${params.toString()}`, {
        headers: { Accept: "application/json" },
        signal: this.abortController.signal,
      })
      if (!response.ok) return

      const payload = await response.json()
      this.renderStatus(this.displayNameStatusTarget, payload.display_name)
      this.renderStatus(this.emailStatusTarget, payload.email)
    } catch (error) {
      if (error.name === "AbortError") return

      this.showError(this.displayNameStatusTarget)
      this.showError(this.emailStatusTarget)
    } finally {
      this.abortController = null
    }
  }

  clearDebounce() {
    if (!this.debounceTimer) return

    clearTimeout(this.debounceTimer)
    this.debounceTimer = null
  }

  abortInFlightRequest() {
    if (!this.abortController) return

    this.abortController.abort()
    this.abortController = null
  }

  renderStatus(target, availability) {
    target.textContent = availability.message
    target.classList.remove("text-gray-500", "text-red-400", "text-green-400")

    if (availability.available === true) {
      target.classList.add("text-green-400")
      return
    }

    if (availability.available === false) {
      target.classList.add("text-red-400")
      return
    }

    target.classList.add("text-gray-500")
  }

  showError(target) {
    target.textContent = "Unable to check right now"
    target.classList.remove("text-gray-500", "text-green-400")
    target.classList.add("text-red-400")
  }
}
