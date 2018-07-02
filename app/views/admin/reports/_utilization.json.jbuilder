json.utilization do
  json.metrics utilization.metrics
  json.availability utilization.total_availability
  json.chart utilization.value do |util_value|
    json.from util_value[:from]
    json.to util_value[:to]
    json.availability util_value[:availability]
  end
end
