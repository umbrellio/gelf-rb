require 'helper'

class TestLogger < Test::Unit::TestCase
  context "with notifier with mocked sender" do
    setup do
      Socket.stubs(:gethostname).returns('stubbed_hostname')
      @notifier = GELF::Notifier.new('host', 12345)
      @sender = mock
      @notifier.instance_variable_set('@sender', @sender)
    end

    should "send pending notifications on #close" do
      @notifier.expects(:send_pending_notifications)
      @notifier.close
    end

    context "#add" do
      # logger.add(Logger::INFO, 'Message')
      should "implement add method with level and message from parameters" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'Message' &&
          hash['level'] == GELF::INFO
        end
        @notifier.add(GELF::INFO, 'Message')
      end

      # logger.add(Logger::INFO, RuntimeError.new('Boom!'))
      should "implement add method with level and exception from parameters" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['level'] == GELF::INFO
        end
        @notifier.add(GELF::INFO, RuntimeError.new('Boom!'))
      end

      # logger.add(Logger::INFO) { 'Message' }
      should "implement add method with level from parameter and message from block" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'Message' &&
          hash['level'] == GELF::INFO
        end
        @notifier.add(GELF::INFO) { 'Message' }
      end

      # logger.add(Logger::INFO) { RuntimeError.new('Boom!') }
      should "implement add method with level from parameter and exception from block" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['level'] == GELF::INFO
        end
        @notifier.add(GELF::INFO) { RuntimeError.new('Boom!') }
      end

      # logger.add(Logger::INFO, 'Message', 'Facility')
      should "implement add method with level, message and facility from parameters" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'Message' &&
          hash['level'] == GELF::INFO &&
          hash['facility'] == 'Facility'
        end
        @notifier.add(GELF::INFO, 'Message', 'Facility')
      end

      # logger.add(Logger::INFO, RuntimeError.new('Boom!'), 'Facility')
      should "implement add method with level, exception and facility from parameters" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['level'] == GELF::INFO &&
          hash['facility'] == 'Facility'
        end
        @notifier.add(GELF::INFO, RuntimeError.new('Boom!'), 'Facility')
      end

      # logger.add(Logger::INFO, 'Facility') { 'Message' }
      should "implement add method with level and facility from parameters and message from block" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'Message' &&
          hash['level'] == GELF::INFO &&
          hash['facility'] == 'Facility'
        end
        @notifier.add(GELF::INFO, 'Facility') { 'Message' }
      end

      # logger.add(Logger::INFO, 'Facility') { RuntimeError.new('Boom!') }
      should "implement add method with level and facility from parameters and exception from block" do
        @notifier.expects(:notify!).with do |hash|
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['level'] == GELF::INFO &&
          hash['facility'] == 'Facility'
        end
        @notifier.add(GELF::INFO, 'Facility') { RuntimeError.new('Boom!') }
      end
    end

    GELF::Levels.constants.each do |const|
      # logger.error "Argument #{ @foo } mismatch."
      should "call notify with level #{const} from method name and message from parameter" do
        @notifier.expects(:add).with(GELF.const_get(const), 'message')
        @notifier.__send__(const.downcase, 'message')
      end

      # logger.fatal { "Argument 'foo' not given." }
      should "call notify with level #{const} from method name and message from block" do
        @notifier.expects(:add).with(GELF.const_get(const), 'message')
        @notifier.__send__(const.downcase) { 'message' }
      end

      # logger.info('initialize') { "Initializing..." }
      should "call notify with level #{const} from method name, facility from parameter and message from block" do
        @notifier.expects(:add).with(GELF.const_get(const), 'message', 'facility')
        @notifier.__send__(const.downcase, 'facility') { 'message' }
      end

      should "respond to #{const.downcase}?" do
        @notifier.level = GELF.const_get(const) - 1
        assert @notifier.__send__(const.to_s.downcase + '?')
        @notifier.level = GELF.const_get(const)
        assert @notifier.__send__(const.to_s.downcase + '?')
        @notifier.level = GELF.const_get(const) + 1
        assert !@notifier.__send__(const.to_s.downcase + '?')
      end
    end

    should_eventually "support Notifier#<<"
  end
end