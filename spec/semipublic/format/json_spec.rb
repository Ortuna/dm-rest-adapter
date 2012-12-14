require 'spec_helper'

describe DataMapperRest::Format::Json do
  let(:default_mime) { "application/json" }
  let(:default_extension) { "json" }
  
  it_should_behave_like "a Format"
  
  describe "#string_representation" do
    before(:each) do
      @format = DataMapperRest::Format::Json.new
      @time = DateTime.now
    end
    
    context "with a simple resource" do
      before(:each) do
        @json = '{"id":1,"created_at":"' + @time.to_s + '","title":"Testing","author":"Testy McTesty","comment_crazy_mapping":"Why I write such good books?"}'
      end
      
      it "returns a JSON string representing the resource" do
        book = Book.new(
          :id         => 1,
          :created_at => @time,
          :title      => "Testing",
          :author     => "Testy McTesty",
          :comment    => "Why I write such good books?"
        )
        book_json = @format.string_representation(book)
        book_json.should == @json
      end
    end
    
    context "with a complex resource" do
      before(:each) do
        @json = '{"id":1,"created_at":"' + @time.to_s + '","title":"Testing","author":"Testy McTesty","pid":7,"comment_crazy_mapping":"Open your eyes, dental floss!"}'
      end
      
      it "uses :field mappings" do
        book = DifficultBook.new(
          :id           => 1,
          :created_at   => @time,
          :title        => "Testing",
          :author       => "Testy McTesty",
          :publisher_id => 7,
          :comment      => "Open your eyes, dental floss!"
        )
        book_json = @format.string_representation(book)
        book_json.should == @json
      end
    end
  end
  
  describe "#update_attributes" do
    before(:each) do
      @format = DataMapperRest::Format::Json.new
      @time = DateTime.new
      @json = '{"id":1,"created_at":"' + @time.to_s + '","title":"Testing","author":"Testy McTesty","comment":"No comment dude"}'
    end
    
    it "updates the attributes in the resource based on the response" do
      book = Book.new
      @format.update_attributes(book, @json)
      
      book.id.should == 1
      book.created_at.should == @time
      book.title.should == "Testing"
      book.author.should == "Testy McTesty"
    end
  end
  
  describe "#parse_record" do
    before(:each) do
      @format = DataMapperRest::Format::Json.new
      @time = DateTime.new
      @json = '{"id":1,"created_at":"' + @time.to_s + '","title":"Testing","author":"Testy McTesty","comment_crazy_mapping":"Donuts"}'
    end
    
    it "loads a record from the string representation" do
      record = @format.parse_record(@json, Book)
      record["id"].should == 1
      record["created_at"].should == @time
      record["title"].should == "Testing"
      record["author"].should == "Testy McTesty"
      record["comment_crazy_mapping"].should == "Donuts"
    end
  end
  
  describe "#parse_collection" do
    before(:each) do
      @format = DataMapperRest::Format::Json.new
      @time = DateTime.new
      @json = '[{"id":1,"created_at":"' + @time.to_s + '","title":"Testing","author":"Testy McTesty","comment_crazy_mapping":"Itzy Bitzy Spider"},' +
        '{"id":2,"created_at":"' + @time.to_s + '","title":"Testing 2","author":"Besty McBesty"}]'
    end
    
    it "loads a recordset from the string representation" do
      collection = @format.parse_collection(@json, Book)
      collection.should have(2).entries
      collection[0]["id"].should == 1
      collection[0]["created_at"].should == @time
      collection[0]["title"].should == "Testing"
      collection[0]["author"].should == "Testy McTesty"
      collection[0]["comment_crazy_mapping"].should == "Itzy Bitzy Spider"
      collection[1]["id"].should == 2
      collection[1]["created_at"].should == @time
      collection[1]["title"].should == "Testing 2"
      collection[1]["author"].should == "Besty McBesty"
      collection[1]["comment_crazy_mapping"].should be_nil
    end
  end
end
