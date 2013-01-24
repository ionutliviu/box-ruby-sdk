require 'helper/account'
require 'box/file'

describe Box::File do
  let(:root) do
    get_root
  end

  let(:test_root) do
    spec = root.find(:name => 'rspec').first
    spec.delete(true) if spec

    root.create_folder('rspec')
  end

  let(:hello_file) do
    'spec/dummy.test'.tap do |file|
      File.open(file, 'w') { |f| f.write("Hello World!") }
    end
  end

  let(:vegetables_file) do
    'spec/veg.test'.tap do |file|
      File.open(file, 'w') { |f| f.write("banana, orange, avachokado") }
    end
  end

  let(:dummy) do
    test_root.upload_file(hello_file)
  end

  describe "#download" do
    it "downloads a file" do
      sleep 1 # wait
      text = dummy.download
      text.should == "Hello World!"
    end
  end

  describe "#upload_version" do
    it "uploads a new file version" do
      dummy.name.should == 'dummy.test'
      file = dummy.upload_version(vegetables_file)

      file.name.should == 'dummy.test'
      file.download.should == 'banana, orange, avachokado'
      file.parent.should == test_root
      file.etag.should_not == dummy.etag
    end
  end

  describe "#update" do
    it "updates file name" do
      new_file = dummy.update(:name => 'new_dummy.test')
      new_file.name.should == 'new_dummy.test'
    end

    it "updates file properties" do
      new_file = dummy.update(:description => "dumb")
      new_file.description.should == "dumb"
    end

    it "updates parent" do
      new_file = dummy.update(:parent => test_root)
      new_file.parent.should == test_root
    end
  end

  describe "#delete" do
    it "deletes the file" do
      dummy.delete.should == true
    end
  end

  describe "#comments" do
    it "gets file comments" do
      comment = dummy.add_comment("Hello World!")
      dummy.comments.should == [ comment ]
    end
  end

  describe "#add_comment" do
    it "adds new comment" do
      comment = dummy.add_comment("Hello world")
      comment.message.should == "Hello world"
    end
  end

  describe "#versions" do

  end

  describe "#version" do
    it "gets file versions" do
      versions = dummy.versions
    end
  end

  describe "#delete_version" do

  end

  describe "#download_version" do

  end

  describe "#info" do
    it "gets file info" do
      dummy.name.should == 'dummy.test'
      dummy.size.should_not == nil
    end

    it "sets the parent folder" do
      dummy.parent.should == test_root
      test_root.parent.should == root
    end

    it "lazy-loads file info" do
      file = Box::File.new( get_api, :file_id => dummy.id )
      file.data[:etag].should == nil
      file.etag.should_not == nil
      file.data[:etag].should_not == nil
    end
  end
end
