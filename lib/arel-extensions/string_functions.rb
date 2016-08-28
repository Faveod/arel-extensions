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

    #SOUNDEX function returns a character string containing the phonetic representation of char.
    def soundex
      ArelExtensions::Nodes::Soundex.new self
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
      ArelExtensions::Nodes::Replace.new self, left, right
    end

    #Function returns a string after removing left, right or the both prefixes or suffixes int argument
    def trim other
      ArelExtensions::Nodes::Trim.new self,other
    end

    def ltrim other
      ArelExtensions::Nodes::Ltrim.new self,other
    end

    def rtrim other
      ArelExtensions::Nodes::Rtrim.new self, other
    end

  end
end