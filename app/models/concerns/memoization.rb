# simple memoization implementation
# how to use: include it, then anywhere in the method:
# memoize(param1, param2, param3) do block
# if all parameters are equal then value will not be recalculated
# Difference from, say, Rails.cache that this is per-instance cache

module Memoization
  extend ActiveSupport::Concern
  def memoize(*keys, &block)
    key = construct_memoization_key(*keys)
    instance_name = memo_instance_name

    if instance_variable_get(instance_name).nil?
      instance_variable_set(instance_name, {})
    end

    hash = instance_variable_get(instance_name)
    hash[key] ||= yield
  end

  private

  def construct_memoization_key(*keys)
    keys.map do |key|
      if key.is_a?(ActiveRecord::Base)
        "#{key.class}-#{key.id}"
      else
        # then calling to_s and hoping for the best
        key.to_s
      end
    end.join('/')
  end

  def memo_instance_name
    method_name = caller_locations(2,1)[0].label.
      gsub('!', '__bang').
      gsub('?', '__question')
    "@__memoization_#{method_name}"
  end
end
