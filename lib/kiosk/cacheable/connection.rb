module Kiosk
  module Cacheable::Connection
    # Sets a value or block used to determine the expiry of written cache
    # entries. If a block is given, its first argument will be the object that
    # is about to be written.
    #
    def cache_expiry=(expiry)
      @cache_expiry = expiry.is_a?(Proc) ? expiry : Proc.new { |r| expiry }
    end

    # Returns the expiry in seconds for the given resource.
    #
    def cache_expiry_of(resource)
      @cache_expiry && @cache_expiry.call(resource)
    end

    def cache_expire_by_path(path)
      cache(:delete, cache_key(path))
    end

    def cache_expire_by_pattern(pattern)
      key_base = cache_key("")
      key = pattern.is_a?(Regexp) ? /^#{key_base}#{pattern}/ : "#{key_base}#{pattern}"
      cache(:delete_matched, key)
    end

    # Returns the type of key matcher supported by the cache store. Note that
    # the type returned here may not be accurate for cache stores that don't
    # support matchers at all. For those cases, you should still expect
    # NotImplemented exceptions to be thrown when calling
    # +cache_expire_by_pattern+.
    #
    def cache_key_matcher
      if defined?(ActiveSupport::Cache::RedisStore) && Rails.cache.is_a?(ActiveSupport::Cache::RedisStore)
        :glob
      else
        :regexp
      end
    end

    def get(*arguments) #:nodoc:
      cache_read_write(arguments.first) { super }
    end

    def delete(*arguments) #:nodoc:
      cache_expire(arguments.first) { super }
    end

    def put(*arguments) #:nodoc:
      cache_expire(arguments.first) { super }
    end

    def post(*arguments) #:nodoc:
      cache_expire(arguments.first) { super }
    end

    def head(*arguments) #:nodoc:
      cache_read_write(arguments.first) { super }
    end

    private

    # Proxy for the Rails cache store.
    #
    def cache(operation, *arguments)
      Rails.cache.send(operation, *arguments) if Rails.cache
    end

    # Wraps the given block in a cache read/write pattern. If a cached entry
    # is not found using the given key then the result of the yielded block is
    # written to the cache using the same key. Either a previously cached or
    # fresh result is returned.
    #
    def cache_read_write(key)
      if cached_object = cache(:read, cache_key(key))
        result = cached_object
      elsif result = yield
        options = (expiry = cache_expiry_of(result)) ? {:expires_in => expiry} : {}
        cache(:write, cache_key(key), result, options) if result
      end
      result
    end

    # Wraps the given block in a cache deletion. The cache entry identified by
    # the given key is deleted after the block is yielded. If any uncaught
    # exception occurs during the yield, the entry will not be deleted.
    #
    def cache_expire(key)
      result = yield
      cache(:delete, cache_key(key))
      result
    end

    # Constructs a fully qualified URL from the given path, to be used as a
    # cache key.
    #
    def cache_key(path)
      "#{site.scheme}://#{site.host}:#{site.port}#{path}"
    end
  end
end
