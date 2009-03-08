require File.join(FIXTURE_PATH, 'more', 'question')
require File.join(FIXTURE_PATH, 'more', 'person')

class Course < CouchRest::ExtendedDocument
  use_database TEST_SERVER.default_database
  
  property :title
  property :questions,      :cast_as => ['Question']
  property :professor,      :cast_as => 'Person'
  property :final_test_at,  :cast_as => 'Time'
  property :students,       :cast_as => ['Student'], :default => [] #a ViewDocuemnt
  view_by :title
  view_by :dept, :ducktype => true
end
