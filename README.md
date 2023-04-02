# crow-i2c2midi
Simple crow library to send commands to the i2c2midi module.

## Basic Usage

From `druid` load and run the library with `r i2c2midi.lua`. Once loaded, you can call i2c2midi
ops via `i2m(op_name, arg1, arg2, ...)`.

For example,
```lua
-- Set all channels time to 1 second
i2m("time", 0, 1000)

-- Define chord 1 to be minor triad using reverse binary
i2m("c_b", 1, "10010001")

-- Set the strum interval on chord 1 to 30ms
i2m("c_str", 1, 30)

-- Play chord 1 on channel 0, at note 60, with velocity 100
i2m("chord", 0, 1, 60, 100) 
```

To see what arguments an op takes just use `i2m(op_name)` and the error message will print them.
Alternatively, you can just read the list of ops in the `I2M_OPS` variable.

## Limitations

This is work in progress and is mainly just a proof of concept for how to easily set up all the
op calls.

Current limitation include:
- No getters
- No default channels -- all ops that can use a channel must
- No buffer ops
- Incomplete chord transformations

None of these limitations are inherent, they are just due to a lack of time. I plan to address them all 
soon.
