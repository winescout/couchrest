require File.dirname(__FILE__) + '/../../spec_helper'
require File.join(FIXTURE_PATH, 'more', 'article')
require File.join(FIXTURE_PATH, 'more', 'course')
require File.join(FIXTURE_PATH, 'more', 'student')

# Mixing in ViewObject allows a class to create views,
# and have the view cast returned objects
#
# class Parent < CouchRest::ExtendedDocument
#   property :children, :cast_as => ["Child"]
# end
# 
# class Child < CouchRest::Response
#   include CouchRest::ViewObject
#   property :year_born
#   view_by :year_born
#           :map => "
#             function(){
#               if (doc['couchrest-type'] == 'Parent' && doc.tags) {
#                 doc.child.forEach(function(child){
#                   emit(null, child);
#             }}}"
# end
#
# Child.casted_from :year_born => [child_1, child_2, ...]

describe "ViewDocument views" do
  describe "a sub-object with simple views and a default param" do
    before(:all) do
      reset_test_db!
      @course = Course.new
      @student = Student.new(:grade_level => "Freshman")
      @course.students << @student
      @course.save
      Student.casted_from :grade_level
    end

    it "should have a design doc" do
      Student.design_doc.should_not be_nil
    end

    it "should save the design doc" do
      doc = Student.database.get Student.design_doc.id
      doc['views']['by_grade_level'].should_not be_nil
    end

    it "should return Student objects when emitted in view" do 
      view = Student.casted_from :grade_level
      view.first["couchrest-type"].should == "Student"
    end
  end
end
