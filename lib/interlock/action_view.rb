module ActionView #:nodoc:
  module Helpers #:nodoc:
    module CacheHelper

=begin rdoc

<tt>view_cache</tt> marks a corresponding view block for caching. It accepts <tt>:tag</tt> and <tt>:ignore</tt> keys for explicit scoping, as well as a <tt>:ttl</tt> key and a <tt>:perform</tt> key.

You can specify dependencies in <tt>view_cache</tt> if you really want to. Note that unlike <tt>behavior_cache</tt>, <tt>view_cache</tt> doesn't set up any default dependencies.

Nested <tt>view_cache</tt> blocks work fine. You would only need to nest if you had a slowly invalidating block contained in a more quickly invalidating block; otherwise there's no benefit.

Finally, caching <tt>content_for</tt> within a <tt>view_cache</tt> works, unlike regular Rails. It even works in nested caches.

== Setting a TTL

Use the <tt>:ttl</tt> key to specify a maximum time-to-live, in seconds:

  <% view_cache :ttl => 5.minutes do %>
  <% end %>

Note that the cached item is not guaranteed to live this long. An invalidation rule could trigger first, or memcached could eject the item early due to the LRU.

== View caching without action caching

It's fine to use a <tt>view_cache</tt> block without a <tt>behavior_cache</tt> block. For example, to mimic regular fragment cache behavior, but take advantage of memcached's <tt>:ttl</tt> support, call:

  <% view_cache :ignore => :all, :tag => 'sidebar', :ttl => 5.minutes do %>
  <% end %>

== Dependencies, scoping, and other options

See ActionController::Base for explanations of the rest of the options. The <tt>view_cache</tt> and <tt>behavior_cache</tt> APIs are identical except for setting the <tt>:ttl</tt>, which can only be done in the view, and the default dependency, which is only set by <tt>behavior_cache</tt>.

=end
      def view_cache(*args, &block)
        options, dependencies = Interlock.extract_options_and_dependencies(args, nil)

        key = controller.caching_key(options.value_for_indifferent_key(:ignore), options.value_for_indifferent_key(:tag))

        if options[:perform] == false || Interlock.config[:disabled]
          capture &block
        else
          Interlock.register_dependencies(dependencies, key)

          @_content_for, previous_cached_content_for = Hash.new { |h, k| h[k] = ActiveSupport::SafeBuffer.new }, @_content_for

          cached_content = Rails.cache.read(key)
          unless cached_content
            cached_content = capture(&block)
            Rails.cache.write key, cached_content, :ttl => (options.value_for_indifferent_key(:ttl) or Interlock.config[:ttl])
          end
          if (cached_block_content = Rails.cache.read(key + ':content_for'))
            @_content_for = cached_block_content
          else
            Rails.cache.write key + ':content_for', {}.merge(@_content_for), :ttl => (options.value_for_indifferent_key(:ttl) or Interlock.config[:ttl])
          end
          # This is tricky. If we were already caching content_fors in a parent block, we need to
          # append the content_fors set in the inner block to those already set in the outer block.
          previous_cached_content_for.merge!(@_content_for) { |k, value1, value2| "#{value1}#{value2}" }
          # Restore the cache state
          @_content_for = previous_cached_content_for
          cached_content
        end
      end
    end
  end
end
