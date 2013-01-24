require 'helper/account'
require 'box/folder'

describe Box::Folder do
  before(:all) do
    @root = get_root
    spec = @root.find(:name => 'rspec', :type => 'folder').first
    spec.delete(true) if spec
  end

  before(:each) do
    @test_root = @root.create_folder('rspec')
    @test_temp = @test_root.create_folder('temp')
    @dummy = @test_root.create_folder('dummy')
  end

  after(:each) do
    @test_root.delete(true)
  end

  it "creates a new folder" do
    @dummy.parent.should == @test_root
    @dummy.name.should == 'dummy'
  end

  it "renames a folder" do
    @dummy.name.should == 'dummy'
    new_dummy = @dummy.update(:name => 'bandito')

    new_dummy.name.should == 'bandito'
  end

  it "moves a folder" do
    new_dummy = @dummy.update(:parent => @test_temp)
    new_dummy.parent.should == @test_temp
  end

  it "deletes a folder" do
    to_delete = @dummy.create_folder('todelete')
    to_delete.delete.should == true
  end

=begin
  context "using fake tree" do
    before(:each) do
      api = double("Api")
      api.stub("get_account_tree") do |*args|
        fake_tree
      end

      @root = Box::Folder.new(api, nil, :id => 0)
    end

    describe "#find" do
      describe "single result" do
        it "finds existing item" do
          file = @root.find(:name => 'expected.1.swf', :recursive => true).first
          file.id.should == '61679540'
          file.name.should == 'expected.1.swf'
        end

        it "finds non-existant file" do
          file = @root.find(:name => 'notfound.png', :recursive => true).first
          file.should be nil
        end

        it "finds specified format" do
          folder = @root.find(:name => 'tests', :type => 'folder', :recursive => true).first
          folder.id.should == '7065552'
          folder.name.should == 'tests'

          file = @root.find(:name => 'tests', :type => 'file', :recursive => true).first
          file.should be nil
        end

        it "finds multiple criteria" do
          file = @root.find(:type => 'file', :id => '61669270', :recursive => true).first
          file.id.should == '61669270'
          file.name.should == 'file.pdf'
        end

        it "obeys recursive flag" do
          file = @root.find(:type => 'file', :sha1 => 'f7379ffe883fdc355fbe47e8a4b3073f21ac0f6d', :recursive => false).first
          file.should == nil
        end

        it "requires both criteria" do
          file = @root.find(:id => 7068024, :name => "notswf", :recursive => true).first
          file.should be nil
        end

        it "finds using regex" do
          folder = @root.find(:name => /T[se]{2}t\w/i, :recursive => true).first
          folder.id.should == '7065552'
          folder.name.should == 'tests'
        end
      end

      describe "multiple results" do
        it "finds multiple files" do
          items = @root.find(:name => 'expected.1.swf', :recursive => true)
          items.should have(2).items
        end

        it "finds all files" do
          files = @root.find(:type => 'file', :recursive => true)
          files.should have(9).items
          files.first.name.should == 'file.pdf'
        end

        it "finds using regex" do
          files = @root.find(:name => /expected.\d+.swf/, :recursive => true)
          files.should have(7).items
        end
      end
    end

# unfortunately, these tests are failing because of a limitation with our fake tree
# the results seem correct, but often miss folder names, and needs to be fixed
    describe "#at" do
      describe "from root" do
        it "gets the root folder" do
          @root.at('').should == @root
          @root.at('/').should == @root
        end

        it "gets a folder" do
          @root.at('tests').path.should == "/tests"
          @root.at('/tests').path.should == "/tests"
          @root.at('/tests/').path.should == "/tests"
          @root.at('/test2').should == nil
        end

        it "gets a nested folder" do
          @root.at('tests/pdf').path.should == "/tests/pdf"
          @root.at('/tests/pdf').path.should == "/tests/pdf"
          @root.at('/tests/pdf/').path.should == "/tests/pdf"
          @root.at('/tests/file.pdf').should == nil
        end

        it "gets a nested file" do
          @root.at('tests/pdf/about stacks/file.pdf').path.should == "/tests/pdf/about stacks/file.pdf"
          @root.at('/tests/pdf/about stacks/file.pdf').path.should == "/tests/pdf/about stacks/file.pdf"
          @root.at('/tests/pdf/about stacks/file.pdf/').should == nil
          @root.at('/tests/pdf/file.pdf').should == nil
        end
      end
      describe "from folder" do
        let(:folder) { @root.at('/tests/pdf/about stacks') }

        it "gets a relative path" do
          folder.at('file.pdf').path.should == "/tests/pdf/about stacks/file.pdf"
          folder.at('./file.pdf').path.should == "/tests/pdf/about stacks/file.pdf"
          folder.at('/file.pdf').should == nil
          folder.at('file.pdf/').should == nil
        end

        it "gets an absolute path" do
          folder.at('/').should == @root
          folder.at('/tests/pdf/about stacks').should == folder
          folder.at('/tests/pdf/about stacks/file.pdf').path.should == "/tests/pdf/about stacks/file.pdf"
        end

        it "gets using parent paths" do
          folder.at('..').path.should == "/tests/pdf"
          folder.at('../about stacks').should == folder
          folder.at('../../../').should == @root
          folder.at('../file.pdf').should == nil
        end
      end
    end
  end
=end
end
