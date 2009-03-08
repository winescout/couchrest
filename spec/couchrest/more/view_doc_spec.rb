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
      puts view.inspect
      view.first["couchrest-type"].should == "Student"
    end
  end
=begin
  describe "another model with a simple view" do
    before(:all) do
      reset_test_db!
      %w{aaa bbb ddd eee}.each do |title|
        Course.new(:title => title).save
      end
    end
    it "should make the design doc upon first query" do
      Course.by_title 
      doc = Course.design_doc
      doc['views']['all']['map'].should include('Course')
    end
    it "should can query via view" do
      # register methods with method-missing, for local dispatch. method
      # missing lookup table, no heuristics.
      view = Course.view :by_title
      designed = Course.by_title
      view.should == designed
    end
    it "should get them" do
      rs = Course.by_title 
      rs.length.should == 4
    end
    it "should yield" do
      courses = []
      rs = Course.by_title # remove me
      Course.view(:by_title) do |course|
        courses << course
      end
      courses[0]["doc"]["title"].should =='aaa'
    end
  end


  describe "a ducktype view" do
    before(:all) do
      @id = TEST_SERVER.default_database.save_doc({:dept => true})['id']
    end
    it "should setup" do
      duck = Course.get(@id) # from a different db
      duck["dept"].should == true
    end
    it "should make the design doc" do
      @as = Course.by_dept
      @doc = Course.design_doc
      @doc["views"]["by_dept"]["map"].should_not include("couchrest")
    end
    it "should not look for class" do |variable|
      @as = Course.by_dept
      @as[0]['_id'].should == @id
    end
  end

  describe "a model with a compound key view" do
    before(:all) do
      Article.design_doc_fresh = false
      Article.by_user_id_and_date.each{|a| a.destroy(true)}
      Article.database.bulk_delete
      written_at = Time.now - 24 * 3600 * 7
      @titles = ["uniq one", "even more interesting", "less fun", "not junk"]
      @user_ids = ["quentin", "aaron"]
      @titles.each_with_index do |title,i|
        u = i % 2
        a = Article.new(:title => title, :user_id => @user_ids[u])
        a.date = written_at
        a.save
        written_at += 24 * 3600
      end
    end
    it "should create the design doc" do
      Article.by_user_id_and_date rescue nil
      doc = Article.design_doc
      doc['views']['by_date'].should_not be_nil
    end
    it "should sort correctly" do
      articles = Article.by_user_id_and_date
      articles.collect{|a|a['user_id']}.should == ['aaron', 'aaron', 'quentin', 
        'quentin']
      articles[1].title.should == 'not junk'
    end
    it "should be queryable with couchrest options" do
      articles = Article.by_user_id_and_date :limit => 1, :startkey => 'quentin'
      articles.length.should == 1
      articles[0].title.should == "even more interesting"
    end
  end

  describe "with a custom view" do
    before(:all) do
      @titles = ["very uniq one", "even less interesting", "some fun", 
        "really junk", "crazy bob"]
      @tags = ["cool", "lame"]
      @titles.each_with_index do |title,i|
        u = i % 2
        a = Article.new(:title => title, :tags => [@tags[u]])
        a.save
      end
    end
    it "should be available raw" do
      view = Article.by_tags :raw => true
      view['rows'].length.should == 5
    end

    it "should be default to :reduce => false" do
      ars = Article.by_tags
      ars.first.tags.first.should == 'cool'
    end
  
    it "should be raw when reduce is true" do
      view = Article.by_tags :reduce => true, :group => true
      view['rows'].find{|r|r['key'] == 'cool'}['value'].should == 3
    end
  end

  # TODO: moved to Design, delete
  describe "adding a view" do
    before(:each) do
      reset_test_db!
      Article.by_date
      @design_docs = Article.database.documents :startkey => "_design/", :endkey => "_design/\u9999"
    end
    it "should not create a design doc on view definition" do
      Article.view_by :created_at
      newdocs = Article.database.documents :startkey => "_design/", :endkey => "_design/\u9999"
      newdocs["rows"].length.should == @design_docs["rows"].length
    end
    it "should create a new version of the design document on view access" do
      old_design_doc = Article.database.documents(:key => @design_docs["rows"].first["key"], :include_docs => true)["rows"][0]["doc"]
      Article.view_by :updated_at
      Article.by_updated_at
      newdocs = Article.database.documents({:startkey => "_design/", :endkey => "_design/\u9999"})

      doc = Article.database.documents(:key => @design_docs["rows"].first["key"], :include_docs => true)["rows"][0]["doc"]
      doc["_rev"].should_not        == old_design_doc["_rev"]
      doc["views"].keys.should include("by_updated_at")
    end
  end

  describe "with a lot of designs left around" do
    before(:each) do
      reset_test_db!
      Article.by_date
      Article.view_by :field
      Article.by_field
    end
    it "should clean them up" do
      ddocs = Article.all_design_doc_versions
      Article.view_by :stream
      Article.by_stream
      Article.cleanup_design_docs!
      ddocs = Article.all_design_doc_versions
      ddocs["rows"].length.should == 1
    end
  end
=end
end
