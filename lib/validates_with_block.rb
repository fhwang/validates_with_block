module ValidatesWithBlock
  def self.included( including_class )
    including_class.class_eval do
      class << self
        alias_method :method_missing_aliased_from_vwb, :method_missing
      end
    end
    
    def including_class.method_missing( sym, *args )
      begin
        method_missing_aliased_from_vwb( sym, *args )
      rescue NoMethodError => e
        if sym.to_s =~ /^validates_(.*)$/ and block_given?
          maybe_attr_name = $1
          setter_names = (
            instance_methods - ActiveRecord::Base.instance_methods
          ).select { |meth| meth =~ /=$/ }
          if column_names.include?( maybe_attr_name ) or
             ( setter_names.include?( maybe_attr_name + '=' ) and
               instance_methods.include?( maybe_attr_name ) )
            yield FieldValidationRecipient.new( self, maybe_attr_name.to_sym )
            return
          end
        end
        raise e
      end
    end
  end
  
  class FieldValidationRecipient
    def initialize( klass, field )
      @klass, @field = klass, field
    end
    
    def method_missing( sym, *args )
      validate_meth = case sym
        when :confirmed;          :validates_confirmation_of
        when :formatted;          :validates_format_of
        when :formatted_as_email; :validates_email_format_of
        when :length;             :validates_length_of
        when :present;            :validates_presence_of
        when :unique;             :validates_uniqueness_of
      end
      if validate_meth
        args.unshift @field
        @klass.send( validate_meth, *args )
      else
        super
      end
    end
  end
end

class ActiveRecord::Base
  include ValidatesWithBlock
end