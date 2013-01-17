-- ceight; a proof of concept CHIP-8 emulator
--         written completely in Lua.

-- created by swyter; released under MIT-like terms.

  ffi=require'ffi'
  mem=ffi.new('unsigned char[?]', 0xfff)

  print("Starting off...")
  
  local f = assert(io.open("R:\\Repositories\\ceight\\roms\\PONG", "rb"))
  if f then
    while true do
      local byte=f:read(1)
      c=(c or 0)+1
      if not byte or ((0x200-1)+c)>0xfff then break end
      print(string.format("%02X ",string.byte(byte)),c)
      mem[(0x200-1)+c]=string.byte(byte)
    end
    print("ROM loaded...")
  end

  
    local t=0
    while true do
      if (0x200+t)>(0x200+c) then break end
      for b=0,9 do
        io.write(string.format("%02X ", mem[0x200+t+b]))
      end
      io.write("\n")
      t=t+10
    end