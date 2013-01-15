-- ceight; a proof of concept CHIP-8 emulator
--         written completely in Lua.

-- created by swyter; released under MIT-like terms.

ffi=require'ffi'
mem=ffi.new('uint8_t[?]', 0xFFF)
stk=ffi.new('uint8_t[?]', 0xFFF)

  local f = assert(io.open("R:\\Repositories\\ceight\\roms\\PONG", "rb"))
  while true do
    local bytes = f:read()
    if not bytes then break end
    mem=bytes
  end
  
  a=0
  while 1 do
    for i=1,32 do
    io.write(string.rep((i%2==a and "Û " or " Û"),60/2).."\n")
    end
    
    print(">>"..string.byte(io.read(1)))
    a=not a
  end