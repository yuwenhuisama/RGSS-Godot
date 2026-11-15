# RGSS resource properties reject access after disposal. The wrappers are the
# public boundary; disposal queries and disposal itself remain usable.
class RGSSError < StandardError
end unless Object.const_defined?(:RGSSError)

class RGSSReset < Exception
end unless Object.const_defined?(:RGSSReset)

module ResourceLifecycle
  def self.guard(klass)
    methods = klass.instance_methods(false) - [:initialize, :dispose, :disposed?, :__handler__, :hash, :eql?]
    methods.each do |name|
      original = klass.instance_method(name)
      klass.define_method(name) do |*args|
        raise RGSSError, 'disposed resource' if @__handler__.disposed?
        original.bind(self).call(*args)
      end
    end
  end
end
