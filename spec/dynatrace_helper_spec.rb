require 'open-uri'

describe Fastlane::Helper::DynatraceHelper do

  describe ".get_dss_client" do
    context "full valid workflow" do
      it "fetches and unzips the newest dss client successfully" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false)
        #expect(File).to receive(:read).and_return("http://127.0.0.1:8000/DTXDssClient.zip")
        #expect(File).to receive(:size).and_return(1)
        #expect(File).to receive(:delete).and_return(1, 1)
        expect(File).to receive(:write).and_return(1)

        expect(IO).to receive(:copy_stream).and_return(1)
        expect(FileUtils).to receive(:chmod).and_return(1)

        # no exception and returned path -> looks like we successfully installed the client
        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end

      it "uses deprecated client path parameter" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dtxDssClientPath = FastlaneCore::ConfigItem.new(key: :dtxDssClientPath, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn",
                 :dtxDssClientPath => "dynatrace/DTXDssClient123" }

        flhash = FastlaneCore::Configuration.create([server, apitoken, dtxDssClientPath], dict)
        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient123")
      end
    end

    context "invalid server response code - no fallback" do
      it "fetches the dss client config, but gets an error code" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPUnauthorized.new(1.0, '401', 'Unauthorized')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "fetches the dss client config, but gets an error code" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPUnauthorized.new(1.0, '401', 'Unauthorized')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end
    end

    context "gets empty json a json response" do
      it "is empty json - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{}' }.twice

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "is empty json - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{}' }.twice

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end

      it "is missing the json key - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl1": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "is missing the json key - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl1": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end

      it "is malformed json - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{""dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)
      end

      it "is malformed json - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{""dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' }.twice

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")
      end
    end

    context "retrieved dss client archive successfully" do
      it "is damaged - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_broken.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false).twice
        expect(File).to receive(:size).and_return(1)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)      
      end

      it "is damaged - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_broken.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false, true)
        expect(File).to receive(:size).and_return(1).twice

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")    
      end

      it "is missing the client binary - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_no client.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false).twice
        expect(File).to receive(:size).and_return(1)
        
        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)      
      end

      it "is missing the client binary - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_no client.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false, true)
        expect(File).to receive(:size).and_return(1).twice

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")    
      end

      it "is a 0 byte archive - no fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_empty.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false).twice
        expect(File).to receive(:size).and_return(0)

        expect{
          Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)
        }.to raise_error(RuntimeError)      
      end

      it "is a 0 byte archive - with fallback" do
        # mock config
        server = FastlaneCore::ConfigItem.new(key: :server, type: String, optional: false)
        apitoken = FastlaneCore::ConfigItem.new(key: :apitoken, type: String, optional: false)
        dict = { :server => "https://dynatrace.com/",
                 :apitoken => "9df8gzjn" }

        flhash = FastlaneCore::Configuration.create([server, apitoken], dict)

        # mock dss client updating request
        response = Net::HTTPSuccess.new(1.0, '200', 'OK')
        expect_any_instance_of(Net::HTTP).to receive(:request) { response }
        expect(response).to receive(:body) { '{"dssClientUrl": "http://127.0.0.1:8000/DTXDssClient.zip"}' } 

        # mock served archive
        content = File.open(Dir.pwd + "/spec/testdata/DTXDssClient_empty.zip").read
        tmpfile = Tempfile.new('dttest')
        tmpfile.write content
        tmpfile.rewind
        expect(Fastlane::Helper::DynatraceHelper).to receive(:save_to_tempfile).and_return(tmpfile)

        # mock file operations
        expect(File).to receive(:directory?).and_return(true)
        expect(File).to receive(:exists?).and_return(false, true)
        expect(File).to receive(:size).and_return(0, 1)

        expect(Fastlane::Helper::DynatraceHelper.get_dss_client(flhash)).to eql("dynatrace/DTXDssClient")    
      end
    end
  end

  describe ".get_server_base_url" do
    context "given 'https://dynatrace.com/'" do
      it "returns https://dynatrace.com" do
        dict = { :server => "https://dynatrace.com/" }
        expect(Fastlane::Helper::DynatraceHelper.get_server_base_url(dict)).to eql("https://dynatrace.com")
      end
    end

    context "given 'https://dynatrace.com'" do
      it "returns https://dynatrace.com" do
        dict = { :server => "https://dynatrace.com" }
        expect(Fastlane::Helper::DynatraceHelper.get_server_base_url(dict)).to eql("https://dynatrace.com")
      end
    end
  end

  describe ".check_fallback_or_raise" do
    context "given valid fallback client mocks" do
      it "throws no error" do
        error_msg = "no callback client found"
        fallback_client_path = "test/DTXDssClient"

        allow(File).to receive(:size).and_return(1)
        allow(File).to receive(:exists?).and_return(true)

        Fastlane::Helper::DynatraceHelper.check_fallback_or_raise(fallback_client_path, error_msg)
      end
    end

    context "empty client binary found" do
      it "throws an error" do
        error_msg = "no callback client found"
        fallback_client_path = "test/DTXDssClient"

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(true)

        expect{
          Fastlane::Helper::DynatraceHelper.check_fallback_or_raise(fallback_client_path, error_msg)
        }.to raise_error(error_msg)
      end
    end

    context "no client binary found" do
      it "throws an error" do
        error_msg = "no callback client found"
        fallback_client_path = "test/DTXDssClient"

        allow(File).to receive(:size).and_return(0)
        allow(File).to receive(:exists?).and_return(false)

        expect{
          Fastlane::Helper::DynatraceHelper.check_fallback_or_raise(fallback_client_path, error_msg)
        }.to raise_error(error_msg)
      end
    end
  end

  describe ".to_redacted_api_token_string" do
    context "given 'https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345'" do
      it "return https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=-----" do
        uri = URI("https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345")
        str_redacted = "https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=-----"
        expect(Fastlane::Helper::DynatraceHelper.to_redacted_api_token_string(uri)).to eql(str_redacted)
      end
    end

    context "given 'https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345&tesArg=123'" do
      it "calls the method with multiple arguments on url -> not designed to work with multiple args" do
        uri = URI("https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=12345&tesArg=123")
        str_redacted = "https://dynatrace.com/api/config/v1/symfiles/dtxdss-download?Api-Token=-----&tesArg=123"
        expect(Fastlane::Helper::DynatraceHelper.to_redacted_api_token_string(uri)).not_to eql(str_redacted)
      end
    end
  end
end