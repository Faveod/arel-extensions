module ArelExtensions
  module Nodes
    class Collate < Function
    RETURN_TYPE = :string

    attr_accessor :ai, :ci, :option

    def initialize left, option = nil, ai = false, ci = false
      @ai = ai
      @ci = ci
      @option = option
      tab = [convert_to_node(left)]
      return super(tab)
    end
    end
  end
end
