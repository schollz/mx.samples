-- superkeys v0.0.0
-- sample player
--
-- llllllll.co/t/superkeys
--

superkeys=include("superkeys/lib/superkeys")

engine.name="Superkeys"
skeys=nil

function init()
  skeys=superkeys:new()
  -- lets add files
  files=list_files(_path.code.."superkeys/samples/piano/")
  for _,fname in ipairs(files) do
    if string.find(fname,".wav") then
      -- print("adding "..fname)
      pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      local foo=split_str(filename,".")
      velocity_range={45,80}
      if foo[2]=="pp" then
        velocity_range={0,45}
      elseif foo[2]=="ff" then
        velocity_range={80,127}
      end
      local midi_value=foo[3]
      skeys:add({name="piano",filename=fname,midi=midi_value,velocity_range=velocity_range})
    end
  end
  -- files=list_files(_path.code.."superkeys/samples/marimba/")
  -- for _,fname in ipairs(files) do
  --   if string.find(fname,".wav") then
  --     -- print("adding "..fname)
  --     pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  --     local foo=split_str(filename,".")
  --     local midi_value=foo[3]
  --     skeys:add{name="marimba",filename=fname,midi=tonumber(midi_value)}
  --   end
  -- end
  -- files=list_files(_path.code.."superkeys/samples/vibraphone/")
  -- for _,fname in ipairs(files) do
  --   if string.find(fname,".wav") then
  --     -- print("adding "..fname)
  --     pathname,filename,ext=string.match(fname,"(.-)([^\\/]-%.?([^%.\\/]*))$")
  --     local foo=split_str(filename,".")
  --     local midi_value=foo[3]
  --     skeys:add{name="vibraphone",filename=fname,midi=tonumber(midi_value)}
  --   end
  -- end
  print("added files")
  m = midi.connect(3)
  m.event = function(data) 
    tab.print(data) 
    if data[1]==144 then 
      skeys:on({name="piano",midi=data[2],velocity=data[3]})
    elseif data[1]==128 then 
      skeys:off({name="piano",midi=data[2]})
    end
  end

  clock.run(redraw_clock) -- start the grid redraw clock
end

function enc(k,d)

end

function key(k,z)
  if z==1 then 
    skeys:on({name="piano",midi=60,velocity=60})
  elseif z==0 then
    skeys:off({name="piano",midi=60})
  end
end

function redraw_clock() -- our grid redraw clock
  while true do -- while it's running...
    clock.sleep(1/30) -- refresh
    redraw()
  end
end

function redraw()
  screen.clear()
  

  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
function list_files(d,recurisve)
  if recursive==nil then
    recursive=false
  end
  return _list_files(d,{},recursive)
end

function _list_files(d,files,recursive)
  -- list files in a flat table
  if d=="." or d=="./" then
    d=""
  end
  if d~="" and string.sub(d,-1)~="/" then
    d=d.."/"
  end
  folders={}
  if recursive then
    local cmd="ls -ad "..d.."*/ 2>/dev/null"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      if not (string.match(s,"ls: ") or s=="../" or s=="./") then
        files=list_files(s,files,recursive)
      end
    end
  end
  do
    local cmd="ls -p "..d.." | grep -v /"
    local f=assert(io.popen(cmd,'r'))
    local out=assert(f:read('*a'))
    f:close()
    for s in out:gmatch("%S+") do
      table.insert(files,d..s)
    end
  end
  return files
end

function split_str(inputstr,sep)
  if sep==nil then
    sep="%s"
  end
  local t={}
  for str in string.gmatch(inputstr,"([^"..sep.."]+)") do
    table.insert(t,str)
  end
  return t
end
