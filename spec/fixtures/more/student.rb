require File.join(FIXTURE_PATH, 'more', 'question')
require File.join(FIXTURE_PATH, 'more', 'person')

class Student < CouchRest::Response
  include CouchRest::ViewObject
  use_database TEST_SERVER.default_database
  
  property :name
  property :grade_level
  view_by  :grade_level, 
           :map => "
             function(doc){
               if(doc['couchrest-type'] == 'Course'){
                 doc.students.forEach(function(student){
                   emit(student['grade_level'], student);
                 });
               }
             }"  
end
