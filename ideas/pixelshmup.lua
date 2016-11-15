t=0
screen={x=0,y=0,w=128,h=128}
colors={player=7,gun=8,air=0,shot=9,bullet=10}
debug=false


--
-- player
--
-- t=timer,st=state,s=speed,jh=jumpMaxHeight, dir=Xdirection(1,-1), gt=gravityTimer
-- state: 0=active
player={bt=0}
player.pixels={
    {x=16,y=64,c=8},
    {x=15,y=63,c=7},
    {x=15,y=65,c=7},
}

player.bullets={}

player._update=function()
    local incx=0
    local incy=0
    local shoot=false
    --local stopy=true
    
    if btnup then incy=-1 end
    if btndwn then incy=1 end
    if btnleft then incx=-1 end
    if btnright then incx=1 end
    
    if btna then 
        if player.bt>=20 then shoot=true player.bt=0 end
    end
    
    --see if any pixels are at the the top and stop direction movement
    foreach(player.pixels, function(px) 
        if px.y<=screen.y or px.y>=screen.h then incy=0 end 
        if px.x<=screen.x or px.x>=screen.w then incx=0 end
    end)
    
    -- move+shoot
    foreach(player.pixels, function(px)
        local dx=px.x+incx
        local dy=px.y+incy
        local pxc=pget(dx,dy)

        if pxc==colors.air then
            --nothing but air, move that pixel
            px.x+=dx
            px.y+=dy
        else
            --hits a pixel of color, what to do next
            
            -- ship or gun block; add to ship
            if pxc==colors.player or pxc==colors.gun then
                add(player.pixels, {x=dx,y=dy,c=pxc})
            end

            -- enemy shot; destroy pixel
            if pxc==colors.shot then
                del(player.pixels, px)
            end
        end
    
        -- shoot
        if shoot then
            if pxc==colors.gun then
                add(player.bullets,{x=px.x,y=px.y}) 
            end
        end
    
    
    end)


    -- bullet movement
    foreach(player.bullets, function(bullet)
        bullet.x+=2
    end)

    player.bt+=1
end



player._draw=function()
    foreach(player.pixels, function(px)
        pset(px.x,px.y, px.c)
        
    end)
    
    foreach(player.bullets, function(b)
        pset(b.x,b.y, colors.bullet)
    end)

end


--
-- loops
--

function _init()
    

end



function _update()
    btnright=btn(1)
    btnleft=btn(0)
    btndwn=btn(3)
    btnup=btn(2)
    btnslide=btn(5)
    btnshoot=btn(4)

    
    player._update()
    

    t+=1
end



function _draw()
    cls()

    
    player._draw()


    print(debug,0,125,1)

end



--
-- utility
--


function offscreen(x,y)
	--screen={x=2,y=3,w=128,h=118,mid=60}
	if (x<screen.x-16 or x>screen.w or y<screen.y-16 or y>screen.h) then 
		return true
	else
		return false
	end
end