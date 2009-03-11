module CouchRest
  module ViewObject
    def self.included(base)
      base.extend(ClassMethods)
      base.send(:include, CouchRest::CastedModel)
      base.send(:include, CouchRest::Mixins::DatabaseHooks)
      base.send(:include, CouchRest::Mixins::DesignDoc)
      base.send(:include, CouchRest::Mixins::Views)
    end

    def initialize(passed_keys={})
      apply_defaults # defined in CouchRest::Mixins::Properties
      super
      cast_keys      # defined in CouchRest::Mixins::Properties
      self['couchrest-type'] = self.class.to_s
    end

    module ClassMethods
      def casted_from(view, opts = {})
        opts[:raw] = true
        self.send("by_#{view}", opts)['rows'].collect do |row|
          klass = Kernel.const_get(row["value"]["couchrest-type"])
          klass.new(row["value"])
        end
      end
    end
  end
end
