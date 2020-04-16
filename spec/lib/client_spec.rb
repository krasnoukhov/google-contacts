require "spec_helper"

describe GContacts::Client do
  include Support::ResponseMock

  context "contact" do
    it "loads all" do
      mock_response(File.read("spec/responses/contacts/all.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_get).with("/m8/feeds/contacts/default/full?updated-min=1234", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234")
      contacts = client.all(:params => {"updated-min" => "1234"})

      expect(contacts.id).to eq "john.doe@gmail.com"
      expect(contacts.updated.to_s).to eq "2012-04-05 21:46:31 UTC"
      expect(contacts.title).to eq "Johnny's Contacts"
      expect(contacts.author).to eq({"name" => "Johnny", "email" => "john.doe@gmail.com"})
      expect(contacts.next_uri).to_not be
      expect(contacts.per_page).to eq 25
      expect(contacts.start_index).to eq 1
      expect(contacts.total_results).to eq 4
      expect(contacts.length).to eq 4

      contact = contacts.first
      expect(contact.id).to eq "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/fd8fb1a55f2916e"
      expect(contact.title).to eq "Steve Stephson"
      expect(contact.updated.to_s).to eq "2012-02-06 01:14:56 UTC"
      expect(contact.edit_uri).to eq URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/fd8fb1a55f2916e")
      expect(contact.etag).to eq '"OWUxNWM4MTEzZjEyZTVjZTQ1Mjgy."'
      expect(contact.data).to eq({"gd:name" => [{"gd:fullName" => "Steve Stephson", "gd:givenName" => "Steve", "gd:familyName" => "Stephson"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve.stephson@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "steve@gmail.com"}], "gd:phoneNumber" => [{"text" => "3005004000", "@rel" => "http://schemas.google.com/g/2005#mobile"}, {"text" => "+130020003000", "@rel" => "http://schemas.google.com/g/2005#work"}]})

      contact = contacts[1]
      expect(contact.id).to eq "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/894bc75ebb5187d"
      expect(contact.title).to eq "Jill Doe"
      expect(contact.updated.to_s).to eq "2011-07-01 18:08:32 UTC"
      expect(contact.edit_uri).to eq URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/894bc75ebb5187d")
      expect(contact.etag).to eq '"ZGRhYjVhMTNkMmFhNzJjMzEyY2Ux."'
      expect(contact.data).to eq ({"gd:name" => [{"gd:fullName" => "Jill Doe", "gd:givenName" => "Jill", "gd:familyName" => "Doe"}]})

      contact = contacts[2]
      expect(contact.id).to eq "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/cd046ed518f0fb0"
      expect(contact.title).to eq 'Dave "Terry" Pratchett'
      expect(contact.updated.to_s).to eq "2011-06-29 23:11:57 UTC"
      expect(contact.edit_uri).to eq URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/cd046ed518f0fb0")
      expect(contact.etag).to eq '"ZWVhMDQ0MWI0MWM0YTJkM2MzY2Zh."'
      expect(contact.data).to eq({"gd:name" => [{"gd:fullName" => "Dave \"Terry\" Pratchett", "gd:givenName" => "Dave", "gd:additionalName" => "\"Terry\"", "gd:familyName" => "Pratchett"}], "gd:organization" => [{"gd:orgName" => "Foo Bar Inc", "@rel" => "http://schemas.google.com/g/2005#work"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "dave.pratchett@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "7003002000", "@rel" => "http://schemas.google.com/g/2005#mobile"}]})

      contact = contacts[3]
      expect(contact.id).to eq "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/a1941d3d13cdc66"
      expect(contact.title).to eq "Jane Doe"
      expect(contact.updated.to_s).to eq "2012-04-04 02:08:37 UTC"
      expect(contact.edit_uri).to eq URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/a1941d3d13cdc66")
      expect(contact.etag).to eq '"Yzg3MTNiODJlMTRlZjZjN2EyOGRm."'
      expect(contact.data).to eq({"gd:name" => [{"gd:fullName" => "Jane Doe", "gd:givenName" => "Jane", "gd:familyName" => "Doe"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#home", "@address" => "jane.doe@gmail.com", "@primary" => "true"}], "gd:phoneNumber" => [{"text" => "16004003000", "@rel" => "http://schemas.google.com/g/2005#mobile"}], "gd:structuredPostalAddress" => [{"gd:formattedAddress" => "5 Market St\n        San Francisco\n        CA", "gd:street" => "5 Market St", "gd:city" => "San Francisco", "gd:region" => "CA", "@rel" => "http://schemas.google.com/g/2005#home"}]})
    end

    it "paginates through all" do
      request_uri = ["/m8/feeds/contacts/default/full", "/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=3&max-results=2", "/m8/feeds/contacts/john.doe%40gmail.com/full?start-index=5&max-results=2"]
      request_uri.each_index do |i|
        res_mock = double("Response#{i}")
        allow(res_mock).to receive(:body).and_return(File.read("spec/responses/contacts/paginate_all_#{i}.xml"))
        allow(res_mock).to receive(:code).and_return("200")
        allow(res_mock).to receive(:message).and_return("OK")
        allow(res_mock).to receive(:header).and_return({})

        http_mock = double("HTTP#{i}")
        expect(http_mock).to receive(:use_ssl=).with(true)
        expect(http_mock).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        expect(http_mock).to receive(:start)
        expect(http_mock).to receive(:request_get).with(request_uri[i], anything).and_return(res_mock)

        expect(Net::HTTP).to receive(:new).ordered.once.and_return(http_mock)
      end

      expected_titles = ["Jack 1", "Jack 2", "Jack 3", "Jack 4", "Jack 5"]

      client = GContacts::Client.new(:access_token => "12341234")
      client.paginate_all do |entry|
        expect(entry.title).to eq expected_titles.shift
      end

      expect(expected_titles.length).to eq 0
    end

    it "gets a single one" do
      mock_response(File.read("spec/responses/contacts/get.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_get).with("/m8/feeds/contacts/default/full/908f380f4c2f81?a=1", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234")
      element = client.get("908f380f4c2f81", :params => {:a => 1})

      expect(element).to be_a_kind_of(GContacts::Element)
      expect(element.id).to eq "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8"
      expect(element.title).to eq "Casey"
      expect(element.edit_uri).to eq URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/3a203c8da7ac0a8")
    end

    it "creates a new one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.category = "contact"
      element.title = "Foo Bar"
      element.data = {"gd:name" => {"gd:fullName" => "Foo Bar", "gd:givenName" => "Foo Bar"}, "gd:email" => {"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => true}}

      mock_response(File.read("spec/responses/contacts/create.xml")) do |http_mock, res_mock|
        allow(http_mock).to receive(:request_post).with("/m8/feeds/contacts/default/full", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      created = client.create!(element)
      expect(created).to be_a_kind_of(GContacts::Element)
      expect(created.id).to eq "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/32c39d7106a538e"
      expect(created.title).to eq "Foo Bar"
      expect(created.data).to eq ({"gd:name" => [{"gd:fullName" => "Foo Bar", "gd:givenName" => "Foo Bar"}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => "true"}]})
      expect(created.edit_uri).to eq URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/full/32c39d7106a538e")
    end

    it "updates an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(nori_parser.parse(File.read("spec/responses/contacts/update.xml"))["entry"])
      expect(element.title).to eq'Foo "Doe" Bar'

      mock_response(File.read("spec/responses/contacts/update.xml")) do |http_mock, res_mock|
        allow(http_mock).to receive(:request_put).with("/m8/feeds/contacts/default/base/32c39d7106a538e", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234", "If-Match" => element.etag)).and_return(res_mock)
      end

      updated = client.update!(element)
      expect(updated).to be_a_kind_of(GContacts::Element)
      expect(updated.id).to eq "http://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/32c39d7106a538e"
      expect(updated.title).to eq 'Foo "Doe" Bar'
      expect(updated.data).to eq ({"gd:name" => [{"gd:fullName" => "Foo \"Doe\" Bar", "gd:givenName" => "Foo Bar", "gd:additionalName" => "\"Doe\""}], "gd:email" => [{"@rel" => "http://schemas.google.com/g/2005#other", "@address" => "casey@gmail.com", "@primary" => "true"}, {"@rel" => "http://schemas.google.com/g/2005#work", "@address" => "foo.bar@gmail.com"}]})
      expect(updated.edit_uri).to eq URI("https://www.google.com/m8/feeds/contacts/john.doe%40gmail.com/base/32c39d7106a538e")
    end

    it "deletes an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(nori_parser.parse(File.read("spec/responses/contacts/update.xml"))["entry"])

      mock_response(File.read("spec/responses/contacts/update.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request) do |request|
          expect(request.path).to eq "/m8/feeds/contacts/default/base/32c39d7106a538e"
          expect(request.to_hash["if-match"]).to eq [element.etag]
          expect(request.to_hash["authorization"]).to eq ["Bearer 12341234"]

          res_mock
        end
      end

      client.delete!(element)
    end

    it "batch creates without an error" do
      allow_any_instance_of(Time).to receive(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.title = "foo bar"
      element.content = "Bar Foo"
      element.data = {"gd:name" => [{"gd:givenName" => "foo bar"}]}
      element.category = "contact"
      element.create

      mock_response(File.read("spec/responses/contacts/batch_success.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_post) do |uri, data, headers|
          expect(uri).to eq "/m8/feeds/contacts/default/full/batch"
          expect(headers).to include("Authorization" => "Bearer 12341234")

          expect(nori_parser.parse(data)).to eq({"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => "2012-04-06T06:02:04Z", "atom:content" => "Bar Foo", "atom:title" => "foo bar", "gd:name" => {"gd:givenName" => "foo bar"}, "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}})

          res_mock
        end
      end

      results = client.batch!([element])
      expect(results.length).to eq 1
      result = results.first
      expect(result.data).to eq ({"gd:name" => [{"gd:fullName" => "foo bar", "gd:givenName" => "foo bar"}]})
      expect(result.batch).to eq ({"status" => "create", "code" => "201", "reason" => "Created", "operation" => "insert"})
    end

    it "batch creates with an error" do
      allow_any_instance_of(Time).to receive(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.title = "foo bar"
      element.content = "Bar Foo"
      element.data = {"gd:name" => [{"gd:givenName" => "foo bar"}]}
      element.category = "contact"
      element.create

      mock_response(File.read("spec/responses/contacts/batch_error.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_post) do |uri, data, headers|
          expect(uri).to eq "/m8/feeds/contacts/default/full/batch"
          expect(headers).to include("Authorization" => "Bearer 12341234")

          expect(nori_parser.parse(data)).to eq ({"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#contact"}, "updated" => "2012-04-06T06:02:04Z", "atom:content" => "Bar Foo", "atom:title" => "foo bar", "gd:name" => {"gd:givenName" => "foo bar"}, "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}})

          res_mock
        end
      end

      results = client.batch!([element])
      expect(results.length).to eq 1
      result = results.first
      expect(result.data).to eq ({})
      expect(result.batch).to eq ({"status" => {"parsed" => 0, "success" => 0, "error" => 0, "unprocessed" => 0}, "code" => "400", "reason" => "[Line 5, Column 35, element atom:entry] Invalid type for batch:operation: 'create'"})
    end
  end

  context "groups" do
    it "loads all" do
      mock_response(File.read("spec/responses/groups/all.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_get).with("/m8/feeds/groups/default/full?updated-min=1234", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      groups = client.all(:params => {"updated-min" => "1234"})

      expect(groups.id).to eq "john.doe@gmail.com"
      expect(groups.updated.to_s).to eq "2012-04-05 22:32:03 UTC"
      expect(groups.title).to eq "Johnny's Contact Groups"
      expect(groups.author).to eq ({"name" => "Johnny", "email" => "john.doe@gmail.com"})
      expect(groups.next_uri).to_not be
      expect(groups.per_page).to eq 25
      expect(groups.start_index).to eq 1
      expect(groups.total_results).to eq 2
      expect(groups.length).to eq 2

      group = groups.first
      expect(group.id).to eq "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"
      expect(group.title).to eq "System Group: My Contacts"
      expect(group.updated.to_s).to eq "1970-01-01 00:00:00 UTC"
      expect(group.edit_uri).to_not be
      expect(group.etag).to eq '"YWJmYzA."'
      expect(group.data.length).to eq 0

      group = groups[1]
      expect(group.id).to eq "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/ada43d293fdb9b1"
      expect(group.title).to eq "Misc"
      expect(group.updated.to_s).to eq "2009-08-17 20:33:20 UTC"
      expect(group.edit_uri).to eq URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/ada43d293fdb9b1")
      expect(group.etag).to eq '"QXc8cDVSLyt7I2A9WxNTFUkLRQQ."'
      expect(group.data.length).to eq 0
    end

    it "paginates through all" do
      request_uri = ["/m8/feeds/groups/default/full", "/m8/feeds/groups/john.doe%40gmail.com/full?start-index=2&max-results=1"]
      request_uri.each_index do |i|
        res_mock = double("Response#{i}")
        allow(res_mock).to receive(:body).and_return(File.read("spec/responses/groups/paginate_all_#{i}.xml"))
        allow(res_mock).to receive(:code).and_return("200")
        allow(res_mock).to receive(:message).and_return("OK")
        allow(res_mock).to receive(:header).and_return({})

        http_mock = double("HTTP#{i}")
        expect(http_mock).to receive(:use_ssl=).with(true)
        expect(http_mock).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE)
        expect(http_mock).to receive(:start)
        expect(http_mock).to receive(:request_get).with(request_uri[i], anything).and_return(res_mock)

        expect(Net::HTTP).to receive(:new).ordered.once.and_return(http_mock)
      end

      expected_titles = ["Misc 1", "Misc 2"]

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      client.paginate_all do |entry|
        expect(entry.title).to eq expected_titles.shift
      end

      expect(expected_titles.length).to eq 0
    end

    it "gets a single one" do
      mock_response(File.read("spec/responses/groups/get.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_get).with("/m8/feeds/groups/default/full/908f380f4c2f81?a=1", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)
      element = client.get("908f380f4c2f81", :params => {:a => 1})

      expect(element).to be_a_kind_of(GContacts::Element)
      expect(element.id).to eq "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/6"
      expect(element.title).to eq "System Group: My Contacts"
      expect(element.edit_uri).to_not be
      expect(element.etag).to eq '"YWJmYzA."'
    end

    it "creates a new one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new
      element.category = "group"
      element.title = "Foo Bar"
      element.content = "Foo Bar"

      mock_response(File.read("spec/responses/groups/create.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_post).with("/m8/feeds/groups/default/full", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234")).and_return(res_mock)
      end

      created = client.create!(element)
      expect(created).to be_a_kind_of(GContacts::Element)
      expect(created.id).to eq "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/005d057b3b3d42a"
      expect(created.title).to eq "Foo Bar"
      expect(created.data).to eq({})
      expect(created.edit_uri).to eq URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/full/005d057b3b3d42a")
    end

    it "updates an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(nori_parser.parse(File.read("spec/responses/groups/update.xml"))["entry"])
      expect(element.title).to eq "Bar Bar"
      expect(element.content).to eq "Bar Bar"

      mock_response(File.read("spec/responses/groups/update.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_put).with("/m8/feeds/groups/default/base/3f93e3738e811d63", "<?xml version='1.0' encoding='UTF-8'?>\n#{element.to_xml}", hash_including("Authorization" => "Bearer 12341234", "If-Match" => element.etag)).and_return(res_mock)
      end

      updated = client.update!(element)
      expect(updated).to be_a_kind_of(GContacts::Element)
      expect(updated.id).to eq "http://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/3f93e3738e811d63"
      expect(updated.title).to eq "Bar Bar"
      expect(updated.data).to eq ({})
      expect(updated.edit_uri).to eq URI("https://www.google.com/m8/feeds/groups/john.doe%40gmail.com/base/3f93e3738e811d63")
    end

    it "deletes an existing one" do
      client = GContacts::Client.new(:access_token => "12341234")

      element = GContacts::Element.new(nori_parser.parse(File.read("spec/responses/groups/update.xml"))["entry"])

      mock_response(File.read("spec/responses/groups/update.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request) do |request|
          expect(request.path).to eq "/m8/feeds/groups/default/base/3f93e3738e811d63"
          expect(request.to_hash["if-match"]).to eq [element.etag]
          expect(request.to_hash["authorization"]).to eq ["Bearer 12341234"]

          res_mock
        end
      end

      client.delete!(element)
    end

    it "batch creates without an error" do
      allow_any_instance_of(Time).to receive(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)

      element = GContacts::Element.new
      element.title = "foo bar"
      element.content = "Bar Foo"
      element.category = "group"
      element.create

      mock_response(File.read("spec/responses/groups/batch_success.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_post) do |uri, data, headers|
          expect(uri).to eq "/m8/feeds/groups/default/full/batch"
          expect(headers).to include("Authorization" => "Bearer 12341234")

          expect(nori_parser.parse(data)).to eq ({"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#group"}, "updated" => "2012-04-06T06:02:04Z", "atom:content" => "Bar Foo", "atom:title" => "foo bar", "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}})

          res_mock
        end
      end

      results = client.batch!([element])
      expect(results.length).to eq 1
      result = results.first
      expect(result.data).to eq ({})
      expect(result.batch).to eq ({"status" => "create", "code" => "201", "reason" => "Created", "operation" => "insert"})
    end

    it "batch creates with an error" do
      allow_any_instance_of(Time).to receive(:iso8601).and_return("2012-04-06T06:02:04Z")

      client = GContacts::Client.new(:access_token => "12341234", :default_type => :groups)

      element = GContacts::Element.new
      element.category = "group"
      element.create

      mock_response(File.read("spec/responses/groups/batch_error.xml")) do |http_mock, res_mock|
        expect(http_mock).to receive(:request_post) do |uri, data, headers|
          expect(uri).to eq "/m8/feeds/groups/default/full/batch"
          expect(headers).to include("Authorization" => "Bearer 12341234")

          expect(nori_parser.parse(data)).to eq ({"feed" => {"atom:entry" => {"batch:id" => "create", "batch:operation" => {"@type" => "insert"}, "atom:category" => {"@scheme" => "http://schemas.google.com/g/2005#kind", "@term" => "http://schemas.google.com/g/2008#group"}, "updated" => "2012-04-06T06:02:04Z", "atom:content" => {"@type" => "text"}, "atom:title" => nil, "@xmlns:atom" => "http://www.w3.org/2005/Atom", "@xmlns:gd" => "http://schemas.google.com/g/2005"}, "@xmlns" => "http://www.w3.org/2005/Atom", "@xmlns:gContact" => "http://schemas.google.com/contact/2008", "@xmlns:gd" => "http://schemas.google.com/g/2005", "@xmlns:batch" => "http://schemas.google.com/gdata/batch"}})

          res_mock
        end
      end

      results = client.batch!([element])
      expect(results.length).to eq 1
      result = results.first
      expect(result.data).to eq ({})
      expect(result.batch).to eq ({"status" => "create", "code" => "400", "reason" => "Entry does not have any fields set", "operation" => "insert"})
    end
  end
end
