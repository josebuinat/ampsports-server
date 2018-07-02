class MathExtras
  # subtract array of integer ranges from array of integer ranges
  # ranges can be arrays [start, end]
  def self.subtract_ranges(given_ranges, subtracted_ranges)
    subtracted_ranges.each do |subtracted|
      eliminated_ranges = []
      lesser_ranges = []

      given_ranges.each do |given|
        if subtracted.first <= given.last && subtracted.last >= given.first
          eliminated_ranges << given

          if subtracted.first <= given.first && subtracted.last >= given.last
            # fully eliminated range
            next
          elsif subtracted.first <= given.first && subtracted.last <= given.last
            # cut beginning of range
            lesser_ranges << (subtracted.last.next..given.last)
          elsif subtracted.first >= given.first && subtracted.last >= given.last
            # cut ending of range
            lesser_ranges << (given.first..subtracted.first.pred)
          elsif subtracted.first >= given.first && subtracted.last <= given.last
            # cut middle of range
            lesser_ranges << (given.first..subtracted.first.pred)
            lesser_ranges << (subtracted.last.next..given.last)
          end
        end
      end

      given_ranges = given_ranges - eliminated_ranges + lesser_ranges

      break if given_ranges.length == 0
    end

    given_ranges
  end

  # takes an array of numbers and returns numbers which had enough consecutive numbers following them
  def self.start_with_consecutive(array_of_numbers, number_of_consecutive)
    return array_of_numbers if number_of_consecutive <= 1
    return [] if array_of_numbers.size < number_of_consecutive

    array_of_numbers = array_of_numbers.sort
    result = []

    (array_of_numbers.first..array_of_numbers.last).each do |number|
      next unless array_of_numbers.index(number)

      starting_index = array_of_numbers.index(number)
      ending_index = starting_index + number_of_consecutive - 1

      break unless array_of_numbers[ending_index]

      if array_of_numbers[ending_index] - array_of_numbers[starting_index] ==
          number_of_consecutive - 1
        result << number
      end
    end

    result
  end

  # rounds the input number to nearest .5 decimal
  def self.round_to_half_decimal(num)
      (num * 2).round / 2.0
  end
end
