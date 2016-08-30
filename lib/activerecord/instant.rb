require "activerecord/instant/version"
require "active_record"

module Activerecord
  class Instant
    class TemporaryTableNotExist < StandardError; end

    def initialize(basename, baseclass: ActiveRecord::Base, extensions: [])
      @basename = basename
      @baseclass = baseclass
      @extensions = extensions
      @conn = @baseclass.connection
    end

    def table_name(temporary: false)
      temporary ? "temporary_#{@basename}" : @basename
    end

    def table_exists?(temporary: false)
      @conn.data_source_exists?(table_name(temporary: temporary))
    end

    def stale_table_name
      "stale_#{table_name}"
    end

    def create_table!(temporary: false, force: false)
      @conn.create_table(table_name(temporary: temporary), force: force) do |t|
        yield(t) if block_given?
      end
    end

    def model(temporary: false)
      table_name = table_name(temporary: temporary)
      model_name = table_name.classify
      if Object.const_defined?(model_name)
        Object.const_get(model_name).tap(&:reset_column_information)
      else
        klass = Class.new(@baseclass) { |c| c.table_name = table_name }
        klass.send(:include, *@extensions) if @extensions.present?
        Object.const_set(model_name, klass)
      end
    end

    def promote_temporary_table!
      fail TemporaryTableNotExist unless table_exists?(temporary: true)

      @baseclass.transaction do
        execute "DROP TABLE IF EXISTS #{@conn.quote_table_name stale_table_name}"
        execute "ALTER TABLE #{model.quoted_table_name} RENAME TO #{@conn.quote_table_name stale_table_name}" if table_exists?
        execute "ALTER TABLE #{model(temporary: true).quoted_table_name} RENAME TO #{model.quoted_table_name}"
      end
    end

    def drop_tables!
      @baseclass.transaction do
        execute "DROP TABLE IF EXISTS #{@conn.quote_table_name table_name(temporary: true)}"
        execute "DROP TABLE IF EXISTS #{@conn.quote_table_name table_name}"
        execute "DROP TABLE IF EXISTS #{@conn.quote_table_name stale_table_name}"
      end
    end

    private

    def execute(sql)
      @conn.execute(sql)
    end
  end
end
