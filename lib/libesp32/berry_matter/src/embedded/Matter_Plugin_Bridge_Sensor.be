#
# Matter_Plugin_Bridge_Sensor.be - implements base class for a Sensor via HTTP to Tasmota
#
# Copyright (C) 2023  Stephan Hadinger & Theo Arends
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

import matter

# Matter plug-in for core behavior

# dummy declaration for solidification
class Matter_Plugin_Bridge_HTTP end

#@ solidify:Matter_Plugin_Bridge_Sensor,weak

class Matter_Plugin_Bridge_Sensor : Matter_Plugin_Bridge_HTTP
  # static var TYPE = ""                              # name of the plug-in in json
  # static var NAME = ""                              # display name of the plug-in
  static var ARG  = "filter"                        # additional argument name (or empty if none)
  static var ARG_HTTP = "url"                       # domain name
  static var UPDATE_TIME = 5000                     # update every 5s
  static var UPDATE_CMD = "Status 8"                # command to send for updates
  static var PROBE_TIMEOUT = 1700                   # timeout of 1700 ms for probing, which gives at least 1s for TCP recovery
  # static var SYNC_TIMEOUT = 500                     # timeout of 700 ms for probing
  var tasmota_sensor_filter                         # Rule-type filter to the value, like "ESP32#Temperature"
  var tasmota_sensor_matcher                        # Actual matcher object
  var shadow_value                                  # Last known value

  #############################################################
  # Constructor
  def init(device, endpoint, arguments)
    super(self).init(device, endpoint, arguments)
    self.tasmota_sensor_filter = arguments.find(self.ARG#-'filter'-#)
    if self.tasmota_sensor_filter
      self.tasmota_sensor_matcher = tasmota.Rule_Matcher.parse(self.tasmota_sensor_filter)
    end
  end

  #############################################################
  # Stub for updating shadow values (local copies of what we published to the Matter gateway)
  #
  # TO BE OVERRIDDEN
  def parse_update(data, index)
    if index == 8                               # Status 8
      if self.tasmota_sensor_matcher
        var val = self.pre_value(real(self.tasmota_sensor_matcher.match(data)))
        if val != nil
          if val != self.shadow_value
            self.value_changed(val)
          end
          self.shadow_value = val
        end
      end
    end
  end

  #############################################################
  # Called when the value changed compared to shadow value
  #
  # This must be overriden.
  # This is where you call `self.attribute_updated(<cluster>, <attribute>)`
  def value_changed(val)
    # self.attribute_updated(0x0402, 0x0000)
  end

  #############################################################
  # Pre-process value
  #
  # This must be overriden.
  # This allows to convert the raw sensor value to the target one, typically int
  def pre_value(val)
    return val
  end

  #############################################################
  # Return the first item in the filter
  def filter_name_html()
    if self.tasmota_sensor_filter
      import string
      import webserver
      return webserver.html_escape(string.split(self.tasmota_sensor_filter, '#')[0])
    end
    return ""
  end

end
matter.Plugin_Bridge_Sensor = Matter_Plugin_Bridge_Sensor
