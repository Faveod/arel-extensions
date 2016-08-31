require 'arel_extensions/nodes/function'
# Math functions
require 'arel_extensions/nodes/abs'
require 'arel_extensions/nodes/ceil'
require 'arel_extensions/nodes/floor'
require 'arel_extensions/nodes/round'
require 'arel_extensions/nodes/rand'
require 'arel_extensions/nodes/sum'

# String functions
require 'arel_extensions/nodes/concat' if Arel::VERSION.to_i < 7
require 'arel_extensions/nodes/length'
require 'arel_extensions/nodes/locate'
require 'arel_extensions/nodes/matches'
require 'arel_extensions/nodes/find_in_set'
require 'arel_extensions/nodes/replace'
require 'arel_extensions/nodes/soundex'
require 'arel_extensions/nodes/trim'
require 'arel_extensions/nodes/ltrim'
require 'arel_extensions/nodes/rtrim'

# Date functions 
require 'arel_extensions/nodes/date_diff'
require 'arel_extensions/nodes/duration'

require 'arel_extensions/nodes/coalesce'
require 'arel_extensions/nodes/is_null'
require 'arel_extensions/nodes/wday'