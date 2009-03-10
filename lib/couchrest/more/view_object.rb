module CouchRest
  module ViewObject
    subklass.send(:include, CouchRest::Mixins::DesignDoc)
    subklass.send(:include, CouchRest::Mixins::Views)
  end
end
