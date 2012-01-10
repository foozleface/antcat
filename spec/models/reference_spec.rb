# coding: UTF-8
require 'spec_helper'

describe Reference do
  before :each do
    @author_names = [Factory(:author_name)]
  end

  describe "Relationships" do
    it "has many author_names" do
      reference = Reference.create! :author_names => @author_names, :title => 'asdf', :citation_year => '2010d'
      reference.author_names.first.should == @author_names.first
    end
    it "has many authors" do
      reference = Reference.create! :author_names => @author_names, :title => 'asdf', :citation_year => '2010d'
      reference.authors.first.should == @author_names.first.author
    end
  end

  describe "author_names_string" do

    describe "parsing" do
      before do
        @reference = Factory :reference
      end
      it "should return nothing if empty" do
        @reference.parse_author_names_and_suffix('') .should == {:author_names => [], :author_names_suffix => nil}
      end
      it "should add an error and raise and exception if invalid" do
        lambda {@reference.parse_author_names_and_suffix('...asdf sdf dsfdsf')}.should raise_error ActiveRecord::RecordInvalid
        @reference.errors.messages.should == {:author_names_string => ["couldn't be parsed. Please post a message on http://groups.google.com/group/antcat/, and we'll fix it!"]}
        @reference.author_names_string.should == '...asdf sdf dsfdsf'
      end
      it "should return the author names and the suffix" do
        @reference.parse_author_names_and_suffix('Fisher, B.; Bolton, B. (eds.)').should == {:author_names => [AuthorName.find_by_name('Fisher, B.'), AuthorName.find_by_name('Bolton, B.')], :author_names_suffix => ' (eds.)'}
      end
    end

    describe "formatting" do
      it "should consist of one author_name if that's all there is" do
        reference = Factory(:reference, :author_names => [Factory(:author_name, :name => 'Fisher, B.L.')])
        reference.author_names_string.should == 'Fisher, B.L.'
      end
      it "should separate multiple author_names with semicolons" do
        author_names = [Factory(:author_name, :name => 'Fisher, B.L.'), Factory(:author_name, :name => 'Ward, P.S.')]
        reference = Factory(:reference, :author_names => author_names)
        reference.author_names_string.should == 'Fisher, B.L.; Ward, P.S.'
      end
      it "should include the author_names' suffix" do
        author_names = [Factory(:author_name, :name => 'Fisher, B.L.'), Factory(:author_name, :name => 'Ward, P.S.')]
        reference = Reference.create! :title => 'Ants', :citation_year => '2010', :author_names => author_names, :author_names_suffix => ' (eds.)'
        reference.reload.author_names_string.should == 'Fisher, B.L.; Ward, P.S. (eds.)'
      end
      it "should be possible to read from and assign to, aliased to author_names_string_cache" do
        reference = Factory :reference
        reference.author_names_string = 'foo'
        reference.author_names_string.should == 'foo'
      end
    end

    describe "updating, when things change" do
      before do
        @reference = Factory(:reference, :author_names => [Factory(:author_name, :name => 'Fisher, B.L.')])
      end
      it "should update its author_names_string when an author_name is added" do
        @reference.author_names << Factory(:author_name, :name => 'Ward')
        @reference.author_names_string.should == 'Fisher, B.L.; Ward'
      end
      it "should update its author_names_string when an author_name is removed" do
        author_name = Factory(:author_name, :name => 'Ward')
        @reference.author_names << author_name
        @reference.author_names_string.should == 'Fisher, B.L.; Ward'
        @reference.author_names.delete author_name
        @reference.author_names_string.should == 'Fisher, B.L.'
      end
      it "should update its author_names_string when an author_name's name is changed" do
        author_name = Factory(:author_name, :name => 'Ward')
        @reference.author_names = [author_name]
        @reference.author_names_string.should == 'Ward'
        author_name.update_attribute :name, 'Fisher'
        @reference.reload.author_names_string.should == 'Fisher'
      end
      it "should update its author_names_string when the author_names_suffix changes" do
        @reference.author_names_suffix = ' (eds.)'
        @reference.save
        @reference.reload.author_names_string.should == 'Fisher, B.L. (eds.)'
      end
    end

    describe "maintaining its order" do
      it "should show the author_names in the order in which they were added to the reference" do
        reference = Factory(:reference, :author_names => [Factory(:author_name, :name => 'Ward')])
        wilden = Factory :author_name, :name => 'Wilden'
        fisher = Factory :author_name, :name => 'Fisher'
        reference.author_names << wilden
        reference.author_names << fisher
        reference.author_names_string.should == 'Ward; Wilden; Fisher'
      end
    end

  end

  describe "principal author last name" do
    before do
      @ward = Factory :author_name, :name => 'Ward, P.'
      @fisher = Factory :author_name, :name => 'Fisher, B.'
    end
    it "should not freak out if there are no authors" do
      reference = Reference.create! :title => 'title', :citation_year => '1993'
      reference.principal_author_last_name.should be_nil
    end
    it "should cache the last name of the principal author" do
      reference = Factory :reference, :author_names => [@ward, @fisher]
      reference.principal_author_last_name.should == 'Ward'
    end
    it "should update its author_names_string when an author_name's name is changed" do
      reference = Factory :reference, :author_names => [@ward]
      @ward.update_attributes :name => 'Bolton, B.'
      reference.reload.principal_author_last_name.should == 'Bolton'
    end
    it "should be possible to read from, aliased to principal_author_last_name_cache" do
      reference = Factory :reference
      reference.principal_author_last_name_cache = 'foo'
      reference.principal_author_last_name.should == 'foo'
    end
  end

  describe "validations" do
    before do
      author_name = Factory :author_name
      @reference = Reference.new :author_names => [author_name], :title => 'title', :citation_year => '1910'
    end

    it "should be OK when all fields are present" do
      @reference.should be_valid
    end

    it "should not be OK when the title is missing" do
      @reference.title = nil
      @reference.should_not be_valid
    end

    it "should not be OK when the citation year is missing" do
      @reference.citation_year = nil
      @reference.should_not be_valid
    end

    it "should not be OK when the citation year is blank" do
      @reference.citation_year = ''
      @reference.should_not be_valid
    end

  end

  describe "changing the citation year" do
    it "should change the year" do
      reference = Factory(:reference, :citation_year => '1910a')
      reference.year.should == 1910
      reference.citation_year = '2010b'
      reference.save!
      reference.year.should == 2010
    end

    it "should set the year to the stated year, if present" do
      reference = Factory(:reference, :citation_year => '1910a ["1958"]')
      reference.year.should == 1958
      reference.citation_year = '2010b'
      reference.save!
      reference.year.should == 2010
    end
  end

  describe "entering a newline in the title, public_notes, editor_notes or taxonomic_notes" do
    it "should strip the newline" do
      reference = Factory :reference
      reference.title = 'A\nB'
      reference.public_notes = "A\nB"
      reference.editor_notes = "A\nB"
      reference.taxonomic_notes = "A\nB"
      reference.save!
      reference.public_notes.should == "A B"
      reference.editor_notes.should == "A B"
      reference.taxonomic_notes.should == "A B"
    end
  end

  describe "long fields" do
    it "should not truncate long fields" do
      Reference.create! :author_names => @author_names, :editor_notes => 'e' * 1000, :citation => 'c' * 2000,
        :public_notes => 'n' * 1500, :taxonomic_notes => 't' * 1700, :title => 't' * 1900, :citation_year => '2010'
      reference = Reference.first
      reference.citation.length.should == 2000
      reference.editor_notes.length.should == 1000
      reference.public_notes.length.should == 1500
      reference.taxonomic_notes.length.should == 1700
      reference.title.length.should == 1900
    end
  end

  describe "ordering by author_name" do
    it "should order by author_name" do
      bolton = Factory :author_name, :name => 'Bolton'
      ward = Factory :author_name, :name => 'Ward'
      fisher = Factory :author_name, :name => 'Fisher'
      bolton_reference = Factory :article_reference, :author_names => [bolton, ward]
      first_ward_reference = Factory :article_reference, :author_names => [ward, bolton]
      second_ward_reference = Factory :article_reference, :author_names => [ward, fisher]
      fisher_reference = Factory :article_reference, :author_names => [fisher, bolton]

      Reference.sorted_by_principal_author_last_name.map(&:id).should == [bolton_reference.id, fisher_reference.id, first_ward_reference.id, second_ward_reference.id]
    end
  end

  describe "versioning" do
    it "should work" do
      reference = UnknownReference.create! :title => 'title', :citation_year => '2010', :citation => 'citation'
      reference.versions.last.event.should == 'create'

      reference.update_attribute :title, 'new title'
      version = reference.versions.last
      version.event.should == 'update'

      reference = version.reify
      reference.save!
      reference.reload.title.should == 'title' 
    end
  end

  describe "document" do
    it "has a document" do
      reference = Factory :reference
      reference.document.should be_nil
      reference.create_document
      reference.document.should_not be_nil
    end
  end

  describe "downloadable_by?" do
    it "should be false if there is no document" do
      Factory(:reference).should_not be_downloadable_by Factory :user
    end

    it "should delegate to its document" do
      reference = Factory :reference, :document => Factory(:reference_document)
      user = Factory :user
      reference.document.should_receive(:downloadable_by?).with(user)
      reference.downloadable_by? user
    end
  end

  describe "url" do
    it "should be nil if there is no document" do
      Factory(:reference).url.should be_nil
    end
    it "should delegate to its document" do
      reference = Factory :reference, :document => Factory(:reference_document)
      reference.document.should_receive(:url)
      reference.url
    end

    it "should make sure it exists" do
      reference = Factory :reference, :year => 2001
      stub_request(:any, "http://antbase.org/1.pdf").to_return :body => "Not Found", :status => 404
      lambda {reference.document = ReferenceDocument.create :url => 'http://antbase.org/1.pdf'}.should raise_error ActiveRecord::RecordNotSaved
    end

  end

  describe "setting the document host" do
    it "should not crash if there is no document" do
      Factory(:reference).document_host = 'localhost'
    end
    it "should delegate to its document" do
      reference = Factory :reference, :document => Factory(:reference_document)
      reference.document.should_receive(:host=)
      reference.document_host = 'localhost'
    end
  end

  describe 'with principal author last name' do
    it 'should return references with a matching principal author last name' do
      not_possible_reference = Factory :book_reference, :author_names => [Factory(:author_name, :name => 'Bolton, B.')]
      possible_reference = Factory :article_reference, :author_names => [Factory(:author_name, :name => 'Ward, P. S.'), Factory(:author_name, :name => 'Fisher, B. L.')]
      another_possible_reference = Factory :article_reference, :author_names => [Factory(:author_name, :name => 'Warden, J.')]
      Reference.with_principal_author_last_name('Ward').should == [possible_reference]
    end
  end

  describe 'implementing ReferenceComparable' do
    it 'should map all fields correctly' do
      reference = ArticleReference.create! :author_names => [Factory(:author_name, :name => 'Fisher, B. L.')], :citation_year => '1981',
        :title => 'Dolichoderinae', :journal => Factory(:journal), :series_volume_issue => '1(2)', :pagination => '22-54'
      reference.author.should == 'Fisher'
      reference.year.should == 1981
      reference.title.should == 'Dolichoderinae'
      reference.type.should == 'ArticleReference'
      reference.series_volume_issue.should == '1(2)'
      reference.pagination.should == '22-54'
    end
  end

  describe "duplicate checking" do
    it "should not allow a duplicate record to be saved" do
      journal = Factory :journal
      author = Factory :author_name
      original = ArticleReference.create! :author_names => [author], :citation_year => '1981', :title => 'Dolichoderinae',
                               :journal => journal, :series_volume_issue => '1(2)', :pagination => '22-54'
      lambda {ArticleReference.create! :author_names => [author], :citation_year => '1981', :title => 'Dolichoderinae',
                               :journal => journal, :series_volume_issue => '1(2)', :pagination => '22-54'}.should raise_error
    end
  end

  describe "Key" do
    it "has a key" do
      reference = Factory :article_reference
      reference.key
    end
  end

end
