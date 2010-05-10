require 'spec_helper'

class SelfObserver
  def self.cache
    @cache ||= []
  end

  def initialize
    self.class.cache << self
  end
end

module Rspec::Core

  describe ExampleGroup do

    describe "top level group" do
      it "runs its children" do
        examples_run = []
        parent = ExampleGroup.describe("parent")
        child = parent.describe("child") do
          it "does something" do
            examples_run << running_example
          end
        end

        child.filtered_examples.replace(child.examples)
        parent.run_all
        examples_run.should have(1).example
      end

      describe "descendents" do
        it "returns self + all descendents" do
          group = ExampleGroup.describe("parent") do
            describe("child") do
              describe("grandchild 1") {}
              describe("grandchild 2") {}
            end
          end
          group.descendents.size.should == 4
        end
      end
    end

    describe "child" do
      it "is known by parent" do
        parent = ExampleGroup.describe
        child = parent.describe
        parent.children.should == [child]
      end

      it "is not registered in world" do
        parent = ExampleGroup.describe
        child = parent.describe
        Rspec.world.example_groups.should == [parent]
      end
    end

    describe "filtering" do
      it "includes all examples in an explicitly included group" do
        Rspec.world.stub(:inclusion_filter).and_return({ :awesome => true })
        group = ExampleGroup.describe("does something", :awesome => true)
        examples = [
          group.example("first"),
          group.example("second")
        ]
        group.filtered_examples.should == examples
      end

      it "includes explicitly included examples" do
        Rspec.world.stub(:inclusion_filter).and_return({ :awesome => true })
        group = ExampleGroup.describe
        example = group.example("does something", :awesome => true)
        group.example("don't run me")
        group.filtered_examples.should == [example]
      end

      it "excludes all examples in an excluded group" do
        Rspec.world.stub(:exclusion_filter).and_return({ :awesome => false })
        group = ExampleGroup.describe("does something", :awesome => false)
        examples = [
          group.example("first"),
          group.example("second")
        ]
        group.filtered_examples.should == []
      end

      it "filters out excluded examples" do
        Rspec.world.stub(:exclusion_filter).and_return({ :awesome => false })
        group = ExampleGroup.describe("does something")
        examples = [
          group.example("first", :awesome => false),
          group.example("second")
        ]
        group.filtered_examples.should == [examples[1]]
      end

      context "with no filters" do
        it "returns all" do
          group = ExampleGroup.describe
          example = group.example("does something")
          group.filtered_examples.should == [example]
        end
      end

      context "with no examples or groups that match filters" do
        it "returns none" do
          Rspec.world.stub(:inclusion_filter).and_return({ :awesome => false })
          group = ExampleGroup.describe
          example = group.example("does something")
          group.filtered_examples.should == []
        end
      end
    end

    describe '#describes' do

      context "with a constant as the first parameter" do
        it "is that constant" do
          ExampleGroup.describe(Object) { }.describes.should == Object
        end
      end

      context "with a string as the first parameter" do
        it "is nil" do
          ExampleGroup.describe("i'm a computer") { }.describes.should be_nil
        end
      end

    end

    describe '#description' do

      it "grabs the description from the metadata" do
        group = ExampleGroup.describe(Object, "my desc") { }
        group.description.should == group.metadata[:example_group][:description]
      end

    end

    describe '#metadata' do

      it "adds the third parameter to the metadata" do
        ExampleGroup.describe(Object, nil, 'foo' => 'bar') { }.metadata.should include({ "foo" => 'bar' })
      end

      it "adds the caller to metadata" do
        ExampleGroup.describe(Object) { }.metadata[:example_group][:caller].any? {|f|
          f =~ /#{__FILE__}/
        }.should be_true
      end

      it "adds the the file_path to metadata" do
        ExampleGroup.describe(Object) { }.metadata[:example_group][:file_path].should == __FILE__
      end

      it "has a reader for file_path" do
        ExampleGroup.describe(Object) { }.file_path.should == __FILE__
      end

      it "adds the line_number to metadata" do
        ExampleGroup.describe(Object) { }.metadata[:example_group][:line_number].should == __LINE__
      end

    end

    describe "before, after, and around hooks" do

      it "runs the before alls in order" do
        group = ExampleGroup.describe
        order = []
        group.before(:all) { order << 1 }
        group.before(:all) { order << 2 }
        group.before(:all) { order << 3 }
        group.example("example") {}

        group.run_all

        order.should == [1,2,3]
      end

      it "runs the before eachs in order" do
        group = ExampleGroup.describe
        order = []
        group.before(:each) { order << 1 }
        group.before(:each) { order << 2 }
        group.before(:each) { order << 3 }
        group.example("example") {}

        group.run_all

        order.should == [1,2,3]
      end

      it "runs the after eachs in reverse order" do
        group = ExampleGroup.describe
        order = []
        group.after(:each) { order << 1 }
        group.after(:each) { order << 2 }
        group.after(:each) { order << 3 }
        group.example("example") {}

        group.run_all

        order.should == [3,2,1]
      end

      it "runs the after alls in reverse order" do
        group = ExampleGroup.describe
        order = []
        group.after(:all) { order << 1 }
        group.after(:all) { order << 2 }
        group.after(:all) { order << 3 }
        group.example("example") {}

        group.run_all

        order.should == [3,2,1]
      end

      it "runs before all, before each, example, after each, after all, in that order" do
        group = ExampleGroup.describe
        order = []
        group.after(:all)   { order << :after_all   }
        group.after(:each)  { order << :after_each  }
        group.before(:each) { order << :before_each }
        group.before(:all)  { order << :before_all  }
        group.example("example") { order << :example }

        group.run_all

        order.should == [
          :before_all,
          :before_each,
          :example,
          :after_each,
          :after_all
        ]
      end

      it "exposes the around each blocks at after_alls" do
        group = ExampleGroup.describe
        group.around(:each) { 'foo' }
        group.should have(1).around_eachs
      end
      
    end

    describe "adding examples" do

      it "allows adding an example using 'it'" do
        group = ExampleGroup.describe
        group.it("should do something") { }
        group.examples.size.should == 1
      end

      it "exposes all examples at examples" do
        group = ExampleGroup.describe
        group.it("should do something 1") { }
        group.it("should do something 2") { }
        group.it("should do something 3") { }
        group.should have(3).examples
      end

      it "maintains the example order" do
        group = ExampleGroup.describe
        group.it("should 1") { }
        group.it("should 2") { }
        group.it("should 3") { }
        group.examples[0].description.should == 'should 1'
        group.examples[1].description.should == 'should 2'
        group.examples[2].description.should == 'should 3'
      end

    end

    describe Object, "describing nested example_groups", :little_less_nested => 'yep' do 

      describe "A sample nested group", :nested_describe => "yep" do
        it "sets the described class to the constant Object" do
          running_example.example_group.describes.should == Object
        end

        it "sets the description to 'A sample nested describe'" do
          running_example.example_group.description.should == 'A sample nested group'
        end

        it "has top level metadata from the example_group and its ancestors" do
          running_example.example_group.metadata.should include(:little_less_nested => 'yep', :nested_describe => 'yep')
        end

        it "exposes the parent metadata to the contained examples" do
          running_example.metadata.should include(:little_less_nested => 'yep', :nested_describe => 'yep')
        end
      end

    end

    describe "#run_examples" do

      let(:reporter) { double("reporter").as_null_object }

      it "returns true if all examples pass" do
        group = ExampleGroup.describe('group') do
          example('ex 1') { 1.should == 1 }
          example('ex 2') { 1.should == 1 }
        end
        group.stub(:filtered_examples) { group.examples }
        group.run(reporter).should be_true
      end

      it "returns false if any of the examples fail" do
        group = ExampleGroup.describe('group') do
          example('ex 1') { 1.should == 1 }
          example('ex 2') { 1.should == 2 }
        end
        group.stub(:filtered_examples) { group.examples }
        group.run(reporter).should be_false
      end

      it "runs all examples, regardless of any of them failing" do
        group = ExampleGroup.describe('group') do
          example('ex 1') { 1.should == 2 }
          example('ex 2') { 1.should == 1 }
        end
        group.stub(:filtered_examples) { group.examples }
        group.filtered_examples.each do |example|
          example.should_receive(:run)
        end
        group.run(reporter).should be_false
      end
    end

    describe "how instance variables are inherited" do
      before(:all) do
        @before_all_top_level = 'before_all_top_level'
      end

      before(:each) do
        @before_each_top_level = 'before_each_top_level'
      end

      it "should be able to access a before each ivar at the same level" do
        @before_each_top_level.should == 'before_each_top_level'
      end

      it "should be able to access a before all ivar at the same level" do
        @before_all_top_level.should == 'before_all_top_level'
      end

      it "should be able to access the before all ivars in the before_all_ivars hash", :ruby => 1.8 do
        running_example.example_group.before_all_ivars.should include('@before_all_top_level' => 'before_all_top_level')
      end

      it "should be able to access the before all ivars in the before_all_ivars hash", :ruby => 1.9 do
        running_example.example_group.before_all_ivars.should include(:@before_all_top_level => 'before_all_top_level')
      end

      describe "but now I am nested" do
        it "should be able to access a parent example groups before each ivar at a nested level" do
          @before_each_top_level.should == 'before_each_top_level'
        end

        it "should be able to access a parent example groups before all ivar at a nested level" do
          @before_all_top_level.should == "before_all_top_level"
        end

        it "changes to before all ivars from within an example do not persist outside the current describe" do
          @before_all_top_level = "ive been changed"
        end

        describe "accessing a before_all ivar that was changed in a parent example_group" do
          it "does not have access to the modified version" do
            @before_all_top_level.should == 'before_all_top_level'
          end
        end
      end

    end

    describe "ivars are not shared across examples" do
      it "(first example)" do
        @a = 1
        @b.should be_nil
      end

      it "(second example)" do
        @b = 2
        @a.should be_nil
      end
    end

    describe "#around" do

      around(:each) do |example|
        SelfObserver.new
        example.run
        SelfObserver.cache.clear
      end

      it "has 1 SelfObserver (1)" do
        SelfObserver.cache.length.should == 1
      end

      it "has 1 SelfObserver (2)" do
        SelfObserver.cache.length.should == 1
      end
    end

    describe "top_level_description" do
      it "returns the description from the outermost example group" do
        group = nil
        ExampleGroup.describe("top") do
          context "middle" do
            group = describe "bottom" do
            end
          end
        end

        group.top_level_description.should == "top"
      end
    end

  end
end
