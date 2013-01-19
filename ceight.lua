-- ceight; a proof of concept CHIP-8 emulator
--         written completely in Lua.

-- created by swyter; released under MIT-like terms.
  local opc=require'c8o'
  local bit=require'bit'
  local ffi=require'ffi'
  local vm=ffi.new([[
    struct{
      unsigned char vid[64*32];                                     // display resolution is 64×32 pixels, and color is monochrome
      unsigned char mem[0xfff];                                     // from 200h to FFFh, making for 3,584 bytes
      unsigned int v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,va,vb,vc,vd,ve,vf; // 16 8-bit data registers named from V0 to VF
      unsigned int i;                                               // the address register, which is named I, is 16 bits wide
    }
  ]])
  
  local mem_base=0x200

  print("Starting off...")
  
  local f = assert(io.open("R:\\Repositories\\ceight\\roms\\PONG", "rb"))
  if f then
    while true do
      local byte=f:read(1)
      c=(c or 0)+1
      if not byte or ((mem_base-1)+c)>0xfff then break end
      vm.mem[(mem_base-1)+c]=string.byte(byte)
    end
    print(string.format("ROM loaded... %d bytes",c))
    f:close()
  end
  
  
function reverse(t)
  local nt = {} -- new table
  local size = #t + 1
  for k,v in ipairs(t) do
    nt[size - k] = v
  end
  return nt
end

function toBits(num)
    local t={}
    while num>0 do
        rest=num%2
        t[#t+1]=rest
        num=(num-rest)/2
    end
    t = reverse(t)
    return table.concat(t)..("-"):rep(16-#t)
end

  f = assert(io.open("_disasm", "w"))
  --[[
  for x=0,c+1,2 do
  
    f:write(string.format("%02X | ", 0x200+x))
    
    hexcomp=bit.lshift(vm.mem[0x200+x],8)+vm.mem[0x200+x+1]
    f:write(string.format("%04X -> ", hexcomp))
    f:write(string.format("%s -> ",   toBits(hexcomp)))
    
    for op,desc in pairs(opc) do
      if bit.band(tonumber(op:gsub("[X|Y|N]","0"),16),hexcomp) ~=0 then
        f:write(op.."  ")
      end
    end
    
    
    
    f:write('\n')
  
  end]]
  
  test=0x6A02
  
  f:write(string.format("%04X", test))
  
  f:write((' '):rep(8)..toBits(test))
  f:write((' '):rep(8)..toBits(bit.band(test,0xF000)))
  f:write('  ')
  f:write('\n'..('-'):rep(58)..'\nOPCO  FLAG  BFLAG             BASE  BBASE             FITS\n')
  
  
    for op,desc in pairs(opc) do
        f:write(op)
        f:write('  ')
        mask=tonumber(op:gsub("[^(X|Y|N)]","F"):gsub("[X|Y|N]","0"),16)
        f:write(string.format("%04X", mask))
        f:write('  ')
        
        f:write(toBits(mask))
        f:write('  ')
        --f:write(toBits(bit.band(tonumber("6A02",16),mask)))
        
        base=bit.band(tonumber(op:gsub("[X|Y|N]","0"),16), mask)
        tesm=bit.band(test,                                mask)
        f:write(string.format("%04X", base))
        f:write('  ')
        f:write(toBits(base))

        --proc=bit.band(test,base)
        f:write('  ')
        f:write(toBits(tesm))
        f:write('  ')
        f:write(string.format("%04X",tesm))
        
        ok="  "..((tesm==base) and "OK" or "NO")

        f:write(ok..'\n')
    end
  
  f:close()
  
  