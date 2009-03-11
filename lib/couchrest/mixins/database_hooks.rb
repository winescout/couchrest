module CouchRest
  module Mixins
    module DatabaseHooks
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:class_inheritable_accessor, :database)
        base.send(:attr_accessor, :database)
      end

      module ClassMethods
        def inherited(base)
          base.send(:class_inheritable_accessor, :database)
        end
              
        # override the CouchRest::Model-wide default_database
        # This is not a thread safe operation, do not change the model
        # database at runtime.
        def use_database(db)
          self.database = db
        end        
      end

      # Returns the document's database
      def database
        @database || self.class.database
      end  
      
    end
  end
end
