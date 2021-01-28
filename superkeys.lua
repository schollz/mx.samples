-- superkeys v0.0.0
-- sample player
--
-- llllllll.co/t/superkeys
--

superkeys=include("superkeys/lib/superkeys")

engine.name="Superkeys"
sk=nil

function init()
  sk=superkeys:new()
  -- lets add files
  files=list_files(_path.code.."superkeys/sample/piano/")
  for _,fname in ipairs(files) do
    if string.find(fname,".wav") then
      print("adding "..fname)
      pathname,filename,ext=string.match(x,"(.-)([^\\/]-%.?([^%.\\/]*))$")
      local foo=split(filename,".")
      velocity_range={30,100}
      if foo[2]=="pp" then
        velocity_range={0,30}
      elseif foo[2]=="ff" then
        velocity_range={100,127}
      end
      midi=foo[3]
      sk:add{name="piano",sample=fname,midi=midi,velocity_range=velocity_range}
    end
  end

  clock.run(redraw_clock) -- start the grid redraw clock
end

function enc(k,d)

end

function key(k,z)

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

function split(inputstr,sep)
  if sep==nil then
    sep="%s"
  end
  local t={}
  for str in string.gmatch(inputstr,"([^"..sep.."]+)") do
    table.insert(t,str)
  end
  return t
end
