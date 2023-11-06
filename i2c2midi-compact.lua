--- i2c2midi
-- Simple Crow -> i2c2midi interface. Initial idea from this post: 
-- https://llllllll.co/t/i2c2midi-a-diy-module-that-translates-i2c-to-midi/40950/399
--
-- Current limitations: No buffer ops, no get ops, no MIDI CC
-- Also almost at limit of user script memory on Crow.
-- 
-- Author: Mark Reid <mark@reid.name>

-- Example script to use i2c2midi
function run()
  tl = timeline
  s = sequins

  t1 = s{.2, .3, .5}
  m1 = s{0, 7, 12} + 36
  v1 = s{40, 80, 120}
  d1 = s{50, 100}
  tl.loop{t1, {ii.i2m.play_note, 0, m1, v1, d1}}

  t2 = s{1.5, 2.5}
  m2 = s{0, 3, 5, 9, 10} + 60
  v2 = s{70, 100}
  d2 = s{200, 100}
  tl.loop{t2, {ii.i2m.play_note, 0, m2, v2, d2}}

  	
  t3 = s{4, 3, 1}
  m3 = s{14, 7, 12, 5} + 72
  v3 = s{50, 60}
  d3 = s{2000, 1000}
  tl.loop{t3, {ii.i2m.play_note, 0, m3, v3, d3}}

  output[1].action = pulse(0.1, 5, 1)
  c = tl.loop{s{0.225, 0.275}, {output[1]}}
  
  ii.jf.mode(1)
  l1 = tl.loop{1, {ii.jf.play_note, s{0, 7, 3, 14, 10}/12, 1.5}}
  l2 = tl.loop{1.5, {ii.jf.play_note, s{12, 15, 10, 7}/12, 1.5}}
end

function init ()
  -- Set up `ii` style hooks so that i2c2midi functions look like others
  ii.i2m = {}
  ii.i2m.help = function ()
    for _, cmd in ipairs(I2M_DEF.commands) do
      print(cmd_show(cmd))
    end
  end
  
  for _, cmd in ipairs(I2M_DEF.commands) do
    ii.i2m[cmd.name] = cmd_fn(I2M_DEF.i2c_address[1], cmd)
  end

  -- Start performance script
  run()
end

-- Integer to byte conversion
function u8 (v) return string.pack("B", v) end    -- unsigned byte
function s8 (v) return string.pack("b", v) end    -- signed byte
function u16 (v) return string.pack(">H", v) end  -- unsigned short (2 bytes)
-- Reverse binary string to unsigned short
function ru16 (v) return u16(tonumber(v:reverse(), 2)) end

-- A `crow/lua/ii` style definition table
I2M_DEF = 
{ module_name  = 'i2c2midi'
, manufacturer = 'attowatt'
, i2c_address  = {0x3f}
, lua_name     = 'i2m'
, commands     = 
  { { name = 'panic'
    , cmd  = 22
    , docs = 'Send MIDI off on all channels'
    , args = { }
    }
  , { name = 'time'
    , cmd  = 2
    , docs = 'Set the time (ms) before note off'
    , args = { { 'channel', u8 }
             , { 'time_ms', u16 }
             }
    }
  , { name = 'shift'
    , cmd  = 4
    , docs = 'Set note shift'
    , args = { { 'channel', u8 }
             , { 'semitones', s8 }
             }
    }
  -- Notes
  , { name = 'note_reps'
    , cmd  = 6
    , docs = 'Set note repetition'
    , args = { { 'channel', u8 }
             , { 'repetitions', u8 }
             }
    }
  , { name = 'note_ratchets'
    , cmd  = 8
    , docs = 'Set note ratcheting'
    , args = { { 'channel', u8 }
             , { 'ratchets', u8 }
             }
    }
  , { name = 'note_on'
    , cmd  = 20
    , docs = 'Send note on'
    , args = { { 'channel', u8 }
             , { 'note', u8 }
             , { 'velocity', u8 }
             }
    }
  , { name = 'note_off'
    , cmd  = 21
    , docs = 'Send note off'
    , args = { { 'channel', u8 }
             , { 'note', u8 }
             }
    }
  , { name = 'play_note'
    , cmd  = 23
    , docs = 'Send note on with duration'
    , args = { { 'channel', u8 }
             , { 'note', u8 }
             , { 'velocity', u8 }
             , { 'duration_ms', u16 }
             }
    }

  -- Chords
  , { name = 'play_chord'
    , cmd  = 30
    , docs = 'Play with given root'
    , args = { { 'channel', u8 }
             , { 'chord', u8 }
             , { 'root', u8 }
             , { 'velocity', u8 }
             }
    }
  , { name = 'chord_add'
    , cmd  = 31
    , docs = 'Add a note'
    , args = { { 'chord', u8 }
             , { 'note', s8 }
             }
    }
  , { name = 'chord_remove'
    , cmd  = 32
    , docs = 'Remove a note'
    , args = { { 'chord', u8 }
             , { 'note', s8 }
             }
    }
  , { name = 'chord_delete'
    , cmd  = 153
    , docs = 'Delete indexed note'
    , args = { { 'chord', u8 }
             , { 'index', u8 }
             }
    }
  , { name = 'chord_set'
    , cmd  = 154
    , docs = 'Set indexed note'
    , args = { { 'chord', u8 }
             , { 'index', u8 }
             , { 'note', s8 }
             }
    }
  , { name = 'chord_binary'
    , cmd  = 159
    , docs = 'Define chord using reverse binary'
    , args = { { 'chord', u8 }
             , { 'rev_binary', ru16, nil }
             }
    }
  , { name = 'chord_clear'
    , cmd  = 33
    , docs = 'Clear all notes'
    , args = { { 'chord', u8 }
             }
    }
  , { name = 'chord_length'
    , cmd  = 35
    , docs = 'Set length (# notes)'
    , args = { { 'chord', u8 }
             , { 'length', u8 }
             }
    }
  , { name = 'chord_scale'
    , cmd  = 158
    , docs = 'Set scale of 1st chord to scale given by 2nd'
    , args = { { 'chord', u8 }
             , { 'scale_chord', u8 }
             }
    }
  , { name = 'chord_reversal'
    , cmd  = 39
    , docs = 'Set reversal'
    , args = { { 'chord', u8 }
             , { 'reversed', u8 }
             }
    }
  , { name = 'chord_rotation'
    , cmd  = 156
    , docs = 'Set rotation'
    , args = { { 'chord', u8 }
             , { 'steps', s8 }
             }
    }
  , { name = 'chord_transpose'
    , cmd  = 160
    , docs = 'Set transposition'
    , args = { { 'chord', u8 }
             , { 'semitones', s8 }
             }
    }
  , { name = 'chord_distort'
    , cmd  = 161
    , docs = 'Set distortion'
    , args = { { 'chord', u8 }
             , { 'width', s8 }
             , { 'anchor', u8 }
             }
    }
  , { name = 'chord_reflect'
    , cmd  = 162
    , docs = 'Set reflection'
    , args = { { 'chord', u8 }
             , { 'width', s8 }
             , { 'anchor', u8 }
             }
    }
  , { name = 'chord_inversion'
    , cmd  = 37
    , docs = 'Set inversion'
    , args = { { 'chord', u8 }
             , { 'inversion', s8 }
             }
    }
  , { name = 'chord_strum'
    , cmd  = 151
    , docs = 'Set duration (ms) between notes'
    , args = { { 'chord', u8 }
             , { 'time_ms', u16 }
             }
    }
  , { name = 'chord_vel_curve'
    , cmd  = 163
    , docs = 'Set velocity curve'
    , args = { { 'chord', u8 }
             , { 'type', u8 }
             , { 'start_percent', u16 }
             , { 'end_percent', u16 }
             }
    }
  , { name = 'chord_time_curve'
    , cmd  = 164
    , docs = 'Set time curve'
    , args = { { 'chord', u8 }
             , { 'type', u8 }
             , { 'start_percent', u16 }
             , { 'end_percent', u16 }
             }
    }
  , { name = 'chord_direction'
    , cmd  = 165
    , docs = 'Set strum pattern'
    , args = { { 'chord', u8 }
             , { 'direction', u8 }
             }
    }

  -- MIDI CC
  , { name = 'midi_cc'
    , cmd  = 40
    , docs = 'Send MIDI CC value'
    , args = { { 'channel', u8 }
             , { 'cc', u8 }
             , { 'value', u8 }
             }
    }
  , { name = 'midi_slew'
    , cmd  = 44
    , docs = 'Set MIDI CC slew'
    , args = { { 'channel', u8 }
             , { 'cc', u8 }
             , { 'slew_ms', u16 }
             }
    }
  }
}

-- Pretty print a command
function cmd_show (cmd)
  local arg_names = {}
  for i, arg in ipairs(cmd.args) do arg_names[i] = arg[1] end
  return cmd.name..'('..table.concat(arg_names, ', ')..')  -- '..cmd.docs
end

-- Convert a command's opcode and arguments to bytes
function cmd_bytes(cmd, vals)
  if #cmd.args ~= #vals then error('Wrong number of args!\nUsage: '..cmd_show(cmd)) end
  local data = u8(cmd.cmd)
  for i, arg in ipairs(cmd.args) do
    local v = vals[i]
    local name, conv = table.unpack(arg)
    data = data .. conv(v)
  end
  return data
end

-- Build a function from `cmd` that encodes arguments and calls `ii.raw`
function cmd_fn (addr, cmd)
  local function fn (...)
    local vals = {...}
    local data = cmd_bytes(cmd, vals)
    ii.raw(addr, data)
  end
  
  return fn
end
