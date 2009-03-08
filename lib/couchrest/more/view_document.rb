require 'mime/types'
require File.join(File.dirname(__FILE__), "property")
require File.join(File.dirname(__FILE__), '..', 'mixins', 'view_document_mixins')

module CouchRest
  
  # Same as CouchRest::Document but with properties and validations
  class ViewDocument < Document
    include CouchRest::Mixins::DesignDoc
    include CouchRest::Mixins::Views
    
    def self.inherited(subklass)
      subklass.send(:include, CouchRest::Mixins::Properties)
    end
    
    # Accessors
    attr_accessor :casted_by
        
    def initialize(passed_keys={})
      apply_defaults # defined in CouchRest::Mixins::Properties
      super
      cast_keys      # defined in CouchRest::Mixins::Properties
      unless self['_id'] && self['_rev']
        self['couchrest-type'] = self.class.to_s
      end
    end
    
    
    # Automatically set <tt>created_at</tt> field
    # on the document when inserted into parent doc. CouchRest uses a pretty
    # decent time format by default. See Time#to_json
    def self.timestamps!
      class_eval <<-EOS, __FILE__, __LINE__
        property(:updated_at, :read_only => true, :cast_as => 'Time', :auto_validation => false, :default => Proc.new{Time.now})
      EOS
    end
  
    # Name a method that will be called before the document is first saved,
    # which returns a string to be used for the document's <tt>_id</tt>.
    # Because CouchDB enforces a constraint that each id must be unique,
    # this can be used to enforce eg: uniq usernames. Note that this id
    # must be globally unique across all document types which share a
    # database, so if you'd like to scope uniqueness to this class, you
    # should use the class name as part of the unique id.
    def self.unique_id method = nil, &block
      if method
        define_method :set_unique_id do
          self['_id'] ||= self.send(method)
        end
      elsif block
        define_method :set_unique_id do
          uniqid = block.call(self)
          raise ArgumentError, "unique_id block must not return nil" if uniqid.nil?
          self['_id'] ||= uniqid
        end
      end
    end
    
    # Temp solution to make the view_by methods available
    def self.method_missing(m, *args)
      if has_view?(m)
        query = args.shift || {}
        view_m = query.has_key?(:raw) ? "view" : "ducktyped_view"
        return self.send(view_m, m, query, *args)
      else
        super
      end
    end

    def self.ducktyped_view(m, query, *args)
      query.merge!(:raw => true)
      view(m, query, *args)['rows'].collect do |row|
        klass = Kernel.const_get(row["value"]["couchrest-type"])
        klass.new(row["value"])
      end
    end
    ### instance methods
    
    # Returns the Class properties
    #
    # ==== Returns
    # Array:: the list of properties for the instance
    def properties
      self.class.properties
    end
    
    # Takes a hash as argument, and applies the values by using writer methods
    # for each key. It doesn't save the document at the end. 
    # Raises a NoMethodError if the corresponding methods are
    # missing. In case of error, no attributes are changed.    
    def update_attributes(hash)
      hash.each do |k, v|
        raise NoMethodError, "#{k}= method not available, use property :#{k}" unless self.respond_to?("#{k}=")
      end      
      hash.each do |k, v|
        self.send("#{k}=",v)
      end
    end

    # for compatibility with old-school frameworks
    alias :new_record? :new_document?    
  end
end
