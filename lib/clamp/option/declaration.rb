require 'clamp/attribute/declaration'
require 'clamp/option/definition'

module Clamp
  module Option

    module Declaration

      include Clamp::Attribute::Declaration

      def option(switches, type, description, opts = {}, &block)
        # merge in any options from the current option group
        opts.merge!(current_option_group)

        Option::Definition.new(switches, type, description, opts).tap do |option|
          declared_options << option
          block ||= option.default_conversion_block
          define_accessors_for(option, &block)
        end
      end

      def option_group(name = nil, opts = {}, &block)
        new_group = current_option_group.merge(opts).tap do |h|
          h[:group] = name unless name.nil?
        end

        option_group_stack.push new_group

        begin
          yield current_option_group
        ensure
          option_group_stack.pop
        end
      end

      def find_option(switch)
        recognised_options.find { |o| o.handles?(switch) }
      end

      def declared_options
        @declared_options ||= []
      end

      def recognised_options
        declare_implicit_options
        effective_options
      end

      private

      def option_group_stack
        @option_group_stack ||= []
      end

      def current_option_group
        option_group_stack.last || {}
      end

      def declare_implicit_options
        return nil if defined?(@implicit_options_declared)
        unless effective_options.find { |o| o.handles?("--help") }
          help_switches = ["--help"]
          help_switches.unshift("-h") unless effective_options.find { |o| o.handles?("-h") }
          option help_switches, :flag, "print help" do
            request_help
          end
        end
        @implicit_options_declared = true
      end

      def effective_options
        ancestors.inject([]) do |options, ancestor|
          if ancestor.kind_of?(Clamp::Option::Declaration)
            options + ancestor.declared_options
          else
            options
          end
        end
      end

    end

  end
end
