module Ifsc
  class DomScraper
    BASE_URL = "https://ifsc.results.info"

    class ScraperError < StandardError; end

    def initialize
      @browser = Ferrum::Browser.new(headless: true, timeout: 30)
    end

    # Navigate to category result page and parse rendered DOM.
    # Returns: { ranking: [...], climbs: [...] }
    def fetch_category_results(event_id, category_id)
      @browser.goto("#{BASE_URL}/event/#{event_id}/cr/#{category_id}")
      wait_for_results
      parse_results
    end

    def close
      @browser.quit
    end

    private

    def wait_for_results
      # Wait for network idle after JS renders the results table
      @browser.network.wait_for_idle(duration: 0.5, timeout: 15)
    rescue Ferrum::TimeoutError
      # Proceed even if not fully idle; DOM may still be usable
    end

    def parse_results
      # Discipline-specific parsing strategies.
      # Selectors are confirmed by inspecting the live rendered DOM.
      # The IFSC SPA renders results into elements with class-based markers:
      #   - Competitor name: elements with [class*="name"] or role-based selectors
      #   - Boulder tops: elements with class "top topped" (topped) vs "top" (not topped)
      #   - Lead height: text content of height column cells
      #   - Speed times: text content of time column cells
      raise NotImplementedError, "Implement discipline-specific parsers after inspecting live DOM"
    end
  end
end
