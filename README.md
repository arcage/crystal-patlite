# Patlite for Crystal

Crystal library for controlling [PATLITE](http://www.patlite.com/) signal towers by using PHN commands.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  patlite:
    github: arcage/crystal-patlite
```

## Usage

```crystal
require "patlite"

patlite_host = "192.168.0.100"
patlite_port = 10000

# initialize host(ip) and port for a signal tower
patlite = Patlite::PHN.new(patlite_host, patlite_port)

# set signal tower statuses
#
# You can set:
# - Light setting: `{{COLOR}}_{{PATTERN}}`
#
#    - `{{COLOR}}`   = red / yellow / green
#    - `{{PATTERN}}` = off / on / flash
#
# - Beep setting: `beep_{{PATTERN}}`
#
#    - `{{PATTERN}}` = off / short / long
patlite.set do
  red_on
  beep_long
end

# get signal tower statuses
status = patlite.status
status.red          #=> Patlite::PHN::Status::Light::ON
status.beep_short?  #=> false
puts status
#=> "RED:on / YELLOW:off / GREEN:off / BEEP:long"

sleep(2)

# add signal tower statuses to current settings
patlite.add do
  green_flash
  beep_off
end

puts patlite.status
#=> "RED:on / YELLOW:off / GREEN:flash / BEEP:off"

sleep(2)

# turn off all lights and beep
patlite.clear

puts patlite.status
#=> "RED:off / YELLOW:off / GREEN:off / BEEP:off"
```

## Contributors

- [arcage](https://github.com/arcage) ʕ·ᴥ·ʔAKJ - creator, maintainer
