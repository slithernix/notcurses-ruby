module Notcurses
  module SwigMixins
    module StructInitializer
      def self.included(base)
        base.class_eval do
          alias_method :swig_initialize, :initialize

          def initialize(**options)
            swig_initialize

            options.each do |k, v|
              setter = "#{k}="

              unless respond_to?(setter)
                raise ArgumentError, "Unknown attribute: #{k}"
              end

              send(setter, v)
            end
          end
        end
      end
    end
  end
end
