# crow-i2c2midi
Simple crow library to send commands to the i2c2midi module.

Two versions are avilable:
1. Standalone implementation with range limits and docs: `i2c2midi.lua`
2. More compact version with more commands and example usage: `i2c2midi-compact.lua`

The first version hit memory limitations when I tried to add more commands, so I got
rid of the range checking and shortened the doc strings. 


## Basic Usage

From `druid` load and run the library with `r i2c2midi.lua`. Once loaded, you can call i2c2midi
ops via `ii.i2mi.{op_name}(arg1, arg2, ...)`.

The available commands can be viewed using `ii.i2m.help()`:
```lua
> ii.i2m.help()
panic()  -- Send MIDI off on all channels
time(channel, time_ms)  -- Set the time (ms) before note off
shift(channel, semitones)  -- Set note shift
note_reps(channel, repetitions)  -- Set note repetition
note_ratchets(channel, ratchets)  -- Set note ratcheting
note_on(channel, note, velocity)  -- Send note on
note_off(channel, note)  -- Send note off
play_note(channel, note, velocity, duration_ms)  -- Send note on with duration
play_chord(channel, chord, root, velocity)  -- Play with given root
chord_add(chord, note)  -- Add a note
chord_remove(chord, note)  -- Remove a note
chord_delete(chord, index)  -- Delete indexed note
chord_set(chord, index, note)  -- Set indexed note
chord_binary(chord, rev_binary)  -- Define chord using reverse binary
chord_clear(chord)  -- Clear all notes
chord_length(chord, length)  -- Set length (# notes)
chord_scale(chord, scale_chord)  -- Set scale of 1st chord to scale given by 2nd
chord_reversal(chord, reversed)  -- Set reversal
chord_rotation(chord, steps)  -- Set rotation
chord_transpose(chord, semitones)  -- Set transposition
chord_distort(chord, width, anchor)  -- Set distortion
chord_reflect(chord, width, anchor)  -- Set reflection
chord_inversion(chord, inversion)  -- Set inversion
chord_strum(chord, time_ms)  -- Set duration (ms) between notes
chord_vel_curve(chord, type, start_percent, end_percent)  -- Set velocity curve
chord_time_curve(chord, type, start_percent, end_percent)  -- Set time curve
chord_direction(chord, direction)  -- Set strum pattern
```

## Example

Here's a quick example that sets up, transforms, and plays a chord:

```lua
-- Set all channels time to 1 second
ii.i2m.time(0, 1000)

-- Define chord 1 to be minor triad using reverse binary
ii.i2m.chord_binary(1, "10010001")

-- Set the strum interval on chord 1 to 120ms
ii.i2m.chord_strum(1, 120)

-- Set the play direction to repeat the bass note
ii.i2m.chord_direction(1, 5)

-- Play chord 1 on channel 0, at note 60, with velocity 100
ii.i2m.play_chord(0, 1, 60, 100) 
```

## Limitations

This is work in progress and is mainly just a proof of concept for how to easily set up all the
op calls.

Current limitation include:
- No getters
- No default channels -- all ops that can use a channel must
- No buffer ops
- No MIDI CC
- No MIDI in

It is not clear how much of the full set of `i2c2midi` ops can be supported. The current
implementation is already close to the size limit for user script memory.
