require_relative '../../spec/support/rspec_helper'
require 'tempfile'

describe HockeyApp::Client do
  context "when there are valid responses" do

    let(:ws) {HockeyApp::FakeWS.new}
    let(:client) {HockeyApp::Client.new(ws)}
    let(:app) {HockeyApp::App.from_hash({"public_identifier" => "1234567890abcdef1234567890abcdef"}, client)}
    let(:crash){HockeyApp::Crash.from_hash({"id" => "123456789", "has_description" => true, "has_log" => true}, app, client)}
    let(:client_object) {HockeyApp::Client.new(HockeyApp::WS.new(:token => "6bb1a31f11904d4f99830ba0f42a70fb"))} #Pass token with full access


    describe "#get_apps" do
      it "returns an Enumerable " do
        client.get_apps.should be_kind_of Enumerable
      end

      it "has a single element " do
        client.get_apps.should have(2).item
      end

      it "returns App objects" do
        client.get_apps[0].should be_kind_of HockeyApp::App
      end

    end

    describe "#get_crashes" do
      it "returns an Enumerable " do
        client.get_crashes(app).should be_kind_of Enumerable
      end

      it "has a 10 elements " do
        client.get_crashes(app).should have(2).items
      end

      it "returns Crash objects" do
        client.get_crashes(app)[0].should be_kind_of HockeyApp::Crash
      end

    end

    describe "#get_crash_groups" do
      it "returns an Enumerable " do
        client.get_crash_groups(app).should be_kind_of Enumerable
      end

      it "has a 7 elements " do
        client.get_crash_groups(app).should have(2).items
      end

      it "returns CrashGroup objects" do
        client.get_crash_groups(app)[0].should be_kind_of HockeyApp::CrashGroup
      end

    end

    describe "#get_versions" do
      it "returns an Enumerable " do
        client.get_versions(app).should be_kind_of Enumerable
      end

      it "has a 9 elements " do
        client.get_versions(app).should have(2).items

      end

      it "returns Version objects" do
        client.get_versions(app)[0].should be_kind_of HockeyApp::Version
      end

    end

    describe "#get_crash_description" do

      it "returns expected string " do
        client.get_crash_description(crash).should == "crash_description"
      end

    end

    describe "#get_crash_log" do
      it "returns expected string " do
        client.get_crash_log(crash).should == "crash_log"
      end

    end

    describe "post_new_version" do

      it "raise an error when no payload is attached to the version object" do
        new_version = ::HockeyApp::Version.new(app, client)
        lambda { client.post_new_version new_version}.should raise_error

      end

      it "forms a valid post request with minimal payload" do
        new_version = ::HockeyApp::Version.new(app, client)
        fake_runtime = Tempfile.new('fake_runtime')
        new_version.ipa= fake_runtime

        ws.should_receive(:post_new_version).with(app.public_identifier, fake_runtime, nil, 'New version', 0, 0, 2).and_return({})
        client.post_new_version new_version
        fake_runtime.unlink
      end

      it "forms a valid request with full payload" do
        new_version = ::HockeyApp::Version.new(app, client)
        fake_runtime = Tempfile.new('fake_runtime')
        new_version.ipa= fake_runtime
        fake_symbols = Tempfile.new('fake_symbols')
        new_version.dsym = fake_symbols
        new_version.notes = "Fake notes"
        new_version.notes_type = ::HockeyApp::Version::NOTES_TYPES_TO_SYM.invert[:textile]
        new_version.notify = ::HockeyApp::Version::NOTIFY_TO_BOOL.invert[true]
        new_version.status = ::HockeyApp::Version::STATUS_TO_SYM.invert[:allow]


        ws.should_receive(:post_new_version).with(app.public_identifier, fake_runtime, fake_symbols, "Fake notes", 0, 1, 2).and_return({})
        client.post_new_version new_version
        fake_runtime.unlink
        fake_symbols.unlink

      end

      it "returns a Version object" do
        new_version = ::HockeyApp::Version.new(app, client)
        fake_runtime = Tempfile.new('fake_runtime')
        new_version.ipa= fake_runtime

        result = client.post_new_version new_version
        result.should be_kind_of ::HockeyApp::Version
        fake_runtime.unlink
      end

    end

    describe "remove_app" do
      it "returns expected code" do
        client.remove_app(app).should be_true
      end

    end

    describe "create_app" do
      it "returns an App object" do
        binary_file = double('file')
        client.create_app(binary_file).should be_kind_of ::HockeyApp::App
      end
    end

    describe "new_app" do
      it "raises an error when mandatory fields are not passed" do
        title = 'title'
        bundle_id = 'bundle_id'
        expect { client_object.new_app(title) }.to raise_error
        expect { client_object.new_app(bundle_id) }.to raise_error
      end

      it "raises error when incorrect path of image is passed" do
        title = 'title'
        bundle_id = 'bundle_id'
        params = {:icon => "/tmp/icon.png"} #any improper path
        expect { client_object.new_app(title, bundle_id, params) }.to raise_error
      end

      it "raises error when image passed is not of formats ['.png', '.jpeg', '.gif']" do
        title = 'title'
        bundle_id = 'bundle_id'
        params = {:icon => File.join(__dir__, "../../spec/icons/icon.ico")} #path with incorrect image format
        expect { client_object.new_app(title, bundle_id, params) }.to raise_error
      end

      it "raises error when platform passed is other than ['Android', 'iOS', 'Windows Phone', 'Mac OS', 'Custom']" do
        title = 'title'
        bundle_id = 'bundle_id'
        params = {:platform => 'platform'}  #incorrect platform
        expect { client_object.new_app(title, bundle_id, params) }.to raise_error
      end

      it "returns an App object" do
        title = 'title'
        bundle_id = 'bundle_id'
        params = {:platform => 'iOS', :release_type => 1, :custom_release_type => "custom", :icon => File.join(__dir__, "../../spec/icons/icon.png"), :private => true, :owner_id => "9adc0915100bf5ea1d7"}
        client_object.new_app(title, bundle_id, params).should be_kind_of ::HockeyApp::App
      end
    end

  end
end