require 'arel_extensions/nodes/concat' if Arel::VERSION.to_i < 7
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

    #REPLACE function replaces a sequence of characters in a string with another set of characters, not case-sensitive.
    def replace left, right
      ArelExtensions::Nodes::Replace.new [self, left, right]
    end

    def group_concat sep = nil
      ArelExtensions::Nodes::GroupConcat.new [self, sep]
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

  end
end
