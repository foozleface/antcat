require 'spec_helper'

describe Name do

  it "should have a name" do
    Name.new(name:'Name').name.should == 'Name'
  end

  describe "Making an epithet search set" do

    it "should put the request term first" do
      Name.make_epithet_set('magus').should == ['magus', 'maga']
      Name.make_epithet_set('maga').should == ['maga', 'magus']
    end

    def should_be_same_epithet *epithets
      epithets.each do |epithet|
        Name.make_epithet_set(epithet).should =~ epithets
      end
    end

    describe "Masculine-feminine" do
      it "should convert between these" do
        should_be_same_epithet 'magus', 'maga'
        should_be_same_epithet 'diabolicus', 'diabolica'
        should_be_same_epithet 'equus', 'equa'
        should_be_same_epithet 'aneus', 'anea'
      end
    end

    it "should convert names deemed identical" do
      should_be_same_epithet 'lundi', 'lundii'
    end

  end

end
