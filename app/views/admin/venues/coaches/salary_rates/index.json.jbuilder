json.salary_rates @salary_rates do |salary_rate|
  json.partial! 'base', salary_rate: salary_rate
end
