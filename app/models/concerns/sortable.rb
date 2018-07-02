# Allows collection sorting by calling #sort_on
module Sortable
  extend ActiveSupport::Concern
  included do
    def self.sort_on(param, additional_params = {})
      column, direction = param.split(' ')
      return where(nil) if column.blank?
      direction = asc unless %w(desc asc).include?(direction)
      names = columns.map(&:name)
      virtual = @virtual_sorting_columns && @virtual_sorting_columns[column.to_sym]
      if virtual.nil?
        return order("#{table_name}.#{column} #{direction}") if names.include?(column)
        return where(nil)
      end

      virtual = virtual.call(additional_params) if virtual.is_a?(Proc)
      query = self
      if virtual[:select]
        query = query.select("#{table_name}.*, #{virtual[:select]}")
      end
      if virtual[:joins]
        query = query.joins(*virtual[:joins])
      end
      if virtual[:group]
        query = query.group(virtual[:group])
      end

      virtual_order = virtual[:order]
      order = virtual_order.is_a?(Proc) ? virtual_order.call(direction) : "#{virtual_order} #{direction}"
      query = query.order(order)

      # select("holidays.*, count(courts.id) courts_count").joins(:courts).order('courts_count asc')

      query
    end

    def self.virtual_sorting_columns(columns)
      @virtual_sorting_columns = columns
    end
  end
end
