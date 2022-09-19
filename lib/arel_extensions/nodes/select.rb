module Arel
  module Nodes
    class SelectCore
      # havings did not exist in rails < 5.2
      if !method_defined?(:havings)
        alias :havings :having
      end
    end
  end
end
