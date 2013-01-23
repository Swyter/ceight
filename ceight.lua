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
      unsigned int stk[16];                                         // stack for returning back from routines
      unsigned int v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,va,vb,vc,vd,ve,vf; // 16 8-bit data registers named from V0 to VF
      unsigned int v_dt,v_st;                                       // delay and sound timer
      unsigned int i;                                               // the address register, which is named I, is 16 bits wide
      unsigned int pc;                                              // the program counter
    }
  ]])
  
  local max_stak=0
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
      f:write(indent,('    '):rep(max_stak)..'[',tostring(key),']') 
      if type(value)=="table" then f:write(':\n') print_r(value,indent..'\t')
      else f:write(' = ',string.format("%X", tostring(value)),'\n') end
    end
  end
  
  f = assert(io.open("_disasm", "w"))

  
  opc['1NNN'].exec=function(...) arg=(...) f:write((" jumping to %x\n"):format(arg.n))
                                           vm.pc=arg.n-2
                                 end
  opc['6XNN'].exec=function(...) arg=(...) f:write((" setting V%X to %x\n"):format(arg.x,arg.n))
                                           vm["v"..("%x"):format(arg.x)]=arg.n
                                 end
  opc['ANNN'].exec=function(...) arg=(...) f:write((" setting I to %x\n"):format(arg.n))
                                           vm.i=arg.n
                                 end
  opc['DXYN'].exec=function(...) arg=(...) f:write((" drawn %d line sprite at (%d,%d) using I: 0x%x\n"):format(arg.n,arg.x,arg.y,vm.i))
                                 end
  opc['2NNN'].exec=function(...) arg=(...) f:write((" called routine at 0x%x\n"):format(arg.n))
                                           vm.stk[max_stak]=vm.pc
                                           vm.pc=arg.n-2
                                           max_stak=max_stak+1
                                 end
  opc['00EE'].exec=function(...) arg=(...) vm.pc=vm.stk[max_stak-1]
                                           f:write((" returns back to 0x%x (%d lvls of nesting)\n"):format(vm.pc,max_stak))
                                           max_stak=max_stak-1
                                 end
  opc['3XNN'].exec=function(...) arg=(...) if vm["v"..("%x"):format(arg.x)]==arg.n then
                                            f:write((" skipping the next instruction (V%X==%X)\n"):format(arg.x,arg.n))
                                            vm.pc=vm.pc+2
                                           else
                                            f:write((" don't skip anything (V%X(%X)!=%X)\n"):format(arg.x,vm["v"..("%x"):format(arg.x)],arg.n))
                                           end
                                 end
  opc['4XNN'].exec=function(...) arg=(...) if vm["v"..("%x"):format(arg.x)]~=arg.n then
                                            f:write((" skipping the next instruction (V%X!=%X)\n"):format(arg.x,arg.n))
                                            vm.pc=vm.pc+2
                                           else
                                            f:write((" don't skip anything (V%X(%X)==%X)\n"):format(arg.x,vm["v"..("%x"):format(arg.x)],arg.n))
                                           end
                                 end
  opc['FX07'].exec=function(...) arg=(...) f:write((" setting V%X to timer(%X)\n"):format(arg.x,vm.v_dt))
                                           vm["v"..("%x"):format(arg.x)]=vm.v_dt
                                 end
  opc['FX33'].exec=function(...) arg=(...) local binenc=string.format("%03d",tostring(vm["v"..("%x"):format(arg.x)]))
                                           f:write((" saving V%X(%s) at I(0x%X) encoding it as bin\n"):format(arg.x,binenc,vm.i))
                                           vm.mem[vm.i+0]=tonumber(binenc:sub(1,1))
                                           vm.mem[vm.i+1]=tonumber(binenc:sub(2,2))
                                           vm.mem[vm.i+2]=tonumber(binenc:sub(3,3))
                                 end
  opc['CXNN'].exec=function(...) arg=(...) local rnd=math.random(0,0xfff)
                                           f:write((" saving random value (%s) at V%X with mask %X\n"):format(rnd,arg.x,arg.n))
                                           vm["v"..("%x"):format(arg.x)]=bit.band(rnd,arg.n)
                                 end
  opc['FX65'].exec=function(...) arg=(...) f:write((" filling V0 to V%X from mem starting at 0x%X\n"):format(arg.x,vm.i))
                                           for i=0,arg.x do
                                            vm["v"..("%x"):format(i)]=vm.mem[vm.i+i]
                                           end
                                 end
  opc['FX29'].exec=function(...) arg=(...) f:write((" setting I pointing to the glyph in V%X(%x)\n"):format(arg.x,vm["v"..("%x"):format(arg.x)]))
                                           vm.i=(vm["v"..("%x"):format(arg.x)])*5
                                 end
  opc['FX18'].exec=function(...) arg=(...) f:write((" setting sound timer to V%X(%x)\n"):format(arg.x,vm["v"..("%x"):format(arg.x)]))
                                           vm.v_st=vm["v"..("%x"):format(arg.x)]
                                 end
  opc['8XY2'].exec=function(...) arg=(...) local band=bit.band(vm["v"..("%x"):format(arg.x)],
                                                               vm["v"..("%x"):format(arg.y)])
                                           f:write((" setting V%X to V%X(%x) and V%X(%x)=%x\n"):format(arg.x, arg.x, vm["v"..("%x"):format(arg.x)], arg.y, vm["v"..("%x"):format(arg.y)], band))
                                           vm["v"..("%x"):format(arg.x)]=band
                                 end
  opc['7XNN'].exec=function(...) arg=(...) local sum=vm["v"..("%x"):format(arg.x)]+arg.n
                                           f:write((" setting V%X to V%X(%x)+(%x)=%x\n"):format(arg.x, arg.x, vm["v"..("%x"):format(arg.x)], arg.n, sum))
                                           vm["v"..("%x"):format(arg.x)]=sum
                                 end
  opc['8XY4'].exec=function(...) arg=(...) local sum=vm["v"..("%x"):format(arg.x)]+vm["v"..("%x"):format(arg.y)]
                                           f:write((" setting V%X to V%X(%x)+V%X(%x)=%x\n"):format(arg.x, arg.x, vm["v"..("%x"):format(arg.x)], arg.y, vm["v"..("%x"):format(arg.y)], sum))
                                           vm["v"..("%x"):format(arg.x)]=sum
                                 end
  opc['8XY0'].exec=function(...) arg=(...) f:write((" setting V%X to V%X(%x)\n"):format(arg.x, arg.y, vm["v"..("%x"):format(arg.y)]))
                                           vm["v"..("%x"):format(arg.x)]=vm["v"..("%x"):format(arg.y)]
                                 end

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
      opc[op]['exec']=opc[op]['exec'] or function(...) f:write(" stub!\n") print_r(...,(" "):rep(17)) end
      
  end
  
  --init program counter to base address
  vm.pc=mem_base
  
  --run the vm
  while true do
      if vm.pc>mem_base+c or vm.pc<mem_base then break end --out of bounds!
      
      local ba=vm.mem[vm.pc]
      local bb=vm.mem[vm.pc+1]
      
      local by=bit.lshift(ba,8)+bb
      
      for op,opn in pairs(opc) do
        if bit.band(by,opn.mask)==opn.base then
          
          local arg={}
          for nm,ay in pairs(opn.args) do arg[nm]=unpack(by,ay.mask,ay.shift) end
          
          f:write(string.format("%4X| %4X  %s%5s", vm.pc, by, ('   |'):rep(max_stak), opn.mne ))
          opn.exec(arg)
          
          break end
      end

      vm.pc = vm.pc + 2
  end
  
  f:close()