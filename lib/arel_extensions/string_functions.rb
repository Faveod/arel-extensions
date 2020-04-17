require 'arel_extensions/nodes/concat' #if Arel::VERSION.to_i < 7
require 'arel_extensions/nodes/length'
require 'arel_extensions/nodes/locate'
require 'arel_extensions/nodes/substring'
require 'arel_extensions/nodes/matches'
require 'arel_extensions/nodes/find_in_set'
require 'arel_extensions/nodes/replace'
require 'arel_extensions/nodes/soundex'
require 'arel_extensions/nodes/trim'
require 'arel_extensions/nodes/change_case'
require 'arel_extensions/nodes/blank'
require 'arel_extensions/nodes/format'
require 'arel_extensions/nodes/repeat'
require 'arel_extensions/nodes/cast'
require 'arel_extensions/nodes/collate'
require 'arel_extensions/nodes/levenshtein_distance'
require 'arel_extensions/nodes/md5'


module ArelExtensions
  module StringFunctions

    #*FindInSet function .......
    def &(other)
      ArelExtensions::Nodes::FindInSet.new [other, self]
    end

    #LENGTH function returns the length of the value in a text field.
    def length
      ArelExtensions::Nodes::Length.new [self]
    end

    #LOCATE function returns the first starting position of a string in another string.
    #If string1 or string2 is NULL then it returns NULL. If string1 not found in string2 then it returns 0.
    def locate val
      ArelExtensions::Nodes::Locate.new [self, val]
    end

    def substring start, len = nil
      ArelExtensions::Nodes::Substring.new [self, start, len]
    end

    def [](start, ind = nil)
      start += 1 if start.is_a?(Integer)
      if start.is_a?(Range)
        ArelExtensions::Nodes::Substring.new [self, start.begin + 1, start.end - start.begin + 1]
      elsif start.is_a?(Integer) && !ind
        ArelExtensions::Nodes::Substring.new [self, start, 1]
      else
        ArelExtensions::Nodes::Substring.new [self, start, ind - start + 1]
      end
    end

    #SOUNDEX function returns a character string containing the phonetic representation of char.
    def soundex
      ArelExtensions::Nodes::Soundex.new [self]
    end

    def imatches others, escape = nil
      ArelExtensions::Nodes::IMatches.new self, others, escape
    end

    def imatches_any others, escape = nil
      grouping_any :imatches, others, escape
    end

    def imatches_all others, escape = nil
      grouping_all :imatches, others, escape, escape
    end

    def idoes_not_match others, escape = nil
      ArelExtensions::Nodes::IDoesNotMatch.new self, others, escape
    end

    def idoes_not_match_any others, escape = nil
      grouping_any :idoes_not_match, others, escape
    end

    def idoes_not_match_all others, escape = nil
      grouping_all :idoes_not_match, others, escape
    end

    def ai_matches other # accent insensitive & case sensitive
      ArelExtensions::Nodes::AiMatches.new(self,other)
    end

    def ai_imatches other # accent insensitive & case insensitive
      ArelExtensions::Nodes::AiIMatches.new(self,other)
    end

    def smatches other # accent sensitive & case sensitive
      ArelExtensions::Nodes::SMatches.new(self,other)
    end

    def ai_collate
      ArelExtensions::Nodes::Collate.new(self,nil,true,false)
    end

    def ci_collate
      ArelExtensions::Nodes::Collate.new(self,nil,false,true)
    end

    def collate ai = false,ci = false, option = nil
      ArelExtensions::Nodes::Collate.new(self,option,ai,ci)
    end

    #REPLACE function replaces a sequence of characters in a string with another set of characters, not case-sensitive.
    def replace pattern, substitute
      if pattern.is_a? Regexp
        ArelExtensions::Nodes::RegexpReplace.new self, pattern, substitute
      else
        ArelExtensions::Nodes::Replace.new self, pattern, substitute
      end
    end

    def regexp_replace pattern, substitute
      ArelExtensions::Nodes::RegexpReplace.new self, pattern, substitute
    end

    def concat other
      ArelExtensions::Nodes::Concat.new [self, other]
    end

    #concat elements of a group, separated by sep and ordered by a list of Ascending or Descending
    def group_concat(sep = nil, *orders, group: nil, order: nil)
      if orders.present?
        warn("Warning : ArelExtensions: group_concat: you should now use the kwarg 'order' to specify an order in the group_concat.")
      end
      order_tabs = [orders].flatten.map{ |o|
        if o.is_a?(Arel::Nodes::Ascending) || o.is_a?(Arel::Nodes::Descending)
          o
        elsif o.respond_to?(:asc)
          o.asc
        else
          nil
        end
      }.compact
      ArelExtensions::Nodes::GroupConcat.new(self, sep, group: group, order: (order || order_tabs))
    end

    #Function returns a string after removing left, right or the both prefixes or suffixes int argument
    def trim other = ' '
      ArelExtensions::Nodes::Trim.new [self, other]
    end

    def ltrim other = ' '
      ArelExtensions::Nodes::Ltrim.new [self, other]
    end

    def rtrim other = ' '
      ArelExtensions::Nodes::Rtrim.new [self, other]
    end

    def downcase
      ArelExtensions::Nodes::Downcase.new [self]
    end

    def upcase
      ArelExtensions::Nodes::Upcase.new [self]
    end

    def blank
      ArelExtensions::Nodes::Blank.new [self]
    end

    def not_blank
      ArelExtensions::Nodes::NotBlank.new [self]
    end

    def repeat other = 1
      ArelExtensions::Nodes::Repeat.new [self, other]
    end

    def levenshtein_distance other
      ArelExtensions::Nodes::LevenshteinDistance.new [self, other]
    end

    def edit_distance other
      ArelExtensions::Nodes::LevenshteinDistance.new [self, other]
    end

    def md5
      ArelExtensions::Nodes::MD5.new [self]
    end
  end
end
