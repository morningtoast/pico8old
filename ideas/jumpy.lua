t=0
colors={wall=7,air=0,mob=11,trap=9,player=8,bg=1}
debug=false



--
-- gravity
--
gravity={v=.5,dir=1,t=0,limit=300,warning=150}
gravity.on=function() if gravity.v>0 then return true else return false end
gravity.toggle=function()
    if gravity.v<0 then
        gravity.v=abs(gravity.v)
        gravity.dir=1
    else
        gravity.v=0-gravity.v
        gravity.dir=-1
    end
    
    gravity.t=0
end
gravity._update=function() 
    gravity.t+=1 
    
    --if gravity.t>=gravity.limit then gravity.toggle() end
end







--
-- player
--
-- t=timer,st=state,s=speed,jh=jumpMaxHeight, dir=Xdirection(1,-1), gt=gravityTimer
-- state: 0=active
player={x=40,y=70,w=1,h=2,t=0,st=0, xv=1,yv=0, jh=3.5,g=false}
player.dx=player.x
player.dy=player.y


player._update=function()
    if btnalt then gravity.toggle() end

    -- active
    if player.st==0 then
        player.dx=player.x
        
    	--horizontal movement
        if btnleft then player.dx=positionX-player.xv end
        if btnright then player.dx=positionX+player.xv end
    	
    	--if player.dx>127 then player.dx=127 end --don't need because of pixel frame?
    	--if player.dx<0 then player.dx=0 end
        
        --jump, apply velocity
        if btnjump and player.g then
            if gravity.on() then
                player.yv = 0-player.jh
            else
                player.yv = player.jh
            end
            player.g = false;
        end

    	player.yv += gravity.v;
        player.dy=player.y + player.yv;
    	
    	local pxcheck=pget(player.dx, player.dy)
    	local pxbelow=pget(player.x, flr(player.dy)+gravity.dir)
    	
    	--if the next position or below is a wall, stop the and fall
    	if pxcheck~=colors.air and pxbelow~=colors.air then
    		player.yv = 0;
            player.g = true;
    	else
    		player.y=player.dy
    	end
    	
    	-- wall collision, if left/right space is wall then stop
    	if pget(player.dx, player.y)==colors.air then
    		player.x=player.dx
    	end
    end


end

player._draw=function()
    if gravity.on() then
        line(player.x,player.y, player.x,player.y-player.h, colors.player) --body, up from foot
    	pset(player.x,player.y, 10) --yellow foot
    else
        line(player.x,player.y, player.x,player.y+player.h, colors.player) --body, up from foot
    	pset(player.x,player.y, 10) --yellow foot
    end
    
end




--[[
-- mobs
--
-- states: 0=waiting, 1=walk, 2=fall
mobs={all={}}
mobs.create=function(x,y)
    local newmob={
        x=x,
        y=y,
        w=1,
        h=1,
        t=0,
        st=0,
        s=1,
        accel=.3,
        dir=1
    }

    newmob.changeState=function(stateId)
       newmob.st=stateId
       newmob.t=0
    end

    
    add(mobs.all, newmob)    
    return newmob
end

mobs.canfall=function(mob)
    if gravity.on() then
        local below=mob.y+1
    else
        local below=mob.y-1
    end
    
    if pget(mob.x,below)==colors.air and pget(mob.x+1,below)==colors.air then  --check if pixels below both feet is air or colored
        return true
    else
        return false
    end
end 

mobs.obstacle=function(mob)
    local check={}
    local blocked=false
    
    if gravity.on() then
        if mob.dir<0 then 
            add(check, {x=mob.x-1,y=mob.y+1})
            add(check, {x=mob.x-1,y=mob.y})
        else
            add(check, {x=mob.x+1+mob.w,y=mob.y+1})
            add(check, {x=mob.x+1+mob.w,y=mob.y})
        end
    else
        if mob.dir<0 then 
            add(check, {x=mob.x-1,y=mob.y-1})
            add(check, {x=mob.x-1,y=mob.y})
        else
            add(check, {x=mob.x+1+mob.w,y=mob.y-1})
            add(check, {x=mob.x+1+mob.w,y=mob.y})
        end
    end

    foreach(check, function(pos)
        if pget(pos.x,pos.y)~=colors.air then blocked=true end
    end)
    
    return blocked
end


mobs._update=function(mob)
        
    
    -- idle
    if mob.st==0 then
        if mob.t>=60 then mob.changeState(1) end
        if mobs.canfall(mob) then mob.changeState(2) end
    end
    
    -- walk
    if mob.st==1 then
        if mobs.obstacle(mob) then --if there's an obstalce, switch direction
            if mob.dir<0 then mob.dir=1 else mob.dir=-1 end
            mob.changeState(0)
        else
            newmob.x+=newmob.dir*min(newmob.accel*newmob.t, newmob.s)
        end
    end
    
    -- fall
    if mob.st==2 then
        if mobs.canfall(mob) then
            mob.y+=min(3,gravity.v*mob.t) --min() picks whichever is lowest, gets faster as you fall but never exceeds 3px/tick
        else
            mob.changeState(0)
        end
    end
    
     
    mob.t+=1
end


mobs._draw=function(mob)
    if gravity.on() then
        rectfill(mob.x,mob.y, mob.x+mob.w,mob.y-mob.h, colors.mob)
    else
        rectfill(mob.x,mob.y, mob.x+mob.w,mob.y+mob.h, colors.mob)
    end
end
]]




--
-- level build
--
-- map(blockx,blocky, displayx,displayy, blockw,blockh)
level={db={},dblen=0,all={}}

-- read map and dump all blocks into array, only once needed
local mx=0
local my=0
for a=1,4 do --col
    for b=1,2 do --row
        add(level.db, {
            x=mx*a,
            y=my*b
        })
    end
end

level.dblen=#level.db
level._init=function()
    level.all={}
    for n=1,15 do
        add(level.all, level.db[pick])
    end
    
    local exitblock=flr(rnd(8)+1)
    level.all[exitblock]={x=0,y=3} --exit room coords
    
end

level._draw=function()
    local mapcol=0
    local maprow=0
    foreach(level.all, function(block)
        if maprow==96 and mapcol==0 then mapcol+=32 end
        
        map(block.x,block.y, mapcol,maprow, 4,4)
        mapcol+=32
        
        if mapcol>=96 then maprow+=32 mapcol=0 end
    end)
    
end





--
-- loops
--

function _init()
    --level._init()

end



function _update()
    btnright=btn(1)
    btnleft=btn(0)
    btnalt=btn(5)
    btnjump=btn(4)
    
    gravity._update()
    
    
    player._update()
    

    t+=1
end



function _draw()
    cls()

    
    player._draw()
    --level._draw()
    
    --ground
    rectfill(0,0, 128,40, 7)
    
    rectfill(0,90, 128,128, 7)
	rectfill(100,82, 128,128, 7)
	rectfill(116,74, 128,128, 7)
	
	rectfill(0,96, 32,128, 7)
    rect(0,0,128,128,7)
    
    print(debug,0,125,1)

end



--
-- utility
--
-- get a random number between min and max
function random(min,max)
	n=round(rnd(max-min))+min
	return n
end

-- round number to the nearest whole
function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end