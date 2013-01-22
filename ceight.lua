-- ceight; a proof of concept CHIP-8 emulator
--         written completely in Lua.

-- created by swyter; released under MIT-like terms.
  local opc=require'c8o'
  local bit=require'bit'
  local ffi=require'ffi'
  local vm=ffi.new([[
    struct{
      unsigned char vid[64*32];                                     // display resolution is 64з32 pixels, and color is monochrome
      unsigned char mem[0xfff];                                     // from 200h to FFFh, making for 3,584 bytes
      unsigned int v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,va,vb,vc,vd,ve,vf; // 16 8-bit data registers named from V0 to VF
      unsigned int i;                                               // the address register, which is named I, is 16 bits wide
    }
  ]])

  local mem_base=0x200
  
  --predefined array of sprites (glyphs)
  vm.mem={ 0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
           0x20, 0x60, 0x20, 0x20, 0x70, -- 1
           0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
           0xF0, 0x10, 0xF0, 0x10, 0xF0, -- 3
           0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
           0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
           0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
           0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
           0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
           0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
           0xF0, 0x90, 0xF0, 0x90, 0x90, -- A
           0xE0, 0x90, 0xE0, 0x90, 0xE0, -- B
           0xF0, 0x80, 0x80, 0x80, 0xF0, -- C
           0xE0, 0x90, 0x90, 0x90, 0xE0, -- D
           0xF0, 0x80, 0xF0, 0x80, 0xF0, -- E
           0xF0, 0x80, 0xF0, 0x80, 0x80} -- F

  print("Starting off...")
  
  --load rom
  local f = assert(io.open("roms\\PONG", "rb"))
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
  function buildargs(base,start,len)
    local  num=tonumber(('0'):rep(start)..
                        ('F'):rep(len)..
                        ('0'):rep((4)-(start+len)), 16)
                                       
    return {['mask']=num, ['shift']=((4)-(start+len))*4}
  end
  function unpack(base,mask,shift)
    local num=bit.band(base, mask)
    return bit.rshift(num, shift)
  end
  function print_r (t, indent) -- alt version, abuse to http://richard.warburton.it
    local indent=indent or ''
    for key,value in pairs(t) do
      f:write(indent,'[',tostring(key),']') 
      if type(value)=="table" then f:write(':\n') print_r(value,indent..'\t')
      else f:write(' = ',string.format("%X", tostring(value)),'\n') end
    end
  end
  
  f = assert(io.open("_disasm", "w"))

  --preprocess opcodes
  for op,opn in pairs(opc) do
  
      local mask=         tonumber(op:gsub("[^(X|Y|N)]","F"):gsub("[X|Y|N]","0"),16)
      local base=bit.band(tonumber(op:gsub(  "[X|Y|N]", "0"),                    16), mask)
      
      local args={}
      if op:find("^.X..$")       then args.x=(buildargs(by,1,1)) end
      if op:find("^..Y.$")       then args.y=(buildargs(by,2,1)) end
      if op:find("^.NNN$")       then args.n=(buildargs(by,1,3)) end
      if op:find("^.[^N]NN$")    then args.n=(buildargs(by,2,2)) end
      if op:find("^.[^N][^N]N$") then args.n=(buildargs(by,3,1)) end

      opc[op]['base']=base
      opc[op]['mask']=mask
      opc[op]['args']=args
      opc[op]['exec']=function(...) print_r(...,(" "):rep(17)) end
      
  end
  
  --init program counter to base address
  local pc=mem_base
  
  --run the vm
  while true do
      if pc>mem_base+c or pc<mem_base then break end --out of bounds!
      
      local ba=vm.mem[pc]
      local bb=vm.mem[pc+1]
      
      local by=bit.lshift(ba,8)+bb
      
      for op,opn in pairs(opc) do
        if bit.band(by,opn.mask)==opn.base then
          
          local arg={}
          for nm,ay in pairs(opn.args) do arg[nm]=unpack(by,ay.mask,ay.shift) end
          
          f:write(string.format("%4X| %4X  %5s\n", pc, by, opn.mne ))
          opn.exec(arg)
          
          break end
      end

      pc = pc + 2
  end
  
  f:close()
  
  --for _=0,32/2 do
  --  for _=0,64/2 do
  --     io.write("мп")
  --  end
  --  io.write("\n")
  --end