module Patlite
  class PHN
    class Status

      RED_ON       = 0b00000001u8
      YELLOW_ON    = 0b00000010u8
      GREEN_ON     = 0b00000100u8
      BEEP_SHORT   = 0b00001000u8
      BEEP_LONG    = 0b00010000u8
      RED_FLASH    = 0b00100000u8
      YELLOW_FLASH = 0b01000000u8
      GREEN_FLASH  = 0b10000000u8

      enum Light
        OFF
        ON
        FLASH
      end

      enum Beep
        OFF
        SHORT
        LONG
      end

      property code
      @code : UInt8 = 0u8

      def initialize(code : UInt8 = 0u8)
        green_flash if (code & GREEN_FLASH) > 0
        yellow_flash if (code & YELLOW_FLASH) > 0
        red_flash if (code & RED_FLASH) > 0
        beep_long if (code & BEEP_LONG) > 0
        beep_short if (code & BEEP_SHORT) > 0
        green_on if (code & GREEN_ON) > 0
        yellow_on if (code & YELLOW_ON) > 0
        red_on if (code & RED_ON) > 0
      end

      def clear
        @code = 0u8
        self
      end

      {% for color in %i{ red yellow green } %}
        def {{color.id}}_off
          @code = @code & ~{{color.id.upcase}}_ON
          @code = @code & ~{{color.id.upcase}}_FLASH
          self
        end

        def {{color.id}}_on
          @code = @code & ~{{color.id.upcase}}_FLASH
          @code = @code | {{color.id.upcase}}_ON
          self
        end

        def {{color.id}}_flash
          @code = @code & ~{{color.id.upcase}}_ON
          @code = @code | {{color.id.upcase}}_FLASH
          self
        end

        def {{color.id}}_off? : Bool
          !({{color.id}}_on? || {{color.id}}_flash?)
        end

        def {{color.id}}_on? : Bool
          @code & {{color.id.upcase}}_ON > 0
        end

        def {{color.id}}_flash? : Bool
          if {{color.id}}_on?
            false
          else
            @code & {{color.id.upcase}}_FLASH > 0
          end
        end

        def {{color.id}} : Light
          if {{color.id}}_on?
            Light::ON
          elsif {{color.id}}_flash?
            Light::FLASH
          else
            Light::OFF
          end
        end

      {% end %}

      def beep_off
        @code = @code & ~BEEP_LONG
        @code = @code & ~BEEP_SHORT
        self
      end

      def beep_short
        @code = @code & ~BEEP_LONG
        @code = @code | BEEP_SHORT
        self
      end

      def beep_long
        @code = @code & ~BEEP_SHORT
        @code = @code | BEEP_LONG
        self
      end

      def beep_off?
        !(beep_short? || beep_long?)
      end

      def beep_short?
        @code & BEEP_SHORT > 0
      end

      def beep_long?
        if beep_short?
          false
        else
          @code & BEEP_LONG > 0
        end
      end

      def beep : Beep
        if beep_short?
          Beep::SHORT
        elsif beep_long?
          Beep::LONG
        else
          Beep::OFF
        end
      end

      def to_s(io : IO)
        io << "RED:" << red << " / "
        io << "YELLOW:" << yellow << " / "
        io << "GREEN:" << green << " / "
        io << "BEEP:" << beep
      end

      def inspect(io : IO)
        flags = [] of String
        flags << "RED_ON" if red_on?
        flags << "RED_FLASH" if red_flash?
        flags << "YELLOW_ON" if yellow_on?
        flags << "YELLOW_FLASH" if yellow_flash?
        flags << "GREEN_ON" if green_on?
        flags << "GREEN_FLASH" if green_flash?
        flags << "BEEP_SHORT" if beep_short?
        flags << "BEEP_LONG" if beep_long?
        flag = flags.empty? ? "OFF" : flags.join(" | ")
        io << "#<#{self.class.name}: " << flag <<  ">"
      end
    end
  end
end
