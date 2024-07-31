# There might be a better way, but this works.
module Notcurses
  module SwigMixins
    module ToH
      def self.included(base)
        base.class_eval do
          def to_h
            hash = {}
            meffids = self.class.instance_methods(false).select{|m| m !~ /=$/}

            meffids.each do |m|
              next if (m == :to_h || m =~ /=$/)
              hash[m] = send(m)[:return] if method(m).arity < 1
            end

            hash
          end
        end
      end
    end
  end
end
