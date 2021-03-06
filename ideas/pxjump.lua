pico-8 cartridge // http://www.pico-8.com
version 7
__lua__
t=0
colors={wall=7,air=0,player=8}
debug=false

--
-- player
--
positionX = 40;
positionY = 89;
velocityX = 1;
velocityY = 0;
gravity = .5;
onGround = false;
dx=positionX
dy=positionY


function _update()
    btnright=btn(1)
    btnleft=btn(0)
    btnjump=btn(4)
	
	dx=positionX
    
	--horizontal movement
    if btnleft then dx=positionX-velocityX end
    if btnright then dx=positionX+velocityX end
	
	if dx>127 then dx=127 end
	if dx<0 then dx=0 end
    
    --jump, apply velocity
    if btnjump and onGround then
        velocityY = -3.5;
        onGround = false;
    end

	--calc in gravity and add to Y
	if not onGround then
		
	end
	
	velocityY += gravity;
    dy=positionY + velocityY;
	
	local pxcheck=pget(dx, dy)
	local pxbelow=pget(positionX, flr(dy)+1)
	
	--check pixel below player to see if it's a wall color
	if pxcheck==colors.wall and pxbelow==colors.wall then
		velocityY = 0;
        onGround = true;
	else
		positionY=dy
	end
	
	if pget(dx, positionY)~=colors.wall then
		positionX=dx
	end
	
	
	
	debug=pxbelow
    

    t+=1
end



function _draw()
    cls()
    
    line(positionX,positionY, positionX,positionY-2, colors.player) --draw stick up from foot
	pset(positionX,positionY, 10) --foot
	
	--ground
    rectfill(0,90, 128,128, 7)
	rectfill(100,82, 128,128, 7)
	rectfill(116,74, 128,128, 7)

    print(debug,0,120,1)
	print(positionX..", "..positionY, 90,120,2)
end

