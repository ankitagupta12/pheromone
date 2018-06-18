# calls a proc or method
module Pheromone
  module MethodInvoker
    module InstanceMethods
      # This method has the :reek:ManualDispatch smell,
      # which is difficult to avoid since it handles
      # either a lambda/Proc or a named method from the including
      # class.
      def call_proc_or_instance_method(proc_or_symbol, argument = nil)
        return proc_or_symbol.call(argument || self) if proc_or_symbol.respond_to?(:call)
        unless respond_to? proc_or_symbol
          raise "Method #{proc_or_symbol} not found for #{self.class.name}"
        end
        __send__(proc_or_symbol)
      end
    end

    def self.included(base)
      base.send :include, InstanceMethods
    end
  end
end