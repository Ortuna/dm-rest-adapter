require 'spec_helper'

shared_examples_for 'a Format' do
  describe "uncustomized" do
    subject { described_class.new }

    its(:mime) { should == default_mime }
    its(:extension) { should == default_extension }

    it "appends the default extension to the resource path" do
      subject.resource_path(:model => Book).should == "livre.#{default_extension}"
    end
  end
  
  context "with a key" do
    subject { described_class.new }
    
    it "appends the key to the path" do
      subject.resource_path(
        :model => Book, :key => 1
      ).should == "livre/1.#{default_extension}"
    end
  end

  describe "custom extension" do
    subject { described_class.new(:extension => "data") }

    its(:extension) { should == "data" }

    it "appends the extension to the resource path" do
      subject.resource_path(:model => Book).should == "livre.data"
    end
  end

  describe "no extension" do
    subject { described_class.new(:extension => nil) }

    its(:extension) { should be_nil }

    it "does not append an extension to the resource path" do
      subject.resource_path(:model => Book).should == "livre"
    end
  end

  describe "empty extension" do
    subject { described_class.new(:extension => "") }

    its(:extension) { should be_nil }

    it "does not append an extension to the resource path" do
      subject.resource_path(:model => Book).should == "livre"
    end
  end
  
  context "with a non-standard storage name" do
    subject { described_class.new }
    
    it "uses the the specified storage name" do
      subject.resource_path(
        :model => DifficultBook
      ).should == "booksies.#{default_extension}"
    end
  end
  
  describe "nested resources" do
    subject { described_class.new }
    
    it "constructs paths to nested resource collections" do
      subject.resource_path(
        { :model => Publisher, :key => 1 },
        { :model => Book }
      ).should == "publishers/1/livre.#{default_extension}"
    end
    
    it "constructs paths to singular nested resources" do
      subject.resource_path(
        { :model => Publisher, :key => 1 },
        { :model => Book, :key => 2 }
      ).should == "publishers/1/livre/2.#{default_extension}"
    end
  end
end
