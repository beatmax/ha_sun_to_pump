# ☀️ SunToPump 🌡️

Sets your room thermostat according to available excess solar power, optimizing heat pump usage.

Useful when your heat pump doesn't support direct power input control ("smart grid ready" or similar).
Learns the power consumption of the heat pump in different conditions, in order to indirectly control the power input using the thermostat.

## Requirements

### Input sensors
- Active power (combined import/export power, negative value when exporting).
- Heat pump's power input.
- Outside temperature.
- Room temperature.
- Room thermostat setpoint.

The active power is usually provided by a device attached to the electricity meter. The other values are ideally provided by the heat pump controller's API, which makes the behavior of the heat pump more predictable, but other methods of obtaining those values should also work. (Side note: This package has been developed and tested with a dutch Quatt heat pump. Please share your experience with a different heat pump!)

Note that exported power is used, not PV production. This way other consumers are taken into account: the thermostat will stay low when e.g., a washing machine is working or an electric car is charging.

### Thermostat
Your room's thermostat must already be controlable from Home Assistant. A stable local connection is recommended. For example, Honeywell Lyric thermostats work better with the 'HomeKit Device' integration than with the cloud-based 'Honeywell Lyric' integration. Anyway, this automation includes a retry mechanism.

## Installation and configuration
1. Clone this repository.
2. Link or copy `suntopump.yaml` into `<ha_config_dir>/packages`.
3. Add `packages: !include_dir_named packages` under the `homeassistant:` section of your configuration.yaml:

```
homeassistant:
  packages: !include_dir_named packages
```

4. Edit the config section at the top of `suntopump.yaml` (entity ids and various preferences).
5. Restart Home Assistant.
6. Create a card with the inputs in this package (`SunToPump active`, etc) and sensors you'd like to monitor.
7. Use the `SunToPump setpoint max` and `SunToPump setpoint min` sliders to enter the desired setpoint range.
8. Toggle the `SunToPump active` input to activate/deactivate the automation.

## Boost
No sunshine today? Push the `SunToPump boost` slider to test the automation. This value is added to the available power. Note it will take some time for the setpoint to raise, but `suntopump_power_hint` and `suntopump_setpoint_hint` should slowly start increasing.

## Tunning the system
While the automation learns the heat pump's actual power behavior, the expected power input for temperature combinations that haven't been encountered yet is calculated using the following input numbers:

**SunToPump td_0w**\
Maximum temperature difference (room - outside) at which the heat pump doesn't need to work to keep the room temperature. E.g., 5°C, if the heat pump is still mostly idle when it's 15°C outside and 20°C inside.

**SunToPump power_td30**\
Heat pump's power consumption when the temperature difference is 30°C (e.g., -10°C outside, 20°C inside). You can make a guess, use the heat pump's maximum power input, or calculate an extrapolation: `power_td30 = power_td<TD> * (30 - td_0w) / (<TD> - td_0w)`. E.g., if `td_0w = 5`, and you have measured a power consumption of 800W when it's 5°C outside and 20°C inside (`TD = 15`), then `power_td30 = 800 * (30 - 5) / (15 - 5) = 2000W`.

**SunToPump power_raise1**\
Heat pump's (extra) power consumption when the room thermostat is set 1°C above the room temperature.

## Sensor chain
The target setpoint is the end result in a chain of template and statistics sensors. Monitoring these sensors can be useful when setting up the system.

**suntopump_available_power**\
Exported power plus heat pump's power input. Or in other words: Negative of the home consumption not counting the heat pump.

**suntopump_available_power_avg_short** and **suntopump_available_power_avg_long**\
Filtered available power. See `available_power_filter` in the configuration.

**suntopump_power_hint**\
How much power is currently desired for the heat pump to use. It's the minimum of the two previous filters.

**suntopump_setpoint_hint**\
Setpoint value corresponding to `suntopump_power_hint` in the power table for the current temperature conditions.

**suntopump_setpoint**\
Target setpoint. Filtered `suntopump_setpoint_hint`, rounding down to 0.5°C steps, and avoiding too frequent changes.

## Power table
In `suntopump.yaml` the structure of the power table is explained. The script `util/read_power_table.sh` can be used to print it; see instructions at the top.

Two additional template sensors are provided for monitoring purposes:

**suntopump_power_table_value**\
Power table value for current temperature conditions. Allows seeing how the power table is updated (i.e., how the system corrects its expectations for the current conditions).

**suntopump_power_to_raise**\
Shows the expected power consumption if the thermostat was raised 0.5°C. The setpoint can be raised when `suntopump_power_hint` reaches this value.
