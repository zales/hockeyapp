module HockeyApp
  class Client

    def initialize ws
      @ws = ws
    end

    def get_apps
      Rails.cache.fetch("apps", :expires_in => 1.hour) do
        apps_hash = ws.get_apps
        assert_success apps_hash
        apps_hash["apps"].map{|app_hash|App.from_hash(app_hash, self)}
      end
    end

    def get_crashes app
      crashes_hash = ws.get_crashes app.public_identifier
      assert_success crashes_hash
      crashes_hash["crashes"].map{|crash_hash|Crash.from_hash(crash_hash, app, self)}
    end

    def get_crash_groups app
      crash_groups_hash = ws.get_crash_groups app.public_identifier
      assert_success crash_groups_hash
      crash_groups_hash["crash_reasons"].map{|reason_hash|CrashGroup.from_hash(reason_hash, app, self)}
    end

    def get_crash_log crash
      ws.get_crash_log crash.app.public_identifier, crash.id
    end

    def get_crash_description crash
      ws.get_crash_description crash.app.public_identifier, crash.id
    end

    def get_versions app
      Rails.cache.fetch("versions/#{app.public_identifier}", :expires_in => 1.hour) do
        versions_hash = ws.get_versions app.public_identifier
        versions_hash["app_versions"].map{|version_hash|Version.from_hash(version_hash, app, self)}
      end
    end

    def post_new_version version
      Rails.cache.delete("versions/#{version.app.public_identifier}")
      app_id = version.app.public_identifier
      ipa = version.ipa
      raise "There must be an executable file" if ipa.nil?
      version_hash = ws.post_new_version(app_id, ipa, version.dsym, version.notes, version.notes_type, version.notify, version.status)
      raise version_hash['errors'].map{|e|e.to_s}.join("\n") unless version_hash['errors'].nil?
      Version.from_hash(version_hash, version.app, self)
    end

    def remove_app app
      Rails.cache.delete("apps")
      resp = ws.remove_app app.public_identifier
      raise "unexpected response" if resp.code != 200
      resp.code == 200
    end

    def create_app file_ipa
      Rails.cache.delete("apps")
      resp = ws.post_new_app(file_ipa)
      raise resp['errors'].map{|e|e.to_s}.join("\n") unless resp['errors'].nil?
      App.from_hash(resp, self)
    end



    private

    attr_reader :ws

    def assert_success hash
      status = hash["status"]
      raise "Bad Status : #{status}" unless status == "success"
    end

  end
end