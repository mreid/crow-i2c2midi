--- i2c2midi
-- Simple Crow -> i2c2midi interface. Initial idea from this post: 
-- https://llllllll.co/t/i2c2midi-a-diy-module-that-translates-i2c-to-midi/40950/399
-- 
-- i2c2midi opcodes and argument lists from:
-- https://github.com/attowatt/i2c2midi/blob/main/firmware/i2c2midi_firmware/ops.ino 
--
-- Author: Mark Reid <mark@reid.name>

-- Address of i2c2midi device on i2c bus
I2C2MIDI_ADDR = 0x3F

-- Integer to byte conversion
local function u8 (v) return string.pack("B", v) end    -- unsigned byte
local function s8 (v) return string.pack("b", v) end    -- signed byte
local function u16 (v) return string.pack(">H", v) end  -- unsigned short (2 bytes)
-- Reverse binary string to unsigned short
local function ru16 (v) return u16(tonumber(v:reverse(), 2)) end

-- Variables and their byte converters, and ranges
local VARS = {
  channel   = {u8,   {0, 32}},
  note      = {u8,   {0, 127}},
  note_rel  = {s8,   {-127, 127}},
  steps     = {s8,   {-127, 127}},
  velocity  = {u8,   {0, 127}},
  reps      = {u8,   {1, 127}},
  chord     = {u8,   {0, 8}},
  length    = {u8,   {1, 8}},
  index     = {u8,   {0, 7}},
  rev_bin   = {ru16, nil},
  anchor    = {u8,   {0, 16}},
  inversion = {s8,   {-32, 32}},
  reversed  = {u8,   {0, 127}},
  time_ms   = {u16,  {0, 32767}},
  curve     = {u8,   {0, 5}},
  direction = {u8,   {0, 8}},
  control   = {u8,   {0, 127}},
  cc_value  = {u8,   {0, 127}},
}

-- i2c2midi ops: name => {opcode, args}
I2M_OPS = {
  -- Settings
  time    = {2, {"channel", "time_ms"}},
  shift   = {4, {"channel", "note_rel"}},
  rep     = {6, {"channel", "reps"}},
  rat     = {8, {"channel", "reps"}},
  -- Notes
  note    = {20, {"channel", "note", "velocity"}},
  note_o  = {21, {"channel"}},
  panic   = {22, {}},
  nt      = {23, {"channel", "note", "velocity", "time_ms"}},
  -- Chords
  chord   = {30, {"channel", "chord", "note", "velocity"}},
  c_add   = {31, {"chord", "note_rel"}},
  c_rm    = {32, {"chord", "note_rel"}},
  c_clr   = {33, {"chord"}},
  c_l     = {35, {"chord", "length"}},
  c_inv   = {37, {"chord", "inversion"}},
  c_rev   = {39, {"chord", "reversed"}},
  c_rot   = {156,{"chord", "steps"}},
  c_str   = {151,{"chord", "time_ms"}},
  c_ins   = {152,{"chord", "index", "note_rel"}},
  c_del   = {153,{"chord", "index"}},
  c_set   = {154,{"chord", "index", "note_rel"}},
  c_sc    = {158,{"chord", "chord"}},
  c_b     = {159,{"chord", "rev_bin"}},
  -- CC
  cc      = {40, {"control", "cc_value"}}, 
}

-- Convert argument value to bytes 
local function bytes(arg, v)
  local conv, range = table.unpack(VARS[arg])
  -- No range check on nil range
  if range == nil then return conv(v) end
  -- Range check
  local lo, hi = table.unpack(range)
  if (v < lo) or (v > hi) then error(arg .. " value " .. v .. " not in [" .. lo .. "," .. hi .."]") end
  -- Convert value
  return conv(v)
end

-- Call i2c2midi op with `op_name` and arguments
function i2m (op_name, ...)
  if I2M_OPS[op_name] == nil then error("Unknown op \"" .. op_name .. "\"") end
  local vals = {...}
  local op, args = table.unpack(I2M_OPS[op_name])
  if #args ~= #vals then error("Usage: i2m(\"" .. op_name .. "\"," .. table.concat(args, ",") .. ")") end
  -- Convert op + args to data
  local tx = u8(op)
  for i, arg in ipairs(args) do tx = tx .. bytes(arg, vals[i]) end
  -- Send to i2c2midi
  ii.raw(I2C2MIDI_ADDR, tx)
end

-- For debugging hex strings
function string.hex(str)
  return (str:gsub(".", function(char) return "\\x" .. string.format("%2x", char:byte()) end))
end

