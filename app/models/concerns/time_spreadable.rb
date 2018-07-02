# Adds overlapping query for models with start-end time columns
module TimeSpreadable
  extend ActiveSupport::Concern
  included do
    def self.overlapping(from, to)
      start_column = @time_spreadable_start_column || 'start_time'
      end_column = @time_spreadable_end_column || 'end_time'

      # dates should overlap if two pieces have the same date
      # for example `01.01 - 31.01` will overlap `31.01 - 30.02`
      # for times we ignore an overlapping second like this
      strict = @time_spreadable_as_dates ? '=' : ''

      where(
        <<-SQL,
          #{start_column} >= :from AND #{start_column} <#{strict} :to OR
            #{end_column} >#{strict} :from AND #{end_column} <= :to OR
            #{start_column} <= :from AND #{end_column} >= :to
        SQL
        from: from, to: to
      )
    end

    def self.time_spreadable_columns(start_column, end_column, as_dates: false)
      @time_spreadable_start_column = start_column
      @time_spreadable_end_column = end_column
      @time_spreadable_as_dates = as_dates
    end
  end
end
