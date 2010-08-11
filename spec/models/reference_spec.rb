require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Reference do
  describe "importing 1995 and prior data" do
    describe "importing from a file" do
      before do
        @filename = 'foo.htm'
      end

      it "should do nothing if file is empty" do
        File.should_receive(:read).with(@filename).and_return('')
        Reference.import(@filename)
        Reference.all.should be_empty
      end

      it "should import a record from the second row of the first table it finds" do
        file_contents = "
          <html>
            <body>
              <table>
                <tr>
                </tr>
                <tr height=12>
                  <td></td>
                  <td height=12 class=xl65 align=right>5523</td>
                  <td class=xl65>Abdul-Rassoul, M. S.; Dawah, H. A.; Othman, N. Y.</td>
                  <td class=xl65>1978.</td>
                  <td class=xl65>197804</td>
                  <td class=xl65>Records of insect collection.</td>
                  <td class=xl65>Bull. Nat. Hist. Res. Cent. Univ. Baghdad 7(2):1-6.</td>
                  <td class=xl65>{Formicidae pp. 4-6.}At least, I think so</td>
                  <td class=xl65>PSW</td>
                </tr>
              </table>
            </body>
          </html>
        "
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        reference = Reference.first
        reference.authors.should == "Abdul-Rassoul, M. S.; Dawah, H. A.; Othman, N. Y."
        reference.year.should == "1978"
        reference.date.should == '197804'
        reference.title.should == 'Records of insect collection.'
        reference.citation.should == 'Bull. Nat. Hist. Res. Cent. Univ. Baghdad 7(2):1-6.'
        reference.journal_title.should == 'Bull. Nat. Hist. Res. Cent. Univ. Baghdad'
        reference.volume.should == '7'
        reference.issue.should == '2'
        reference.start_page.should == '1'
        reference.end_page.should == '6'
        reference.public_notes.should == 'Formicidae pp. 4-6.'
        reference.editor_notes.should == 'At least, I think so'
        reference.cite_code.should == '5523'
        reference.possess.should == 'PSW'
      end

      it "should read from the second row of the first table it finds and continue until first blank row" do
        file_contents = "
          <html><body><table><tr></tr>
            <tr>
              <td></td>
              <td>1</td>
              <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
            </tr>
            <tr>
              <td></td>
              <td>2</td>
              <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
            </tr>
            <tr>
              <td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td>
            </tr>
            <tr>
              <td></td>
              <td>3</td>
              <td></td><td></td><td></td><td></td><td></td><td></td><td></td>
            </tr>
          </table></body></html>"
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        Reference.count.should == 2
        Reference.all.map(&:cite_code).should =~ ['1', '2']
      end

      it "should collapse lines" do
        file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td><td></td><td></td>
            <td>Records of insect collection (Part I) in the Natural History
            Research Centre, Baghdad.</td>
          <td></td><td></td><td></td></tr></table></body></html>"
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        Reference.first.title.should == 'Records of insect collection (Part I) in the Natural History Research Centre, Baghdad.'
      end

      describe "parsing notes" do
        it "reads public notes" do
          file_contents = "<html><body><table><tr></tr><tr>
              <td></td>
              <td>123</td>
              <td></td>
              <td></td>
              <td></td>
              <td>title</td>
              <td>journal</td>
              <td>{Notes}</td>
              <td></td>
              <td></td>
          </tr></table></body></html>"

          File.should_receive(:read).with(@filename).and_return(file_contents)
          Reference.import(@filename)
          Reference.first.public_notes.should == 'Notes'
          Reference.first.editor_notes.should be_blank
        end
        it "reads editor's notes" do
          file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td><td></td><td></td>
            <td>title</td><td>journal</td>
            <td>Notes</td>
            <td></td><td></td></tr></table></body></html>"
          File.should_receive(:read).with(@filename).and_return(file_contents)
          Reference.import(@filename)
          Reference.first.public_notes.should be_blank
          Reference.first.editor_notes.should == 'Notes'
        end
        it "reads public and editor's notes" do
          file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td><td></td><td></td>
            <td>title</td><td>journal</td>
            <td>{Public} Editor</td>
            <td></td><td></td></tr></table></body></html>"
          File.should_receive(:read).with(@filename).and_return(file_contents)
          Reference.import(@filename)
          Reference.first.public_notes.should == 'Public'
          Reference.first.editor_notes.should == 'Editor'
        end
        it "handles linebreaks and italics" do
          file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td><td></td><td></td>
            <td>title</td><td>journal</td>
            <td>
  {Page 53: <font class=font7>Myrmicium</font><font class=font0>.}
  And </font><font class=font7>Myrmecium</font><font class=font0>
  (misspelling).</font>
            </td>
            <td></td><td></td></tr></table></body></html>"
          File.should_receive(:read).with(@filename).and_return(file_contents)
          Reference.import(@filename)
          Reference.first.public_notes.should == 'Page 53: *Myrmicium*.'
          Reference.first.editor_notes.should == 'And *Myrmecium* (misspelling).'
        end

      end

      it "should convert vertical bars (Phil's indication of italics) to asterisks (Markdown)" do
        file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td><td></td><td></td>
            <td>Records of |Formicidae|.</td>
          <td></td><td></td><td></td></tr></table></body></html>"
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        Reference.first.title.should == 'Records of *Formicidae*.'
      end

      it "should convert Microsoft's indication of italics to asterisks" do
        file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td><td></td><td></td>
            <td>Interaction between the ants <font class=font7>Zacryptocerus
  maculatus</font><font class=font0> and </font><font class=font7>Azteca
  trigona</font><font class=font0>.</font></td>
          <td></td><td></td><td></td></tr></table></body></html>"
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        Reference.first.title.should == 'Interaction between the ants *Zacryptocerus maculatus* and *Azteca trigona*.'
      end

      it "should convert entities to characters" do
        file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td><td></td><td></td>
            <td>Love &amp; Death</td>
          <td></td><td></td><td></td></tr></table></body></html>"
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        Reference.first.title.should == 'Love & Death'
      end

      it "should remove period from end of year" do
        file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td>
            <td>1978.</td><td></td><td></td>
          <td></td><td></td><td></td></tr></table></body></html>"
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        Reference.first.year.should == '1978'
      end

      it "should import the numeric year" do
        file_contents = "<html><body><table><tr></tr><tr><td></td><td>123</td><td></td>
            <td>1978a (\"2005\").</td><td></td><td></td>
          <td></td><td></td><td></td></tr></table></body></html>"
        File.should_receive(:read).with(@filename).and_return(file_contents)
        Reference.import(@filename)
        Reference.first.year.should == '1978a ("2005")'
        Reference.first.numeric_year.should == 1978
      end
    end

  end

  describe "importing post-1995 data" do
    it "should import a record" do
      filename = 'ANTBIB96.htm'
      file_contents = "
        <html>
          <body>
            <table>
              <tr>
              </tr>
              <tr height=12>
                <td></td>
                <td height=12 class=xl65 align=right>96-1828</td>
                <td class=xl65>Schlick-Steiner, B. C.; Steiner, F. M.; Seifert, B.; Stauffer, C.; Christian, E.; Crozier, R. H.</td>
                <td class=xl65>1978.</td>
                <td class=xl65>197804</td>
                <td class=xl65>Records of insect collection.</td>
                <td class=xl65>Bull. Nat. Hist. Res. Cent. Univ. Baghdad 7(2):1-6.</td>
                <td>Austromorium</td>
                <td class=xl65>Published online: 2005102</td>
                <td class=xl65>PSW</td>
              </tr>
            </table>
          </body>
        </html>
      "
      File.should_receive(:read).with(filename).and_return(file_contents)
      Reference.import(filename)
      reference = Reference.first
      reference.authors.should == "Schlick-Steiner, B. C.; Steiner, F. M.; Seifert, B.; Stauffer, C.; Christian, E.; Crozier, R. H."
      reference.year.should == "1978"
      reference.date.should == '197804'
      reference.title.should == 'Records of insect collection.'
      reference.citation.should == 'Bull. Nat. Hist. Res. Cent. Univ. Baghdad 7(2):1-6.'
      reference.journal_title.should == 'Bull. Nat. Hist. Res. Cent. Univ. Baghdad'
      reference.volume.should == '7'
      reference.issue.should == '2'
      reference.start_page.should == '1'
      reference.end_page.should == '6'
      reference.public_notes.should be_blank
      reference.editor_notes.should == 'Published online: 2005102'
      reference.taxonomic_notes.should == 'Austromorium'
      reference.cite_code.should == '96-1828'
      reference.possess.should == 'PSW'
    end
  end

  describe "parsing the citation" do
    describe "parsing a journal citation" do
      before do
        @reference = Factory(:reference, :citation => 'Behav. Ecol. Sociobiol. 4:163-181.')
      end

      it "should extract the journal title" do
        @reference.parse_citation
        @reference.journal_title.should == 'Behav. Ecol. Sociobiol.'
      end

      it "should extract the journal volume" do
        @reference.parse_citation
        @reference.volume.should == '4'
      end
      it "should extract the beginning page number" do
        @reference.parse_citation
        @reference.start_page.should == '163'
      end
      it "should extract the ending page number" do
        @reference.parse_citation
        @reference.end_page.should == '181'
      end
      it "should recognize it as a journal" do
        @reference.parse_citation
        @reference.kind.should == 'journal'
      end

      describe "parsing a citation with just a single page number" do
        it "should work" do
          reference = Factory(:reference, :citation => "Entomol. Mon. Mag. 92:8.")
          reference.parse_citation
          reference.journal_title.should == 'Entomol. Mon. Mag.'
          reference.volume.should == '92'
          reference.start_page.should == '8'
          reference.end_page.should be_nil
        end
      end

      describe "parsing a citation with an issue number" do
        it "should work" do
          reference = Factory(:reference, :citation => "Entomol. Mon. Mag. 92(32):8.")
          reference.parse_citation
          reference.volume.should == '92'
          reference.issue.should == '32'
          reference.start_page.should == '8'
          reference.end_page.should be_nil
        end
      end

      describe "parsing a citation with a series number" do
        it "should work" do
          reference = Factory(:reference, :citation => 'Ann. Mag. Nat. Hist. (10)8:129-131.')
          reference.parse_citation
          reference.series.should == '10'
          reference.volume.should == '8'
        end
      end

      describe "parsing a citation with series, volume and issue" do
        it "should work" do
          reference = Factory(:reference, :citation => 'Ann. Mag. Nat. Hist. (I)C(xix):129-131.')
          reference.parse_citation
          reference.series.should == 'I'
          reference.volume.should == 'C'
          reference.issue.should == 'xix'
        end
      end
    end

    describe "parsing a book citation" do
      before do
        @reference = Factory(:reference, :citation => 'Melbourne: CSIRO Publications, vii + 70 pp.')
      end

      it "should extract the place of publication" do
        @reference.parse_citation
        @reference.place.should == 'Melbourne'
      end

      it "should extract the publisher" do
        @reference.parse_citation
        @reference.publisher.should == 'CSIRO Publications'
      end
      it "should extract the pagination" do
        @reference.parse_citation
        @reference.pagination.should == 'vii + 70 pp.'
      end
      it "should recognize it as a book" do
        @reference.parse_citation
        @reference.kind.should == 'book'
      end
    end

    describe "parsing a book citation with complicate pagination" do
      it "should work" do
        reference = Factory(:reference, :citation => 'Tokyo: Keishu-sha, 247 pp. + 14 pl. + 4 pp. (index).')
        reference.parse_citation
        reference.place.should == 'Tokyo'
        reference.publisher.should == 'Keishu-sha'
        reference.pagination.should == '247 pp. + 14 pl. + 4 pp. (index).'
        reference.kind.should == 'book'
      end
    end

    describe "parsing a nested citation" do
      describe "without page numbers" do
        it "should work" do
          reference = Factory(:reference, :citation => 'In: Michaelsen, W., Hartmeyer, R. (eds.)  Die Fauna S�dwest-Australiens. Band I, Lieferung 7.  Jena: Gustav Fischer, pp. 263-310.')
          reference.parse_citation
          reference.kind.should == 'nested'
        end
      end
      describe "with page numbers" do
        it "should work" do
          reference = Factory(:reference, :citation => 'Pp. 191-210 in: Presl, J. S., Presl, K. B.  Deliciae Pragenses, historiam naturalem spectantes. Tome 1.  Pragae: Calve, 244 pp.')
          reference.parse_citation
          reference.kind.should == 'nested'
        end
      end

    end

    describe "parsing an unknown format" do
      it "should consider it an unknown format" do
        reference = Factory(:reference, :citation => 'asdf')
        reference.parse_citation
        reference.kind.should == 'unknown'
      end
    end
  end

  describe "searching" do
    it "should return an empty array if nothing is found for author" do
      Factory(:reference, :authors => 'Bolton')
      Reference.search(:author => 'foo').should be_empty
    end

    it "should find the reference for a given author if it exists" do
      reference = Factory(:reference, :authors => 'Bolton')
      Factory(:reference, :authors => 'Fisher')
      Reference.search(:author => 'Bolton').should == [reference]
    end

    it "should return an empty array if nothing is found for a given year and author" do
      Factory(:reference, :authors => 'Bolton', :numeric_year => 2010)
      Factory(:reference, :authors => 'Bolton', :numeric_year => 1995)
      Factory(:reference, :authors => 'Fisher', :numeric_year => 2011)
      Factory(:reference, :authors => 'Fisher', :numeric_year => 1996)
      Reference.search(:start_year => '2012', :end_year => '2013', :author => 'Fisher').should be_empty
    end


    it "should return the one reference for a given year and author" do
      Factory(:reference, :authors => 'Bolton', :numeric_year => 2010)
      Factory(:reference, :authors => 'Bolton', :numeric_year => 1995)
      Factory(:reference, :authors => 'Fisher', :numeric_year => 2011)
      reference = Factory(:reference, :authors => 'Fisher', :numeric_year => 1996)
      Reference.search(:start_year => '1996', :end_year => '1996', :author => 'Fisher').should == [reference]
    end

    describe "searching by year" do
      before do
        Factory(:reference, :numeric_year => 1994)
        Factory(:reference, :numeric_year => 1995)
        Factory(:reference, :numeric_year => 1996)
        Factory(:reference, :numeric_year => 1997)
        Factory(:reference, :numeric_year => 1998)
      end

      it "should return an empty array if nothing is found for year" do
        Reference.search(:start_year => '1992', :end_year => '1993').should be_empty
      end

      it "should find entries less than or equal to the end year" do
        Reference.search(:end_year => '1995').map(&:numeric_year).should =~ [1994, 1995]
      end

      it "should find entries equal to or greater than the start year" do
        Reference.search(:start_year => '1995').map(&:numeric_year).should =~ [1995, 1996, 1997, 1998]
      end

      it "should find entries in between the start year and the end year (inclusive)" do
        Reference.search(:start_year => '1995', :end_year => '1996').map(&:numeric_year).should =~ [1995, 1996]
      end

      it "should find references in the year of the end range, even if they have extra characters" do
        Factory(:reference, :year => '2004.', :numeric_year => 2004)
        Reference.search(:start_year => '2004', :end_year => '2004').map(&:numeric_year).should =~ [2004]
      end

      it "should find references in the year of the start year, even if they have extra characters" do
        Factory(:reference, :year => '2004.', :numeric_year => 2004)
        Reference.search(:start_year => '2004', :end_year => '2004').map(&:numeric_year).should =~ [2004]
      end

    end
    
    describe "sorting search results" do
      it "should sort by author plus year plus letter" do
        fisher1910b = Factory :reference, :authors => 'Fisher', :year => '1910b'
        wheeler1874 = Factory :reference, :authors => 'Wheeler', :year => '1874'
        fisher1910a = Factory :reference, :authors => 'Fisher', :year => '1910a'

        results = Reference.search

        results.should == [fisher1910a, fisher1910b, wheeler1874]
      end
    end

    describe "searching by journal" do
      it "should find by journal" do
        reference = Factory(:reference, :journal_title => "Mathematica")
        Reference.search(:journal => 'Mathematica').should == [reference]
      end
      it "should only do an exact match" do
        Factory(:reference, :journal_title => "Mathematica")
        Reference.search(:journal => 'Math').should be_empty
      end
    end

  end

  describe "parsing after editing" do
    it "should parse out the numeric year" do
      reference = Factory(:reference, :year => '1910a', :numeric_year => 1910)
      reference.update_attribute(:year, '2000a')
      reference.numeric_year.should == 2000
    end
    it "should parse out the journal title" do
      reference = Factory(:reference, :citation => 'Ecology Letters 12:324-333.', :journal_title => 'Ecology Letters')
      reference.update_attribute(:citation, 'Playboy 3:1-5')
      reference.journal_title.should == 'Playboy'
    end
  end
  describe "parsing after creating" do
    it "should parse out the numeric year" do
      reference = Factory(:reference, :year => '1910a')
      reference.numeric_year.should == 1910
    end
  end
end
