--- i2c2midi
-- Simple Crow -> i2c2midi interface. Initial idea from this post: 
-- https://llllllll.co/t/i2c2midi-a-diy-module-that-translates-i2c-to-midi/40950/399
--
-- Current limitations: No buffer ops, no get ops, no MIDI CC
-- Also almost at limit of user script memory on Crow.
-- 
-- Author: Mark Reid <mark@reid.name>

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
    , args = { { 'channel', u8, {0, 32} }
             , { 'time_ms', u16, {0, 32767} }
             }
    }
  , { name = 'shift'
    , cmd  = 4
    , docs = 'Set note shift'
    , args = { { 'channel', u8, {0, 32} }
             , { 'semitones', s8, {-127, 127} }
             }
    }
  -- Notes
  , { name = 'note_reps'
    , cmd  = 6
    , docs = 'Set note repetition'
    , args = { { 'channel', u8, {0, 32} }
             , { 'repetitions', u8, {1, 127} }
             }
    }
  , { name = 'note_ratchets'
    , cmd  = 8
    , docs = 'Set note ratcheting'
    , args = { { 'channel', u8, {0, 32} }
             , { 'ratchets', u8, {1, 127} }
             }
    }
  , { name = 'note_on'
    , cmd  = 20
    , docs = 'Send note on'
    , args = { { 'channel', u8, {0, 32} }
             , { 'note', u8, {0, 127} }
             , { 'velocity', u8, {1, 127} }
             }
    }
  , { name = 'note_off'
    , cmd  = 21
    , docs = 'Send note off'
    , args = { { 'channel', u8, {0, 32} }
             , { 'note', u8, {0, 127} }
             }
    }
  , { name = 'play_note'
    , cmd  = 23
    , docs = 'Send note on with duration'
    , args = { { 'channel', u8, {0, 32} }
             , { 'note', u8, {0, 127} }
             , { 'velocity', u8, {1, 127} }
             , { 'duration_ms', u16, {0, 32767} }
             }
    }
  -- Chords
  , { name = 'play_chord'
    , cmd  = 30
    , docs = 'Play with given root'
    , args = { { 'channel', u8, {0, 32} }
             , { 'chord', u8, {0, 8} }
             , { 'root', u8, {0, 127} }
             , { 'velocity', u8, {1, 127} }
             }
    }
  , { name = 'chord_add'
    , cmd  = 31
    , docs = 'Add a note'
    , args = { { 'chord', u8, {0, 8} }
             , { 'note', s8, {-127, 127} }
             }
    }
  , { name = 'chord_remove'
    , cmd  = 32
    , docs = 'Remove a note'
    , args = { { 'chord', u8, {0, 8} }
             , { 'note', s8, {-127, 127} }
             }
    }
  , { name = 'chord_delete'
    , cmd  = 153
    , docs = 'Delete indexed note'
    , args = { { 'chord', u8, {0, 8} }
             , { 'index', u8, {0, 7} }
             }
    }
  , { name = 'chord_set'
    , cmd  = 154
    , docs = 'Set indexed note'
    , args = { { 'chord', u8, {0, 8} }
             , { 'index', u8, {0, 7} }
             , { 'note', s8, {-127, 127} }
             }
    }
  , { name = 'chord_binary'
    , cmd  = 159
    , docs = 'Define chord using reverse binary'
    , args = { { 'chord', u8, {0, 8} }
             , { 'rev_binary', ru16, nil }
             }
    }
  , { name = 'chord_clear'
    , cmd  = 33
    , docs = 'Clear all notes'
    , args = { { 'chord', u8, {0, 8} }
             }
    }
  , { name = 'chord_length'
    , cmd  = 35
    , docs = 'Set length (# notes)'
    , args = { { 'chord', u8, {0, 8} }
             , { 'length', u8, {1, 127} }
             }
    }
  , { name = 'chord_scale'
    , cmd  = 158
    , docs = 'Set scale of 1st chord to scale given by 2nd'
    , args = { { 'chord', u8, {0, 8} }
             , { 'scale_chord', u8, {0, 8} }
             }
    }
  , { name = 'chord_reversal'
    , cmd  = 39
    , docs = 'Set reversal'
    , args = { { 'chord', u8, {0, 8} }
             , { 'reversed', u8, {0, 127} }
             }
    }
  , { name = 'chord_rotation'
    , cmd  = 156
    , docs = 'Set rotation'
    , args = { { 'chord', u8, {0, 8} }
             , { 'steps', s8, {-127, 127} }
             }
    }
  , { name = 'chord_transpose'
    , cmd  = 160
    , docs = 'Set transposition'
    , args = { { 'chord', u8, {0, 8} }
             , { 'semitones', s8, {-127, 127} }
             }
    }
  , { name = 'chord_distort'
    , cmd  = 161
    , docs = 'Set distortion'
    , args = { { 'chord', u8, {0, 8} }
             , { 'width', s8, {-127, 127} }
             , { 'anchor', u8, {0, 16} }
             }
    }
  , { name = 'chord_reflect'
    , cmd  = 162
    , docs = 'Set reflection'
    , args = { { 'chord', u8, {0, 8} }
             , { 'width', s8, {-127, 127} }
             , { 'anchor', u8, {0, 16} }
             }
    }
  , { name = 'chord_inversion'
    , cmd  = 37
    , docs = 'Set inversion'
    , args = { { 'chord', u8, {0, 8} }
             , { 'inversion', s8, {-32, 32} }
             }
    }
  , { name = 'chord_strum'
    , cmd  = 151
    , docs = 'Set duration (ms) between notes'
    , args = { { 'chord', u8, {0, 8} }
             , { 'time_ms', u16, {0, 32767} }
             }
    }
  , { name = 'chord_vel_curve'
    , cmd  = 163
    , docs = 'Set velocity curve'
    , args = { { 'chord', u8, {0, 8} }
             , { 'type', u8, {0, 5} }
             , { 'start_percent', u16, {0, 32767} }
             , { 'end_percent', u16, {0, 32767} }
             }
    }
  , { name = 'chord_time_curve'
    , cmd  = 164
    , docs = 'Set time curve'
    , args = { { 'chord', u8, {0, 8} }
             , { 'type', u8, {0, 5} }
             , { 'start_percent', u16, {0, 32767} }
             , { 'end_percent', u16, {0, 32767} }
             }
    }
  , { name = 'chord_direction'
    , cmd  = 165
    , docs = 'Set strum pattern'
    , args = { { 'chord', u8, {0, 8} }
             , { 'direction', u8, {0, 8} }
             }
    }
  }
}


function init ()
  -- Set up `ii` style hooks so that i2c2midi functions look like others
  ii.i2m = {}
  
  for _, cmd in ipairs(I2M_DEF.commands) do
    print(cmd_show(cmd))
    ii.i2m[cmd.name] = cmd_fn(I2M_DEF.i2c_address[1], cmd)
  end
end

-- Pretty print a command
function cmd_show (cmd)
  local arg_names = {}
  for i, arg in ipairs(cmd.args) do arg_names[i] = arg[1] end
  return cmd.name..'('..table.concat(arg_names, ', ')..')\n-- '..cmd.docs
end

-- Convert a command's opcode and arguments to bytes
function cmd_bytes(cmd, vals)
  if #cmd.args ~= #vals then error('Wrong number of args!\nUsage: '..cmd_show(cmd)) end
  local data = u8(cmd.cmd)
  for i, arg in ipairs(cmd.args) do
    local v = vals[i]
    local name, conv, range = table.unpack(arg)
    if range == nil then 
      -- No range check on nil range
      data = data .. conv(v)
    else
      -- Range check
      local lo, hi = table.unpack(range)
      if (v < lo) or (v > hi) then error(name.."="..v.." not in ["..lo..","..hi.."]") end
      data = data .. conv(v)
    end
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
