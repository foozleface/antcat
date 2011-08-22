# coding: UTF-8
require 'spec_helper'

describe CitationGrammar do
  it "should return an empty string if the string is empty" do
    ['', nil].each {|string| CitationParser.parse(string).should be_nil}
  end

  it "should handle an author + year" do
    string = 'Fisher, 2010'
    CitationParser.parse(string).should be_true
    string.should be_empty
  end

  it "should stop after the year" do
    string = 'Santschi, 1936 (<b>unavailable name</b>);'
    CitationParser.parse(string).should be_true
    string.should == '(<b>unavailable name</b>);'
  end

  it "should handle multiple authors" do
    string = 'Espadaler & DuMerle, 1989: 121'
    CitationParser.parse(string).should be_true
    string.should be_empty
  end

  it "should handle a missing comma before the year" do
    string = 'Espadaler 1989: 121'
    CitationParser.parse(string).should be_true
    string.should be_empty
  end

  it "should handle a letter at the end of the year" do
    string = 'Espadaler 1989b: 121'
    CitationParser.parse(string).should be_true
    string.should  be_empty
  end
  
  it "should handle a nested citation, and an author with two last names" do
    string = 'De Andrade, in Baroni Urbani & De Andrade, 2007'
    CitationParser.parse(string).should be_true
    string.should be_empty
  end

  it "should handle a page number" do
    string = 'Wheeler, W.M. 1915h: 142; see under *<i>pumilus</i>, above.'
    CitationParser.parse(string).should be_true
    string.should == '; see under *<i>pumilus</i>, above.'
  end

end
