require 'spec_helper'

describe ReferenceDecorator do
  let(:nil_decorator) { ReferenceDecorator.new nil }
  let(:journal) { create :journal, name: "Neue Denkschriften" }
  let(:author_name) { create :author_name, name: "Forel, A." }

  # PDF link formatting
  describe "#format_reference_document_link" do
    it "creates a link" do
      reference = build_stubbed :reference
      allow(reference).to receive(:downloadable?).and_return true
      allow(reference).to receive(:url).and_return 'example.com'
      expect(reference.decorate.format_reference_document_link)
        .to eq '<a class="document_link" target="_blank" href="example.com">PDF</a>'
    end
  end

  describe "#make_html_safe" do
    def make_html_safe string
      nil_decorator.send :make_html_safe, string
    end

    it "doesn't touch a string without HTML" do
      expect(make_html_safe 'string').to eq 'string'
    end

    it "leaves italics alone" do
      expect(make_html_safe '<i>string</i>').to eq '<i>string</i>'
    end

    it "leaves quotes alone" do
      expect(make_html_safe '"string"').to eq '"string"'
    end

    it "returns an html_safe string" do
      expect(make_html_safe '"string"').to be_html_safe
    end

    it "escapes other HTML" do
      expect(make_html_safe '<script>danger</script>')
        .to eq '&lt;script&gt;danger&lt;/script&gt;'
    end
  end

  #TODO DRY
  describe "#formatted" do
    it "formats the reference" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452"
      string = reference.decorate.formatted
      expect(string).to be_html_safe
      expect(string).to eq 'Forel, A. 1874. Les fourmis de la Suisse. Neue Denkschriften 26:1-452.'
    end

    it "adds a period after the title if none exists" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452"
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse. Neue Denkschriften 26:1-452.'
    end

    it "doesn't add a period after the author_names' suffix" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452"
      reference.update_attribute :author_names_suffix, ' (ed.)'
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. (ed.) 1874. Les fourmis de la Suisse. Neue Denkschriften 26:1-452.'
    end

    it "doesn't add a period after the title if it ends with a question mark" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse?",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452"
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse? Neue Denkschriften 26:1-452.'
    end

    it "doesn't add a period after the title if it ends with an exclamation mark" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse!",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452"
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse! Neue Denkschriften 26:1-452.'
    end

    it "doesn't add a period after the title if there's already one" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse.",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452"
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse. Neue Denkschriften 26:1-452.'
    end

    it "adds a period after the citation if none exists" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse.",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452"
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse. Neue Denkschriften 26:1-452.'
    end

    it "doesn't add a period after the citation if there's already one" do
      reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse.",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452."
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse. Neue Denkschriften 26:1-452.'
    end

    it "separates the publisher and the pagination with a comma" do
      publisher = create :publisher
      reference = create :book_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse.",
        publisher: publisher, pagination: "22 pp."
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse. New York: Wiley, 22 pp.'
    end

    it "formats unknown references" do
      reference = create :unknown_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse.",
        citation: 'New York'
      expect(reference.decorate.formatted).to eq 'Forel, A. 1874. Les fourmis de la Suisse. New York.'
    end

    it "formats nested references" do
      reference = create :book_reference,
        author_names: [create(:author_name, name: 'Mayr, E.')],
        citation_year: '2010',
        title: 'Ants I have known',
        publisher: create(:publisher, name: 'Wiley', place: create(:place, name: 'New York')),
        pagination: '32 pp.'
      nested_reference = create :nested_reference, nesting_reference: reference,
        author_names: [author_name], title: 'Les fourmis de la Suisse',
        citation_year: '1874', pages_in: 'Pp. 32-45 in'
      expect(nested_reference.decorate.formatted).to eq(
        'Forel, A. 1874. Les fourmis de la Suisse. Pp. 32-45 in Mayr, E. 2010. Ants I have known. New York: Wiley, 32 pp.'
      )
    end

    it "formats a citation_string correctly if the publisher doesn't have a place" do
      publisher = Publisher.create! name: "Wiley"
      reference = create :book_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse.",
        publisher: publisher,
        pagination: "22 pp."
      expect(reference.decorate.formatted)
        .to eq 'Forel, A. 1874. Les fourmis de la Suisse. Wiley, 22 pp.'
    end

    context "with unsafe characters" do
      let!(:author_names) { [create(:author_name, name: 'Ward, P. S.')] }
      let(:reference) do
        create :unknown_reference, author_names: author_names,
          citation_year: "1874", title: "Les fourmis de la Suisse.", citation: '32 pp.'
      end

      it "escapes everything, buts let italics through" do
        reference.author_names = [create(:author_name, name: '<script>')]
        expect(reference.decorate.formatted)
          .to eq '&lt;script&gt; 1874. Les fourmis de la Suisse. 32 pp.'
      end

      it "escapes the citation year" do
        reference.update_attribute :citation_year, '<script>'
        expect(reference.decorate.formatted)
          .to eq 'Ward, P. S. &lt;script&gt;. Les fourmis de la Suisse. 32 pp.'
      end

      it "escapes the title" do
        reference.update_attribute :title, '<script>'
        expect(reference.decorate.formatted).to eq 'Ward, P. S. 1874. &lt;script&gt;. 32 pp.'
      end

      it "escapes the title but leave the italics alone" do
        reference.update_attribute :title, '*foo*<script>'
        expect(reference.decorate.formatted).to eq 'Ward, P. S. 1874. <i>foo</i>&lt;script&gt;. 32 pp.'
      end

      it "escapes the date" do
        reference.update_attribute :date, '1933>'
        expect(reference.decorate.formatted)
          .to eq 'Ward, P. S. 1874. Les fourmis de la Suisse. 32 pp. [1933&gt;]'
      end

      it "escapes the citation in an article reference" do
        reference = create :article_reference,
          title: 'Ants are my life', author_names: author_names,
          journal: create(:journal, name: '<script>'), citation_year: '2010d', series_volume_issue: '<', pagination: '>'
        expect(reference.decorate.formatted)
          .to eq 'Ward, P. S. 2010d. Ants are my life. &lt;script&gt; &lt;:&gt;.'
      end

      it "escapes the citation in a book reference" do
        reference = create :book_reference,
          citation_year: '2010d',
          title: 'Ants are my life',
          author_names: author_names,
          publisher: create(:publisher, name: '<', place: create(:place, name: '>')),
          pagination: '>'
        expect(reference.decorate.formatted)
          .to eq 'Ward, P. S. 2010d. Ants are my life. &gt;: &lt;, &gt;.'
      end

      it "escapes the citation in an unknown reference" do
        reference = create :unknown_reference,
          title: 'Ants are my life',
          citation_year: '2010d',
          author_names: author_names,
          citation: '>'
        expect(reference.decorate.formatted).to eq 'Ward, P. S. 2010d. Ants are my life. &gt;.'
      end

      it "escapes the citation in a nested reference" do
        nested_reference = create :unknown_reference,
          title: "Ants are my life",
          citation_year: '2010d',
          author_names: author_names
        reference = create :nested_reference,
          title: "Ants are my life",
          citation_year: '2010d',
          author_names: author_names,
          pages_in: '>',
          nesting_reference: nested_reference
        expect(reference.decorate.formatted)
          .to eq 'Ward, P. S. 2010d. Ants are my life. &gt; Ward, P. S. 2010d. Ants are my life. New York.'
      end
    end

    describe "Italicizing title and citation" do
      it "returns an html_safe string" do
        reference = create :unknown_reference,
          citation_year: '2010d',
          author_names: [],
          citation: '*Ants*',
          title: '*Tapinoma*'
        expect(reference.decorate.formatted).to be_html_safe
      end

      it "italicizes the title and citation" do
        reference = create :unknown_reference,
          citation_year: '2010d',
          author_names: [],
          citation: '*Ants*',
          title: '*Tapinoma*'
        expect(reference.decorate.formatted).to eq "2010d. <i>Tapinoma</i>. <i>Ants</i>."
      end

      it "italicizes the title even with two italicized words" do
        reference = create :unknown_reference,
          citation_year: '2010d',
          author_names: [],
          citation: 'Ants',
          title: 'Note on a new northern cutting ant, *Atta* *septentrionalis*.'
        expect(reference.decorate.formatted)
          .to eq "2010d. Note on a new northern cutting ant, <i>Atta</i> <i>septentrionalis</i>. Ants."
      end

      it "allows existing italics in title and citation" do
        reference = create :unknown_reference,
          citation_year: '2010d',
          author_names: [],
          citation: '*Ants*',
          title: '<i>Tapinoma</i>'
        expect(reference.decorate.formatted).to eq "2010d. <i>Tapinoma</i>. <i>Ants</i>."
      end

      it "escapes other HTML in title and citation" do
        reference = create :unknown_reference,
          citation_year: '2010d',
          author_names: [],
          citation: '*Ants*',
          title: '<span>Tapinoma</span>'
        expect(reference.decorate.formatted)
          .to eq "2010d. &lt;span&gt;Tapinoma&lt;/span&gt;. <i>Ants</i>."
      end

      it "doesn't escape et al. in citation" do
        reference = create :unknown_reference,
          author_names: [],
          citation_year: '2010',
          citation: 'Ants <i>et al.</i>',
          title: 'Tapinoma'
        expect(reference.decorate.formatted).to eq "2010. Tapinoma. Ants <i>et al.</i>."
      end

      it "doesn't escape et al. in citation for a missing reference" do
        reference = create :missing_reference,
          author_names: [],
          citation_year: '2010',
          citation: 'Ants <i>et al.</i>',
          title: 'Tapinoma'
        expect(reference.decorate.formatted).to eq "2010. Tapinoma. Ants <i>et al.</i>"
      end
    end
  end

  context "when there are no authors" do
    it "doesn't have a space at the beginning" do
      reference = create :unknown_reference,
        citation_year: '2010d',
        author_names: [],
        citation: 'Ants',
        title: 'Tapinoma'
      expect(reference.decorate.formatted).to eq "2010d. Tapinoma. Ants."
    end
  end

  describe "formatting the date" do
    it "uses ISO 8601 format for calendar dates" do
      make '20101213'
      check ' [2010-12-13]'
    end

    it "handles years without months and days" do
      make '201012'
      check ' [2010-12]'
    end

    it "handles years with months but without days" do
      make '2010'
      check ' [2010]'
    end

    it "handles nil dates" do
      make nil
      check ''
    end

    it "handles missing dates" do
      make ''
      check ''
    end

    it "handles dates with other symbols/characters" do
      make '201012>'
      check ' [2010-12&gt;]'
    end

    def make date
      @reference = create :article_reference,
        author_names: [author_name],
        citation_year: "1874",
        title: "Les fourmis de la Suisse.",
        journal: journal,
        series_volume_issue: "26",
        pagination: "1-452.",
        date: date
    end

    def check expected
      expect(@reference.decorate.formatted)
        .to eq "Forel, A. 1874. Les fourmis de la Suisse. Neue Denkschriften 26:1-452.#{expected}"
    end
  end

  describe "#format_italics" do
    it "replaces asterisks and bars with italics" do
      string = nil_decorator.send :format_italics, "|Hymenoptera| *Formicidae*".html_safe
      expect(string).to eq "<i>Hymenoptera</i> <i>Formicidae</i>"
      expect(string).to be_html_safe
    end

    context "string isn't html_safe" do
      it "raises" do
        expect { nil_decorator.send :format_italics, 'roman' }.to raise_error
      end
    end
  end

  describe "#inline_citation" do
    context "a MissingReference" do
      it "just outputs the citation" do
        reference = create :missing_reference, citation: 'foo'
        expect(reference.decorate.inline_citation).to eq 'foo'
      end
    end
  end

  # Returns the display string for a review status.
  describe "#format_review_state" do
    let(:reference) { build_stubbed :article_reference }

    it "handles 'reviewed'" do
      reference.review_state = 'reviewed'
      expect(reference).to have_formatted_review_state 'Reviewed'
    end

    it "handles 'reviewing'" do
      reference.review_state = 'reviewing'
      expect(reference).to have_formatted_review_state 'Being reviewed'
    end

    it "handles 'none'" do
      reference.review_state = 'none'
      expect(reference).to have_formatted_review_state ''
    end

    it "handles empty states" do
      reference.review_state = ''
      expect(reference).to have_formatted_review_state ''
    end

    it "handles nil" do
      reference.review_state = nil
      expect(reference).to have_formatted_review_state ''
    end
  end

  describe "a regression where a string should've been duped" do
    let(:reference) do
      journal = create :journal, name: 'Ants'
      create :article_reference,
        author_names: [author_name], citation_year: '1874', title: 'Format',
        journal: journal, series_volume_issue: '1:1', pagination: '2'
    end

    it "really should have been duped" do
      expect(reference.decorate.formatted).to eq 'Forel, A. 1874. Format. Ants 1:1:2.'
    end
  end

  describe "Using ReferenceFormatterCache" do
    let(:reference) { create :article_reference }

    it "returns an html_safe string from the cache" do
      ReferenceFormatterCache.populate reference
      expect(reference.decorate.formatted).to be_html_safe
    end
  end
end
