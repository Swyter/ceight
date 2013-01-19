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
  function unpack(base,start,len)
    local  num=bit.band(base, tonumber(('0'):rep(start)..
                                       ('F'):rep(len)..
                                       ('0'):rep((4)-(start+len)), 16))
                                       
    return string.format("%X", bit.rshift(num, ((4)-(start+len))*4))
  end
  
  f = assert(io.open("_disasm", "w"))

  --preprocess opcodes
  for op,opn in pairs(opc) do
  
      mask=tonumber(op:gsub("[^(X|Y|N)]","F"):gsub("[X|Y|N]","0"),16)
      base=bit.band(tonumber(op:gsub("[X|Y|N]","0"),16), mask)

      opc[op]['base']=base
      opc[op]['mask']=mask
      opc[op]['exec']=function(op, by) arg=''
          if op:find("^.X..$")       then arg=arg..(", x·"..unpack(by,1,1)) end
          if op:find("^..Y.$")       then arg=arg..(", y·"..unpack(by,2,1)) end
          if op:find("^.NNN$")       then arg=arg..(", n·"..unpack(by,1,3)) end
          if op:find("^.[^N]NN$")    then arg=arg..(", n·"..unpack(by,2,2)) end
          if op:find("^.[^N][^N]N$") then arg=arg..(", n·"..unpack(by,3,1)) end
      end
      
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
          opn.exec(op,by)
          f:write(string.format("%4X| %4X  %5s%s", pc, by, opn.me, arg))
          f:write((' '):rep(16-(arg:len() or 0))..' ;'..opn.desc..'\n')
          break end
      end

      pc = pc + 2
  end
  
  f:close()
  
  