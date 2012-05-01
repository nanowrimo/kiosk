require 'active_support/concern'

module Kiosk
  module Cacheable::Resource
    extend ActiveSupport::Concern

    included do
      def self.inherited(sub)
        super

        sub.module_exec do
          protected

          # Returns expireable connection keys set by derived class and all
          # parent classes.
          #
          def self.all_connection_keys_to_expire
            keys = @connection_keys_to_expire || []

            if superclass.respond_to?(:all_connection_keys_to_expire)
              superclass.all_connection_keys_to_expire | keys
            else
              keys
            end
          end
        end
      end
    end

    module ClassMethods
      # Specifies the length of time for which a resource should stay cached.
      # Either a +Fixnum+ (time in seconds) or block can be given. The block
      # should accept the resource as its argument and should return the
      # expiry time for the resource in seconds.
      #
      # Keep in mind that the underlying cache store may not support
      # expiration length. In that case, this option has no effect.
      #
      def cached_expire_in(expiry = nil, &blk)
        connection.cache_expiry = expiry || blk
      end

      # Reimplements method to provide a cacheable connection.
      #
      def connection(*args)
        connection = super(*args)
        connection.extend(Cacheable::Connection) unless connection.is_a?(Cacheable::Connection)
        connection
      end

      # Expire from the cache the resource identified by the given id.
      #
      def expire(id)
        connection.cache_expire_by_path(element_path(id))
      end

      # Expire from the cache the resource identified by the given slug.
      #
      def expire_by_slug(slug)
        connection.cache_expire_by_path(element_path_by_slug(slug))
      end

      # Expire from the cache the resource identified by both the slug and id.
      # Notify any observers of expiration.
      #
      def expire_resource(resource)
        notify_observers(:before_expire, resource)

        expire(resource.id)
        expire_by_slug(resource.slug)

        begin
          all_connection_keys_to_expire.each { |key| connection.cache_expire_by_pattern(key) }
        rescue NotImplementedError
        end

        notify_observers(:after_expire, resource)
      end

      # When a resource is explicitly expired from the cache, cache entries
      # matching URLs to the given API method are deleted as well.
      #
      def expires_connection_methods(*methods)
        matchers = methods.map do |method|
          case connection.cache_key_matcher
          when :glob
            "#{api_path_to(method)}*"
          when :regexp
            /^#{Regexp.escape(api_path_to(method))}/
          end
        end

        expires_connection_keys(*matchers)
      end

      private

      def expires_connection_keys(*keys)
        (@connection_keys_to_expire ||= []).concat(keys)
      end
    end

    module InstanceMethods
      # Expire the resource from the cache.
      #
      def expire
        self.class.expire_resource(self)
      end
    end
  end
end
