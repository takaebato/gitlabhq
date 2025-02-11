# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Prefer using `.strong_memoize_attr()` over `#strong_memoize()`. See
      # https://docs.gitlab.com/ee/development/utilities.html/#strongmemoize.
      #
      # Good:
      #
      #     def memoized_method
      #       'This is a memoized method'
      #     end
      #     strong_memoize_attr :memoized_method
      #
      # Bad, can be autocorrected:
      #
      #     def memoized_method
      #       strong_memoize(:memoized_method) do
      #         'This is a memoized method'
      #       end
      #     end
      #
      # Very bad, can't be autocorrected:
      #
      #     def memoized_method
      #       return unless enabled?
      #
      #       strong_memoize(:memoized_method) do
      #         'This is a memoized method'
      #       end
      #     end
      #
      class StrongMemoizeAttr < RuboCop::Cop::Base
        extend RuboCop::Cop::AutoCorrector

        MSG = 'Use `strong_memoize_attr`, instead of using `strong_memoize` directly'

        def_node_matcher :strong_memoize?, <<~PATTERN
          (block
            $(send nil? :strong_memoize
              (sym _)
            )
            (args)
            $_
          )
        PATTERN

        def on_block(node)
          send_node, body = strong_memoize?(node)
          return unless send_node

          corrector = autocorrect_pure_definitions(node.parent, body) if node.parent.def_type?

          add_offense(send_node, &corrector)
        end

        private

        def autocorrect_pure_definitions(def_node, body)
          proc do |corrector|
            method_name = def_node.method_name
            replacement = "\n#{indent(def_node)}strong_memoize_attr :#{method_name}"

            corrector.insert_after(def_node, replacement)
            corrector.replace(def_node.body, body.source)
          end
        end
      end
    end
  end
end
