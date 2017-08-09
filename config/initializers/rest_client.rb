class RestClient::Request
  class << self
    def execute_with_capture_duration(args, &block)
      started = Time.now
      res = execute_without_capture_duration(args, &block)
      @@duration = (@@duration || 0) + Time.now - started
      return res
    end

    def start_capture_duration
      @@duration = 0
    end

    def end_capture_duration
      @@duration
    end

    alias_method_chain :execute, :capture_duration
  end
end
