module ValidatesWithBlock
  def self.included(mod)
    mod.extend ClassMethods
    super
  end
  
  module ClassMethods
    
    def method_missing(sym, *args)
      if sym.to_s =~ /^validates_(.*)$/ && valid_attribute_name?($1)
        raise "Block required for #{sym}" unless block_given?
        yield FieldValidationRecipient.new( self, $1.to_sym )
      else
        super
      end
    end
    
    def valid_attribute_name?(name)
      column_names.include?(name) || (
        instance_methods.include?("#{name}=") &&
        instance_methods.include?(name)
      )
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