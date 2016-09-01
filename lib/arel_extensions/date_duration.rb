module ArelExtensions
    module DateDuration
      #function returns the year (as a number) given a date value.
      def year
        ArelExtensions::Nodes::Duration.new "y", self
      end

    #function returns the month (as a number) given a date value.
      def month
        ArelExtensions::Nodes::Duration.new "m", self
      end

      #function returns the  week (as a number) given a date value.
      def week
        ArelExtensions::Nodes::Duration.new "w", self
      end

      #function returns the month (as a number) given a date value.
      def day
        ArelExtensions::Nodes::Duration.new "d", self
      end

      def wday
        ArelExtensions::Nodes::Duration.new 'wd', self
      end

    end
end
