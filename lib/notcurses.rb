# frozen_string_literal: true
#
# Temporarily suppress warnings to kill allocator warnings, should be fixed
# in SWIG 4.2
$VERBOSE = nil
require 'notcurses.so'

require_relative 'notcurses/version'
require_relative 'notcurses/swig_mixins/struct_initializer'
require_relative 'notcurses/swig_mixins/to_h'

module Notcurses
  # No matter how hard I tried I could not get SWIG to do this for me.
  class << self
    alias_method :ncplane_vprintf_yx, :ruby_ncplane_vprintf_yx
    alias_method :ncplane_vprintf, :ruby_ncplane_vprintf
    alias_method :ncplane_vprintf_aligned, :ruby_ncplane_vprintf_aligned
    alias_method :ncplane_vprintf_stained, :ruby_ncplane_vprintf_stained
  end

  # This is a stub, couldn't find an easy way to figure this out looking at
  # constants and methods etc. There is an instance variable but I'd have to
  # instantiate it to get it...
  def self.swig_generated_class?(klass)
    true
  end

  # "Mixin' the Swiiiggssss" -- Pauly Shore
  constants.each do |const_name|
    const = const_get(const_name)
    if const.is_a?(Class) && swig_generated_class?(const)
      const.include(SwigMixins::StructInitializer)
      const.include(SwigMixins::ToH)
    end
  end
end

