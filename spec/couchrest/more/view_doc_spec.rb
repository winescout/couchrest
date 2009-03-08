require File.dirname(__FILE__) + '/../../spec_helper'
require File.join(FIXTURE_PATH, 'more', 'article')
require File.join(FIXTURE_PATH, 'more', 'course')
require File.join(FIXTURE_PATH, 'more', 'student')

# ViewDocuments were born from a need to handle object types that are 
# embedded in other objects, and want to create views of those objects.
# 
# class Child < CouchRest::ViewDocument
#   property :year_born
#   view_by :year_born
# end
#
# class Parent < CouchRest::ExtendedDocument
#   property :children, :cast_as => ["Child"]
# end

describe "ViewDocument views" do
  describe "a model with timestamps" do 
    it 'should set created_at with default of now'
  end
  
  describe "a sub-object with simple views and a default param" do
    before(:all) do
      reset_test_db!
      @course = Course.new
      @student = Student.new(:grade_level => "Freshman")
      @course.students << @student
      @course.save
      Student.by_grade_level
    end

    it "should have a design doc" do
      Student.design_doc.should_not be_nil
    end

    it "should save the design doc" do
      doc = Student.database.get Student.design_doc.id
      doc['views']['by_grade_level'].should_not be_nil
    end

    it "should return the matching raw view result" do
      view = Student.by_grade_level :raw => true
      view['rows'].length.should == 1
    end

    it "should return Student objects when emitted in view" do 
      view = Student.by_grade_level
      view.first["couchrest-type"].should == "Student"
    end
  end
end
