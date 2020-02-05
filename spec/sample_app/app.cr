module SampleApp
  class DbService
  end
  class Application
    property config

    def initialize(@config : SampleApp::DbService)
    end
  end
end