#
# result_set.rb
# ConstantContact
#
# Copyright (c) 2013 Constant Contact. All rights reserved.

module ConstantContact
  module Components
    class ResultSet
      attr_accessor :results, :next


      # Constructor to create a ResultSet from the results/meta response when performing a get on a collection
      # @param [Array<Hash>] results - results array from request
      # @param [Hash] meta - meta hash from request
      def initialize(results, meta, component = nil)
        @results = results
        if component.present?
          @component = component
        end

        if meta.has_key?('pagination') and meta['pagination'].has_key?('next_link')
          @next_link = meta['pagination']['next_link']
          @next = @next_link[@next_link.index('?'), @next_link.length]
        end
      end

      def next_results
        if @next_link.present? and @component.present?
          url = Util::Config.get('endpoints.api_url') + @next_link
          url = url.gsub(@next, "")
          url = Services::BaseService.build_url(url, {
            :next => @next.split("next=")[1]
          })
          response = RestClient.get(url, Services::BaseService.get_headers())
          body = JSON.parse(response.body)

          events = body['results'].collect do |event|
            @component.create_summary(event)
          end

          return Components::ResultSet.new(events, body['meta'], @component)
        else
          return nil
        end
      end

    end
  end
end