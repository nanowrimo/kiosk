require 'nokogiri'

module Kiosk
  # Rewrites the content of resources.
  #
  class Rewriter

    # Creates a new content rewriter.
    #
    def initialize
      @claims = {}
      @rewrites = []
    end

    # Adds a +Claim+ to the rewriter. This is typically done indirectly
    # using +Resource.claims_content+ in each resource model.
    #
    # Options:
    #
    # - +:priority+: Claims with higher priority (a lower value) take
    #                precedence. Symbols +:high+, +:normal+, +:low+ map to
    #                values -9, 0, and 9 respectively.
    #
    def add_claim(claim, options = {})
      priority = {
        :high => -9,
        :normal => 0,
        :low => 9
      }.fetch(options[:priority], options[:priority] || 0)

      (@claims[priority] || (@claims[priority] = [])) << claim
    end

    # Adds a rewrite rule to the rewriter. This is typically done indirectly
    # using +Controller.rewrite_content_for+ in each controller.
    #
    def add_rewrite(rewrite)
      @rewrites << rewrite
    end

    # Clears all rewrite rules.
    #
    def reset!
      @rewrites.clear
    end

    # Runs on claims on the given content, incorporates all controller
    # rewrites, and returns the resulting content.
    #
    def rewrite(content)
      document = Document.parse(content)

      # Claims are grouped by priority. Process them in order.
      @claims.keys.sort.each do |k|

        # Iterate of all claims in this priority group.
        @claims[k].each do |claim|

          # Stake the claim on the content.
          claim.stake!(document) do |node|
            # Process all rewrites on the claimed node.
            @rewrites.each do |rewrite|
              rewrite.evaluate(node) if rewrite.matches?(node)
            end
          end
        end
      end

      document.to_html
    end
  end
end
