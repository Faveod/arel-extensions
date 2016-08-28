require 'arel-extensions/nodes/function'
# Math functions
require 'arel-extensions/nodes/abs'
require 'arel-extensions/nodes/ceil'
require 'arel-extensions/nodes/floor'
require 'arel-extensions/nodes/round'
require 'arel-extensions/nodes/rand'
require 'arel-extensions/nodes/sum'

# String functions
require 'arel-extensions/nodes/concat' if Arel::VERSION.to_i < 7
require 'arel-extensions/nodes/length'
require 'arel-extensions/nodes/locate'
require 'arel-extensions/nodes/matches'
require 'arel-extensions/nodes/find_in_set'
require 'arel-extensions/nodes/replace'
require 'arel-extensions/nodes/soundex'


require 'arel-extensions/nodes/coalesce'
require 'arel-extensions/nodes/date_diff'
require 'arel-extensions/nodes/duration'
require 'arel-extensions/nodes/isnull'
require 'arel-extensions/nodes/trim'
require 'arel-extensions/nodes/ltrim'
require 'arel-extensions/nodes/rtrim'
require 'arel-extensions/nodes/wday'
