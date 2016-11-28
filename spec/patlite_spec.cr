require "./spec_helper"

class DummyPatlite
  DEFAULT_STATUS = 137u8

  def initialize(@port : Int32)
    @status = DEFAULT_STATUS
    @socket = TCPServer.new(10000)
    start
  end

  def start
    loop do
      @socket.accept do |client|
        com = client.read_byte.not_nil!
        case com
        when 0x57u8
          if status = client.read_byte
            @status = status
            client.write "ACK".to_slice
          else
            client.write "NAK".to_slice
          end
        when 0x52u8
          client.write_byte 0x52u8
          client.write_byte @status
        else
          client.write "NAK".to_slice
        end
      end
    end
  ensure
    @socket.close
  end
end

spawn do
  DummyPatlite.new(10000)
end

sleep 1

describe Patlite::PHN do
  patlite = Patlite::PHN.new("127.0.0.1", 10000)

  describe "#status" do
    it "return the signal tower status" do
      patlite.status.code.should eq DummyPatlite::DEFAULT_STATUS
    end
  end

  describe "#clear" do
    it "tuen all of signal tower status to off" do
      patlite.clear
      patlite.status.code.should eq 0u8
    end
  end

  describe "#set" do
    it "sets signal tower status" do
      patlite.set { red_on }
      patlite.status.red_on?.should be_true
    end
  end

  describe "#add" do
    it "adds signal tower status from current settings" do
      patlite.add {
        green_flash
        beep_short
      }
      status = patlite.status
      status.red_on?.should be_true
      status.green_flash?.should be_true
      status.beep_short?.should be_true
    end
  end
end

describe Patlite::PHN::Status do
  describe ".new" do
    it "uses an argument as an internal status code" do
      Patlite::PHN::Status.new(129u8).code.should eq 129u8
    end

    it "gets rid of contradictories in the argument" do
      Patlite::PHN::Status.new(Patlite::PHN::Status::RED_ON | Patlite::PHN::Status::RED_FLASH).code.should eq Patlite::PHN::Status::RED_ON
    end

    it "uses 0u8 as an internal status code when called without argument" do
      Patlite::PHN::Status.new.code.should eq 0u8
    end
  end

  describe "#clear" do
    it "turn all statuses to :off" do
      code = 0xffu8
      status = Patlite::PHN::Status.new(code)
      status.clear
      status.red.should eq Patlite::PHN::Status::Light::OFF
      status.yellow.should eq Patlite::PHN::Status::Light::OFF
      status.green.should eq Patlite::PHN::Status::Light::OFF
      status.beep.should eq Patlite::PHN::Status::Beep::OFF
    end
  end

  {% for color in %i(red yellow green) %}
    describe "#"+"{{color.id}}" do
      it "returns {{color.id}} light status" do
        Patlite::PHN::Status.new.{{color.id}}.should eq Patlite::PHN::Status::Light::OFF
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_ON).{{color.id}}.should eq Patlite::PHN::Status::Light::ON
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_FLASH).{{color.id}}.should eq Patlite::PHN::Status::Light::FLASH
      end

      it "gives priority to \"on\" over \"flash\" status" do
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_ON | Patlite::PHN::Status::{{color.id.upcase}}_FLASH).{{color.id}}.should eq Patlite::PHN::Status::Light::ON
      end
    end

    describe "#"+"{{color.id}}_off?" do
      it "returns true when {{color.id}} light status is Light::OFF" do
        Patlite::PHN::Status.new.{{color.id}}_off?.should be_true
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_ON).{{color.id}}_off?.should be_false
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_FLASH).{{color.id}}_off?.should be_false
      end
    end

    describe "#"+"{{color.id}}_on?" do
      it "returns true when {{color.id}} light status is Light::ON" do
        Patlite::PHN::Status.new.{{color.id}}_on?.should be_false
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_ON).{{color.id}}_on?.should be_true
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_FLASH).{{color.id}}_on?.should be_false
      end
    end

    describe "#"+"{{color.id}}_flash?" do
      it "returns true when {{color.id}} light status is Light::FLASH" do
        Patlite::PHN::Status.new.{{color.id}}_flash?.should be_false
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_ON).{{color.id}}_flash?.should be_false
        Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_FLASH).{{color.id}}_flash?.should be_true
      end
    end

    describe "#"+"{{color.id}}_off" do
      it "turns {{color.id}} light status to Light::OFF" do
        status = Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_ON)
        status.{{color.id}}_off
        status.{{color.id}}.should eq Patlite::PHN::Status::Light::OFF
      end
    end

    describe "#"+"{{color.id}}_on" do
      it "turns {{color.id}} light status to Light::ON" do
        status = Patlite::PHN::Status.new
        status.{{color.id}}_on
        status.{{color.id}}.should eq Patlite::PHN::Status::Light::ON
      end
    end

    describe "#"+"{{color.id}}_flash" do
      it "turns {{color.id}} light status to Light::FLASH" do
        status = Patlite::PHN::Status.new
        status.{{color.id}}_flash
        status.{{color.id}}.should eq Patlite::PHN::Status::Light::FLASH
      end

      it "overrides {{color.id}} light :on status to Light::FLASH" do
        status = Patlite::PHN::Status.new(Patlite::PHN::Status::{{color.id.upcase}}_ON)
        status.{{color.id}}_flash
        status.{{color.id}}.should eq Patlite::PHN::Status::Light::FLASH
      end
    end

  {% end %}

  describe "#beep" do
    it "returns beep status" do
      Patlite::PHN::Status.new.beep.should eq Patlite::PHN::Status::Beep::OFF
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_SHORT).beep.should eq Patlite::PHN::Status::Beep::SHORT
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_LONG).beep.should eq Patlite::PHN::Status::Beep::LONG
    end
  end

  describe "#beep_off?" do
    it "returns true when beep status is Beep::OFF" do
      Patlite::PHN::Status.new.beep_off?.should be_true
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_SHORT).beep_off?.should be_false
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_LONG).beep_off?.should be_false
    end
  end

  describe "#beep_short?" do
    it "returns true when beep status is Beep::SHORT" do
      Patlite::PHN::Status.new.beep_short?.should be_false
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_SHORT).beep_short?.should be_true
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_LONG).beep_short?.should be_false
    end
  end

  describe "#beep_long?" do
    it "returns true when beep status is Beep::SHORT" do
      Patlite::PHN::Status.new.beep_long?.should be_false
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_SHORT).beep_long?.should be_false
      Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_LONG).beep_long?.should be_true
    end
  end

  describe "#beep_off" do
    it "turns beep status to BEEP::OFF" do
      status = Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_SHORT)
      status.beep_off
      status.beep.should eq Patlite::PHN::Status::Beep::OFF
    end
  end

  describe "#beep_short" do
    it "turns beep status to BEEP::SHORT" do
      status = Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_LONG)
      status.beep_short
      status.beep.should eq Patlite::PHN::Status::Beep::SHORT
    end
  end

  describe "#beep_long" do
    it "turns beep status to BEEP::LONG" do
      status = Patlite::PHN::Status.new(Patlite::PHN::Status::BEEP_SHORT)
      status.beep_long
      status.beep.should eq Patlite::PHN::Status::Beep::LONG
    end
  end
end
