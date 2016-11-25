require "./phn/*"

module Patlite
  class PHN

    def initialize(@host : String, @port : Int32)
    end

    def clear
      w_request(0u8)
    end

    def set : Bool
      status = Status.new
      with status yield
      w_request(status.code)
    end

    def add : Bool
      status = Status.new(r_request)
      with status yield
      w_request(status.code)
    end

    def status : Status
      Status.new(r_request)
    end

    private def w_request(code : UInt8) : Bool
      data = Slice(UInt8).new(2)
      data[0] = 0x57u8
      data[1] = code
      res = Slice(UInt8).new(3)
      TCPSocket.open(@host, @port) do |sock|
        sock.write data
        sock.read res
      end
      case String.new(res)
      when "ACK"
        true
      when "NAK"
        false
      else
        raise Error.new("Unknown responce #{res.inspect}")
      end
    end

    private def r_request : UInt8
      data = Slice(UInt8).new(1, 0x52u8)
      res = Slice(UInt8).new(2)
      TCPSocket.open(@host, @port) do |sock|
        sock.write data
        sock.read res
      end
      raise Error.new("Unknown responce #{res.inspect}") unless res[0] == 0x52u8
      res[1]
    end
  end
end
