require 'env_parser/version'
require 'active_support/all'

## The EnvParser class simplifies parsing of environment variables as different data types.
##
class EnvParser
  class << self
    ## Interprets the given value as the specified type.
    ##
    ## @param value [String, Symbol]
    ##   The value to parse/interpret. If a String is given, the value will be used as-is. If a
    ##   Symbol is given, the ENV value for the matching string key will be used.
    ##
    ## @option options as [Symbol]
    ##   The expected return type. A best-effort attempt is made to convert the source String to the
    ##   requested type. Valid "as" types are:
    ##
    ##   - `:string`
    ##   - `:symbol`
    ##   - `:boolean`
    ##   - `:int` / `:integer`
    ##   - `:float` / `:decimal` / `:number`
    ##   - `:json`
    ##   - `:array`
    ##   - `:hash`
    ##
    ## @option options if_unset
    ##   Specifies the default value to return if the given "value" is either nil or an empty String
    ##   (''). Any "if_unset" value given will be returned as-is, with no type conversion or other
    ##   change having been made.  If unspecified, the "default" value for nil/'' input will depend
    ##   on the "as" type.
    ##
    def parse(value, options = {})
      value = if value.is_a? Symbol
                ENV[value.to_s]
              else
                value.to_s
              end

      return options[:if_unset] if value.blank? && options.key?(:if_unset)

      case options[:as].to_sym
      when :string then parse_string(value)
      when :symbol then parse_symbol(value)
      when :boolean then parse_boolean(value)
      when :int, :integer then parse_integer(value)
      when :float, :decimal, :number then parse_float(value)
      when :json then parse_json(value)
      when :array then parse_array(value)
      when :hash then parse_hash(value)
      else raise ArgumentError, "invalid `as` parameter: #{options[:as].inspect}"
      end
    end

    private

    def parse_string(value)
      value
    end

    def parse_symbol(value)
      value.to_sym
    end

    def parse_boolean(value)
      case value
      when '', '0', 'f', 'false' then false
      else true
      end
    end

    def parse_integer(value)
      value.to_i
    end

    def parse_float(value)
      value.to_f
    end

    def parse_json(value)
      require 'json'

      return nil if value.blank?

      decoded_json = JSON.parse(value, quirks_mode: true)
      { decoded_json: decoded_json }.with_indifferent_access[:decoded_json]
    end

    def parse_array(value)
      return [] if value.blank?

      decoded_json = parse_json(value)
      raise(ArgumentError, 'non-array value') unless decoded_json.is_a? Array

      decoded_json
    end

    def parse_hash(value)
      return {} if value.blank?

      decoded_json = parse_json(value)
      raise(ArgumentError, 'non-hash value') unless decoded_json.is_a? Hash

      decoded_json
    end
  end
end