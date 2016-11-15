pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- cave runners!
-- by guerragames

--[[
todo:
- pick-ups?
- land anim?
- bouncer?
- finish screen?! congratulations + global time
--]]

-------------------
-- globals
-------------------
one_frame = 1/30

t = 0
time_since_press = 100
time_since_release = 100
time_held = 0
button_held = false

max_running_time = 60*100

---------------------------
-- button handling
---------------------------
function button_update()
 time_since_press += one_frame
 time_since_release += one_frame
  
 -- button or mouse button pressed
 if btn(4) or btn(5) or stat(34) != 0 then
  if time_held == 0 then
   button_held = true
   time_since_press = 0
  end
  
  time_held += one_frame
 else
  if time_held > 0 then
   time_since_release = 0
  end
  
  button_held = false
  time_held = 0
 end
end

function button_consume()
 time_since_press = 100
 time_since_release = 100
end

---------------------------
-- vector2d 
---------------------------
function magnitude( x, y )
  return sqrt( x * x + y * y )
end

-------------------

function normalizewithmag( x, y )
  local mag = magnitude( x, y )
  local one_over_mag = 1 / mag

  local normal_x = x * one_over_mag
  local normal_y = y * one_over_mag

  return normal_x, normal_y, mag
end

-------------------

function rotate_point( x, y, cosa, sina )
 return x*cosa - y*sina, x*sina + y*cosa
end

-------------------

function scale_point( x, y, scalex, scaley )
 return scalex*x, scaley*y
end

----------------------------
-- ease_out
----------------------------
function ease_out(time, start, delta, duration)
 time /= duration
 time -= 1 
 return delta*(time*time*time*time*time + 1) + start
end

function lerp(time, start, delta, duration)
 return time*delta/duration + start
end


----------------------------
-- print_outline
----------------------------
align_center = 0
align_left = 1
align_right = 2

function print_outline( text, x, y, color, backc, align )
  local offsetx = 0 
  
  if not align or align == align_center then
   offsetx = (#text * 0.5)*4
  elseif align == align_right then
   offsetx = #text*4
  end
  
  print( text, x - offsetx - 1, y - 0, backc )
  print( text, x - offsetx - 1, y - 1, backc )
  print( text, x - offsetx + 0, y - 1, backc )
  print( text, x - offsetx + 1, y - 1, backc )
  print( text, x - offsetx + 1, y + 0, backc )
  print( text, x - offsetx + 1, y + 1, backc )
  print( text, x - offsetx - 0, y + 1, backc )
  print( text, x - offsetx - 1, y + 1, backc )
  
  print( text, x - offsetx, y, color )
end

----------------------------
-- print_scaled
----------------------------

function scan_text(text)
  cls()
  scan={}
  print(text,0,0,1)
  for y=0,6+1 do
    scan[y]={}
    for x=0,(#text)*4+1 do
      scan[y][x]=pget(x,y)
    end
  end
  cls()
  return scan
end

-----------

function print_scaled(text,x,y,w,h,color)

  tw=#text[0]
  th=#text
  
  pix_w = flr(w/tw)
  pix_h = flr(h/th)
  
  pix_w = (pix_w == 0) and 1 or pix_w
  pix_h = (pix_h == 0) and 1 or pix_h
  
  for j=y,y+h,pix_h do
   v=flr(((j-y)/h)*th)
   row = text[v]
   
   for i=x,x+w,pix_w do
    u=flr(((i-x)/w)*tw)
	c = row and row[u] or c
	if c!=0 then
	 if color!=nil then
	  rectfill(i,j,i+pix_w-1,j+pix_h-1,color)
	 else
	  rectfill(i,j,i+pix_w-1,j+pix_h-1,c)
	 end
	end
   end
  end
end

-----------

function print_outline_scaled( text,x,y,w,h, color, backc )
 
  print_scaled( text, x - 1, y - 0,w,h, backc )
  print_scaled( text, x - 1, y - 1,w,h, backc )
  print_scaled( text, x + 0, y - 1,w,h, backc )
  print_scaled( text, x + 1, y - 1,w,h, backc )
  print_scaled( text, x + 1, y + 0,w,h, backc )
  print_scaled( text, x + 1, y + 1,w,h, backc )
  print_scaled( text, x - 0, y + 1,w,h, backc )
  print_scaled( text, x - 1, y + 1,w,h, backc )
  
  print_scaled( text, x, y,w,h, color )
end

-----------------
-- time_to_text
-----------------
function time_to_text( time )
 local mins = flr(time/60)
 local secs = time%60
 
  if mins >= 100 then
   return "99:59.999"
  elseif mins > 0 then
   if secs < 10 then
    return mins..":0"..secs
   else
    return mins..":"..secs
   end
  else
   return ""..secs
  end
end

------------------------
-- arrow
------------------------
arrow = {}
arrow.size = 5
arrow.scale = 1
arrow.min_scale = 0.8
arrow.max_scale = 0.8
arrow.min_col_scale = 0.5
arrow.max_col_scale = 1.8
arrow.x = 80
arrow.y = 80
arrow.colors = {8,9,10,7,12}
arrow.nx = 1
arrow.ny = 0

arrow.points =
{
 { 0, 0},
 { 2, 2},
 { 1, 2},
 { 1, 4},
 {-1, 4},
 {-1, 2},
 {-2, 2},
 { 0, 0},
}

--------------------------

arrow.draw = function()
 local st = 0.8*sin(t)
 local scale = arrow.scale
 
 if scale < arrow.min_scale then
  scale = arrow.min_scale
 elseif scale > arrow.max_scale then
  scale = arrow.max_scale
 end
 
 local col_scale = arrow.scale
 if col_scale < arrow.min_col_scale then
  col_scale = arrow.min_col_scale
 elseif col_scale > arrow.max_col_scale then
  col_scale = arrow.max_col_scale
 end
 local color_index = 1 + flr( ((col_scale - arrow.min_col_scale)/(arrow.max_col_scale - arrow.min_col_scale) ) * (#arrow.colors-1))
 local color = arrow.colors[color_index]
 
 local x,y = scale_point(arrow.points[1][1], arrow.points[1][2], scale*(arrow.size+st), scale*(arrow.size-st))
 local cosa = arrow.ny
 local sina = arrow.nx
 x,y = rotate_point(x,y,cosa,sina)
 
 for i=2,#arrow.points do
  local px,py = x,y
  x,y = scale_point(arrow.points[i][1], arrow.points[i][2],scale*(arrow.size+st), scale*(arrow.size-st))
  x,y = rotate_point(x,y,cosa,sina)
  
  local ax = arrow.x+x
  local ay = arrow.y+y
  local pax = arrow.x+px
  local pay = arrow.y+py
  line(ax+1,ay,pax+1,pay, 0)
  line(ax-1,ay,pax-1,pay, 0)
  line(ax,ay+1,pax,pay+1, 0)
  line(ax,ay-1,pax,pay-1, 0)

  line(ax+1,ay+1,pax+1,pay+1, 0)
  line(ax-1,ay-1,pax-1,pay-1, 0)
  line(ax-1,ay+1,pax-1,pay+1, 0)
  line(ax+1,ay-1,pax+1,pay-1, 0)
 end 

 for i=2,#arrow.points do
  local px,py = x,y
  x,y = scale_point(arrow.points[i][1], arrow.points[i][2],scale*(arrow.size+st), scale*(arrow.size-st))
  x,y = rotate_point(x,y,cosa,sina)
  line(arrow.x+x,arrow.y+y,arrow.x+px,arrow.y+py, color)
 end 
 
end

--------------------------
-- booms
--------------------------
booms = {}
booms.next = 1
booms.count = 10
booms.max_time = .2

booms.max_spikes = 100
booms.min_size = 8
booms.max_size = 40

for i=1,booms.count do
 local boom = {}
 
 boom.t = 0
 boom.x = 64
 boom.y = 64
 boom.spikes_count = 100
 boom.color = 7
 boom.active = false
 boom.orient = 0
 
 for j=1,booms.max_spikes+1 do
  local b = {}
  b.r = 0
  b.a = 0
  b.max_r = 0
  add( boom, b )
 end
 
 add( booms, boom )
end

----------------------
booms.spawn = function( x, y, color, orient, spikes_count ) -- orient: 0=floor,1=rwall,2=ceiling,3=lwall, 4=360
 local boom = booms[booms.next]
 boom.t = 0
 boom.x = x
 boom.y = y
 boom.color = color
 boom.active = true
 boom.orient = orient
 boom.spikes_count = spikes_count
 
 if boom.spikes_count > booms.max_spikes then
  boom.spikes_count = booms.max_spikes
 end

 for i=1,boom.spikes_count+1 do
  local b = boom[i]
  b.r = 0
  if boom.orient == 4 then
   b.a = i/boom.spikes_count
  else
   b.a = (i-1)/(2*boom.spikes_count) + boom.orient*0.25
  end
  
  b.max_r = booms.min_size + rnd()*((booms.max_size-booms.min_size)*(i%2))
 end
 
 booms.next += 1
 
 if booms.next > booms.count then
  booms.next = 1
 end
end

----------------------------
booms.update = function()
 for i=1,booms.count do
  local boom = booms[i]
  if boom.active then 
   boom.t += one_frame
 
   for j=1,boom.spikes_count+1 do
    local b = boom[j]
    b.r = (boom.t/booms.max_time)*b.max_r
  
    if b.r > b.max_r then
     b.r = b.max_r
    end
   end  
  
   if boom.t >= booms.max_time then
    boom.active = false
   end
  end
 end
end

-------------------------
booms.draw_line = function( cx, cy, b1, b2, c, offset_r )
 local x1 = cx + (b1.r + offset_r) * cos( b1.a )
 local y1 = cy + (b1.r + offset_r) * sin( b1.a ) 
 local x2 = cx + (b2.r + offset_r) * cos( b2.a )
 local y2 = cy + (b2.r + offset_r) * sin( b2.a ) 
 line(x1,y1,x2,y2,c)
end

-------------------------
booms.draw = function()
 for i=1,booms.count do
  local boom = booms[i]
  if boom.active then 
   for j = 2, boom.spikes_count - 1 do
    booms.draw_line(boom.x, boom.y, boom[j], boom[j+1], boom.color, 0 )
   end
   
   if boom.orient == 4 then
    booms.draw_line(boom.x, boom.y, boom[boom.spikes_count], boom[1], boom.color, 0 )
    booms.draw_line(boom.x, boom.y, boom[1], boom[2], boom.color, 0 )
   end
  end
 end
end

-----------------
-- trail
-----------------
trail = {}
trail.max_count = 12
trail.next = 1
trail.spawn_time = 0

for i=1,trail.max_count do
 add(trail, {x=-1,y=-1,spr=-1,flip=false} )
end

-----------------
trail.init = function()
 for i=1,trail.max_count do
  trail[i].x=-1
  trail[i].y=-1
  trail[i].spr=-1
  trail[i].flip=false
 end 
end

-----------------
trail.update = function(nx,ny,spr,flip)
 trail.spawn_time += one_frame

 if trail.spawn_time > 0.08 then
  trail.spawn_time = 0
 
  local node = trail[trail.next]
  node.x = nx
  node.y = ny
  node.spr = spr
  node.flip = flip
 
  trail.next += 1
 
  if trail.next > trail.max_count then
   trail.next = 1
  end
 end
end

-----------------
trail.draw = function()
 local colors={1,5,13,6}
 local trail_count = -1
 
 local pre_index = (trail.next-1 == 0) and (trail.max_count) or (trail.next-1)
 local pre_x = trail[pre_index].x
 local pre_y = trail[pre_index].y
 

 for i = trail.next, trail.max_count do
  trail_count += 1
  if trail[i].x == -1 then
   break
  end
  
  local color = colors[1+flr(#colors*trail_count/trail.max_count)]
  
  for i=1,15 do
   pal( i, color )
  end
  
  spr( trail[i].spr, trail[i].x, trail[i].y, 1, 1, trail[i].flip )
  
  pre_x = trail[i].x
  pre_y = trail[i].y
 end  

 for i = 1, trail.next-1 do
  trail_count += 1
  if trail[i].x == -1 then
   break
  end
  
  local color = colors[1+flr(#colors*trail_count/trail.max_count)]
  
  for i=1,15 do
   pal( i, color )
  end

  spr(trail[i].spr, trail[i].x, trail[i].y, 1, 1, trail[i].flip )
  
  pre_x = trail[i].x
  pre_y = trail[i].y
 end
 
 pal()
end

-----------------
-- collision
-----------------
function solid_floor( x, y )
 local val = mget(flr(x/8), flr(y/8))
 return fget(val, 0)
end

function solid_ceiling( x, y )
 local val = mget(flr(x/8), flr(y/8))
 return fget(val, 2)
end

function solid_lwall( x, y )
 local val = mget(flr(x/8), flr(y/8))
 return fget(val, 3)
end

function solid_rwall( x, y )
 local val = mget(flr(x/8), flr(y/8))
 return fget(val, 1)
end

-- test if a point is solid
function collision_checks( x, y, vx, vy )
 -- walk a pixel at a time until found collision
 
 local new_x = x
 local new_y = y
 
 local on_floor = false
 local on_ceiling = false
 local on_lwall = false
 local on_rwall = false
 
 local nvx, nvy, vel_mag = normalizewithmag( vx, vy )
 
 local keep_looking = true
 
 while keep_looking do
  local temp_x = new_x
  local temp_y = new_y
  
  if vel_mag > 0 then
   local i_vx = (vel_mag >= 1) and nvx or (vel_mag*nvx) 
   local i_vy = (vel_mag >= 1) and nvy or (vel_mag*nvy)
    
    if not on_floor and not on_ceiling then
     if i_vy > 0 then
      -- check floor
      if solid_floor( new_x+1, new_y+7 + i_vy ) and not solid_floor( new_x+1, new_y+7 ) or 
         solid_floor( new_x+7, new_y+7 + i_vy ) and not solid_floor( new_x+7, new_y+7 ) then
       on_floor = true
       temp_y = flr(temp_y)
       nvy = 0
       i_vy = 0
      end
     elseif i_vy < 0 then
      -- check ceiling
      if solid_ceiling( new_x+1, new_y + i_vy ) and not solid_ceiling( new_x+1, new_y ) or
         solid_ceiling( new_x+7, new_y + i_vy ) and not solid_ceiling( new_x+7, new_y ) then
       on_ceiling = true
       temp_y = -flr(-temp_y)
       nvy = 0
       i_vy = 0
      end
     end
    end
    
    if not on_rwall and not on_lwall then
     if i_vx > 0 then
      -- check rwall
      if solid_rwall( new_x+7 + i_vx, new_y+1 ) and not solid_rwall( new_x+7, new_y+1 ) or
         solid_rwall( new_x+7 + i_vx, new_y+7 ) and not solid_rwall( new_x+7, new_y+7 ) then
       on_rwall = true
       temp_x = flr(temp_x)
       nvx = 0
       i_vx = 0
      end
     elseif i_vx < 0 then
      -- check lwall
      if solid_lwall( new_x + i_vx, new_y+1 ) and not solid_lwall( new_x, new_y+1 ) or
         solid_lwall( new_x + i_vx, new_y+7 ) and not solid_lwall( new_x, new_y+7 ) then
       on_lwall = true
       temp_x = -flr(-temp_x)
       nvx = 0
       i_vx = 0
      end
     end
    end
    
    if not on_floor and not on_ceiling and not on_lwall and not on_rwall then
    if not on_floor and not on_ceiling then
     if i_vy > 0 then
      -- check floor
      if solid_floor( new_x+1 + i_vx, new_y+7 + i_vy ) and not solid_floor( new_x+1, new_y+7 ) or 
         solid_floor( new_x+7 + i_vx, new_y+7 + i_vy ) and not solid_floor( new_x+7, new_y+7 ) then
       on_floor = true
       temp_y = flr(temp_y)
       nvy = 0
       i_vy = 0
      end
     elseif i_vy < 0 then
      -- check ceiling
      if solid_ceiling( new_x+1 + i_vx, new_y + i_vy ) and not solid_ceiling( new_x+1, new_y ) or
         solid_ceiling( new_x+7 + i_vx, new_y + i_vy ) and not solid_ceiling( new_x+7, new_y ) then
       on_ceiling = true
       temp_y = -flr(-temp_y)
       nvy = 0
       i_vy = 0
      end
     end
    end
    
    if not on_rwall and not on_lwall then
     if i_vx > 0 then
      -- check rwall
      if solid_rwall( new_x+7 + i_vx, new_y+1 + i_vy ) and not solid_rwall( new_x+7, new_y+1 ) or
         solid_rwall( new_x+7 + i_vx, new_y+7 + i_vy ) and not solid_rwall( new_x+7, new_y+7 ) then
       on_rwall = true
       temp_x = flr(temp_x)
       nvx = 0
       i_vx = 0
      end
     elseif i_vx < 0 then
      -- check lwall
      if solid_lwall( new_x + i_vx, new_y+1 + i_vy ) and not solid_lwall( new_x, new_y+1 ) or
         solid_lwall( new_x + i_vx, new_y+7 + i_vy ) and not solid_lwall( new_x, new_y+7 ) then
       on_lwall = true
       temp_x = -flr(-temp_x)
       nvx = 0
       i_vx = 0
      end
     end
    end
    end
    
    if not on_floor and not on_ceiling then
     temp_y += i_vy
    end
  
    if not on_rwall and not on_lwall then
     temp_x += i_vx
    end    
  
    vel_mag -= 1
  else
   keep_looking = false
  end

  new_x = temp_x
  new_y = temp_y
 end
 
 return { x=new_x, y=new_y, floor=on_floor, lwall=on_lwall, rwall=on_rwall }
end

------------------
-- player
------------------
player={}

player.dude_anims ={}
player.girl_anims = {}
player.dog_anims = {}
player.mouse_anims = {}
player.car_anims = {}
player.alien_anims = {}
player.slime_anims = {}

-- dude
player.dude_anims.set_index = 1
player.dude_anims.run_anim={9,9,1,1,2,2,3,3,4,4,5,5}
player.dude_anims.start_anim={8,8}
player.dude_anims.launch_anim={8,8}
player.dude_anims.land_anim={8,8}
player.dude_anims.wall_slide_anim={6,6,6,6,6,6,7,7}
player.dude_anims.wall_launch_anim={7,7}
player.dude_anims.cheer_anim={9,9,9,9,9,9,8,8,8,8,8,8}
player.dude_anims.target_anims = player.girl_anims
player.dude_anims.starget_anims = player.mouse_anims
player.dude_anims.objective_text = "find the girl!"
player.dude_anims.win_text = "dude found girl"
player.dude_anims.swin_text = "found secret mouse"

-- girl
player.girl_anims.set_index = 2
player.girl_anims.run_anim={16,16,17,17,18,18,19,19,20,20,21,21}
player.girl_anims.start_anim={24,24}
player.girl_anims.launch_anim={24,24}
player.girl_anims.land_anim={24,24}
player.girl_anims.wall_slide_anim={22,22,22,22,22,22,23,23}
player.girl_anims.wall_launch_anim={23,23}
player.girl_anims.cheer_anim={16,16,16,16,16,16,24,24,24,24,24,24}
player.girl_anims.target_anims = player.dog_anims
player.girl_anims.starget_anims = player.slime_anims
player.girl_anims.objective_text = "get the doggy!"
player.girl_anims.win_text = "girl rescued the doggy"
player.girl_anims.swin_text = "found a secret slime"

-- doge
player.dog_anims.set_index = 3
player.dog_anims.run_anim={32,32,33,33,34,34,35,35,36,36,37,37}
player.dog_anims.start_anim={40,40}
player.dog_anims.launch_anim={40,40}
player.dog_anims.land_anim={40,40}
player.dog_anims.wall_slide_anim={38,38,38,38,38,38,39,39}
player.dog_anims.wall_launch_anim={39,39}
player.dog_anims.cheer_anim={32,32,32,32,32,32,40,40,40,40,40,40}
player.dog_anims.target_anims = player.mouse_anims
player.dog_anims.starget_anims = player.alien_anims
player.dog_anims.objective_text = "find the mouse!"
player.dog_anims.win_text = "dog found the mouse"
player.dog_anims.swin_text = "found the secret alien"

-- mouse
player.mouse_anims.set_index = 4
player.mouse_anims.run_anim={48,48,49,49,50,50,51,51,52,52,53,53}
player.mouse_anims.start_anim={56,56}
player.mouse_anims.launch_anim={56,56}
player.mouse_anims.land_anim={56,56}
player.mouse_anims.wall_slide_anim={54,54,54,54,54,54,55,55}
player.mouse_anims.wall_launch_anim={55,55}
player.mouse_anims.cheer_anim={48,48,48,48,48,48,56,56,56,56,56,56}
player.mouse_anims.target_anims = player.car_anims
player.mouse_anims.starget_anims = player.dude_anims
player.mouse_anims.objective_text = "find the car!"
player.mouse_anims.win_text = "mouse found a car"
player.mouse_anims.swin_text = "found a secret dude"

-- car
player.car_anims.set_index = 5
player.car_anims.run_anim={25,25,26,26,25,25,26,26,25,25,26,26}
player.car_anims.start_anim={26,26}
player.car_anims.launch_anim={26,26}
player.car_anims.land_anim={26,26}
player.car_anims.wall_slide_anim={27,27,27,27,27,27,28,28}
player.car_anims.wall_launch_anim={28,28}
player.car_anims.cheer_anim={25,25,25,25,25,25,26,26,26,26,26,26}
player.car_anims.target_anims = player.alien_anims
player.car_anims.starget_anims = player.dog_anims
player.car_anims.objective_text = "find the alien!"
player.car_anims.win_text = "car found a alien"
player.car_anims.swin_text = "found a secret dog"

-- alien
player.alien_anims.set_index = 6
player.alien_anims.run_anim={41,41,42,42,41,41,42,42,41,41,42,42}
player.alien_anims.start_anim={42,42}
player.alien_anims.launch_anim={42,42}
player.alien_anims.land_anim={42,42}
player.alien_anims.wall_slide_anim={43,43,43,43,43,43,44,44}
player.alien_anims.wall_launch_anim={44,44}
player.alien_anims.cheer_anim={41,41,41,41,41,41,42,42,42,42,42,42}
player.alien_anims.target_anims = player.slime_anims
player.alien_anims.starget_anims = player.girl_anims
player.alien_anims.objective_text = "find the slime!"
player.alien_anims.win_text = "alien found a slime"
player.alien_anims.swin_text = "found a secret girl"

-- slime
player.slime_anims.set_index = 7
player.slime_anims.run_anim={57,57,58,58,57,57,58,58,57,57,58,58}
player.slime_anims.start_anim={58,58}
player.slime_anims.launch_anim={58,58}
player.slime_anims.land_anim={58,58}
player.slime_anims.wall_slide_anim={59,59,59,59,59,59,60,60}
player.slime_anims.wall_launch_anim={60,60}
player.slime_anims.cheer_anim={57,57,57,57,57,57,58,58,58,58,58,58}
player.slime_anims.target_anims = player.dude_anims
player.slime_anims.starget_anims = player.car_anims
player.slime_anims.objective_text = "find the dude!"
player.slime_anims.win_text = "slime found a dude"
player.slime_anims.swin_text = "found a secret car"

player.anim_sets = {
 player.dude_anims,
 player.girl_anims,
 player.dog_anims,
 player.mouse_anims,
 player.car_anims,
 player.alien_anims,
 player.slime_anims,
}

player.max_best_time = 99*60 + 99

player.best_times = {
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
}

player.gold_scores = 
{
 43,
 41,
 41,
 17,
 15,
 42,
 17,
}

player.sbest_times = {
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
 player.max_best_time,
}

player.sgold_scores = 
{
 110,
  80,
  40,
  40,
  25,
  25,
  35,
}

player.locked_status = {
 false,
 true,
 true,
 true,
 true,
 true,
 true,
}

-----------------
player.anim_set = player.dude_anims
player.anim = player.anim_set.start_anim
player.anim_index=1
player.anim_flip=false
player.anim_loops=true
player.x = 3*8
player.y = 3*8
player.max_vx = 2
player.vx = 0
player.vy = 0
player.gravity = .4
player.max_vy = 4
player.start_timer = 4
player.start_timer_beeps = 4
player.running_time = 0
player.air_time = 10

player.has_target = false
player.target_found = false
player.target_found_time = 0
player.target_found_after_time = 0
player.target_found_boom_time = 0
player.target_x=-1
player.target_y=-1

player.has_starget = false
player.starget_found = false
player.starget_found = false
player.starget_found_time = 0
player.starget_found_after_time = 0
player.starget_found_boom_time = 0
player.starget_x=-1
player.starget_y=-1

player.last_found = -1
player.just_unlocked = false
player.just_beat_record = false

player.debug_teleports={6,22,38,54,27,43,59}
player.debug_teleport_next = 2

----------------
player.init = function()
 player.anim_index=1
 player.anim_flip=false
 player.anim_loops=true
 player.x = 3*8
 player.y = 3*8
 player.max_vx = 2
 player.vx = 0
 player.vy = 0
 player.gravity = .4
 player.max_vy = 4
 player.start_timer = 4
 player.start_timer_beeps = 4
 player.running_time = 0
 player.air_time = max_running_time

 player.has_target = false
 player.target_found = false
 player.target_found_time = 0
 player.target_found_after_time = 0
 player.target_found_boom_time = 0
 player.target_x=-1
 player.target_y=-1
 
 player.has_starget = false
 player.starget_found = false
 player.starget_found_time = 0
 player.starget_found_after_time = 0
 player.starget_found_boom_time = 0
 player.starget_x=-1
 player.starget_y=-1
 
 player.just_unlocked = false
 player.just_beat_record = false
end

----------------
player.teleport = function()
 local found_teleport = false

 while not found_teleport do
  for i=0,16*8 do
   for j=0,16*4 do
    local map_tile = mget( i, j )
    local flags = fget( map_tile )
    if flags == 0x80 then
     if map_tile == player.debug_teleports[player.debug_teleport_next] then
 	  found_teleport = true
	 
      player.x = i*8
	  player.y = j*8
	 
	  player.debug_teleport_next += 1
	 
	  if player.debug_teleport_next > #player.debug_teleports then
	   player.debug_teleport_next = 1
	  end
	  
	  break
	 end
    end
   end
   
   if found_teleport then
    break
   end
   
  end
 
  if not found_teleport then
   player.debug_teleport_next = 1
  end
 end
end

---------------
player.find_target = function()
 player.has_target = false

 for i=0,16*8 do
  for j=0,16*4 do
   local map_tile = mget( i, j )
    
   if map_tile == player.anim_set.target_anims.cheer_anim[1] then
    player.has_target = true
	 
    player.target_x = i*8 + 4
	player.target_y = j*8 + 4
    break
   end
  end
   
  if player.has_target then
   break
  end
   
 end
end

---------------
player.find_starget = function()
 player.has_starget = false

 for i=0,16*8 do
  for j=0,16*4 do
   local map_tile = mget( i, j )
    
   if map_tile == player.anim_set.starget_anims.cheer_anim[1] then
    player.has_starget = true
	 
    player.starget_x = i*8 + 4
	player.starget_y = j*8 + 4
    break
   end
  end
   
  if player.has_starget then
   break
  end
   
 end
end

---------------
player.find_start = function()
 player.x = 3*8
 player.y = 3*8
 
 local found = false
 
 for i=0,16*8 do
  for j=0,16*4 do
   local map_tile = mget( i, j )
    
   if map_tile == player.anim_set.start_anim[1] then
    player.x = i*8
	player.y = j*8
    
    found = true
    break
   end
  end
   
  if found then
   break
  end
   
 end
end

---------------
player.check_target = function()
 if player.x > player.target_x+4 or
    player.y > player.target_y+4 or
    player.x+8 < player.target_x-4 or
    player.y+8 < player.target_y-4 then
 else
  player.target_found = true
  player.target_found_time = player.running_time
  music(40)
  
  if player.target_found_time < player.best_times[title_screen.selected] then
   -- record broken!
   player.best_times[title_screen.selected] = player.target_found_time
   player.just_beat_record = true
   
   -- save best time
   dset( title_screen.selected, player.best_times[title_screen.selected] )

  end
  
  if player.x+4 > player.target_x then
   player.x = player.target_x+5
   player.anim_flip = true
  else
   player.x = player.target_x-13
   player.anim_flip = false
  end
  
  player.y = player.target_y-4

  player.set_anim( player.anim_set.cheer_anim, true, player.anim_flip )
  player.vx = 0
  player.vy = 0
    
 end
end


---------------
player.check_starget = function()
 if player.x > player.starget_x+4 or
    player.y > player.starget_y+4 or
    player.x+8 < player.starget_x-4 or
    player.y+8 < player.starget_y-4 then
 else
  player.starget_found = true
  player.starget_found_time = player.running_time
  music(40)
  
  if player.starget_found_time < player.sbest_times[title_screen.selected] then
   -- record broken!
   player.sbest_times[title_screen.selected] = player.starget_found_time
   player.just_beat_record = true
   
   -- save best time
   dset( #player.best_times + title_screen.selected, player.sbest_times[title_screen.selected] )

  end
  
  if player.x+4 > player.starget_x then
   player.x = player.starget_x+5
   player.anim_flip = true
  else
   player.x = player.starget_x-13
   player.anim_flip = false
  end
  
  player.y = player.starget_y-4

  player.set_anim( player.anim_set.cheer_anim, true, player.anim_flip )
  player.vx = 0
  player.vy = 0
    
 end
end

---------------
player.anim_end_callback = function()
 if player.anim == player.anim_set.launch_anim or
    player.anim == player.anim_set.wall_launch_anim then
  player.vy = -4.55
  player.vx = player.anim_flip and -player.max_vx or player.max_vx
  player.gravity = .4
  player.max_vy = 4
 end
end

---------------
player.set_anim = function( anim, loops, flips )
 if player.anim != anim then
  player.anim = anim
  player.anim_index = 1
 end
 
 player.anim_loops = loops
 player.anim_flip = flips
end

---------------
player.anim_advance = function()
 player.anim_index += 1
 
 if player.anim_index >= #player.anim+1 then
  player.anim_index = 1
  
  player.anim_end_callback()
  
  if not player.anim_loops then
   player.set_anim( player.anim_set.run_anim, true, sgn(player.vx) != 1 )
  end
 end
end

---------------
player.update = function()
 
 local new_x = player.x + player.vx
 local new_y = player.y + player.vy
 
 local collision_result = collision_checks( player.x, player.y, player.vx, player.vy )
 local colision_x = collision_result.x
 local colision_y = collision_result.y
 
 player.x = colision_x
 player.y = colision_y
 
 player.anim_advance()
 
 if player.start_timer > 0 then
  player.start_timer -= one_frame
  
  if player.start_timer > 3 then
   if player.start_timer_beeps == 4 then
    player.start_timer_beeps -= 1
    sfx(2)
   end
  elseif player.start_timer > 2 then
   if player.start_timer_beeps == 3 then
    player.start_timer_beeps -= 1
    sfx(2)
   end
  elseif player.start_timer > 1 then
   if player.start_timer_beeps == 2 then
    player.start_timer_beeps -= 1
    sfx(2)
   end
  elseif player.start_timer > 0 then
   if player.start_timer_beeps == 1 then
    player.start_timer_beeps -= 1
    sfx(3)
   end
  end  
  
 end
 
 if player.start_timer > 1 then
 elseif player.running_time == 0 and player.start_timer <= 1 then
  -- start running
  music(0)
  
  player.running_time = one_frame
  player.set_anim( player.anim_set.run_anim, true, player.anim_flip )
  player.vx = player.max_vx
  
 elseif not player.target_found and not player.starget_found then

  player.air_time += one_frame
  
  if player.air_time > max_running_time then
   player.air_time = max_running_time
  end
  
  player.running_time += one_frame

  if player.running_time > max_running_time then
   player.running_time = max_running_time
  end
  
  if not collision_result.floor then
   player.vy += player.gravity
  
   if player.vy > player.max_vy then
    player.vy = player.max_vy
   end
  else
   player.vy = 0
  end
 
  -- debug teleport player
  --if btnp(4) then
  -- player.teleport()
  --end
 
  if collision_result.rwall then
    if collision_result.floor then
     -- if we hit the wall on the floor, flip around quickly
     player.anim_flip = not player.anim_flip
     player.vx = player.anim_flip and -player.max_vx or player.max_vx
     player.max_vy = 4
    elseif player.vx >= 0 then
     -- if we hit the wall in the air, slide down the wall slowly
     player.max_vy = 2
     player.set_anim( player.anim_set.wall_slide_anim, true, player.anim_flip )
    end
  elseif collision_result.lwall then
    if collision_result.floor then
     -- if we hit the wall on the floor, flip around quickly
     player.anim_flip = not player.anim_flip
     player.vx = player.anim_flip and -player.max_vx or player.max_vx
     player.max_vy = 4
    elseif player.vx <= 0 then
     -- if we hit the wall in the air, slide down the wall slowly
     player.max_vy = 2
     player.set_anim( player.anim_set.wall_slide_anim, true, player.anim_flip )
    end
  else
   -- not on walls, reset max velocity on y (terminal velocity)
   player.max_vy = 4
  
   if player.anim != player.anim_set.run_anim and
      player.anim != player.anim_set.launch_anim and
      player.anim != player.anim_set.wall_launch_anim then
    player.set_anim( player.anim_set.run_anim, true, player.anim_flip )
   end
  end
 
  if collision_result.floor or 
     collision_result.rwall or 
     collision_result.lwall then
   player.air_time = 0
  end

  if player.air_time < 0.1 then  
   if time_since_press < 0.2 then
     -- fixed jump
     sfx(0)
     
     local orient = 0
     
     if collision_result.floor then
      booms.spawn( player.x+4, player.y+8, 7, 0, 20 )
     elseif collision_result.rwall then
      booms.spawn( player.x+8, player.y+4, 7, 1, 20 )
     elseif collision_result.lwall then
      booms.spawn( player.x, player.y+4, 7, 3, 20 )
     else
      booms.spawn( player.x+4, player.y+8, 7, 0, 20 )
     end
     
     player.vx = 0
     player.vy = 0
     player.gravity = 0
     
     button_consume()
     player.air_time = max_running_time
  
     if collision_result.rwall or collision_result.lwall then
      -- wall jump
      player.set_anim( player.anim_set.wall_launch_anim, false, not player.anim_flip )
     else
      -- regular jump
      player.set_anim( player.anim_set.launch_anim, false, player.anim_flip )
     end
  
   end
  end
  
  if player.has_target then 
   player.check_target()
  end
 
  if player.has_starget then 
   player.check_starget()
  end
  
 else -- target found
  if player.target_found then
   if player.target_found_boom_time <= 0 then
    booms.spawn( 0.5*(player.x+4+player.target_x), player.y+4, 10, 4, 30 )
    player.target_found_boom_time = 0.4
   end
  
   player.target_found_boom_time -= one_frame
   player.target_found_after_time += one_frame
  
   player.last_found = player.anim_set.target_anims.set_index
  
   if player.locked_status[player.anim_set.target_anims.set_index] then
    player.just_unlocked = true
   
    -- save unlocked status
    dset( #player.best_times + #player.sbest_times + player.anim_set.target_anims.set_index, 1 )
   
   end
  
   player.locked_status[player.anim_set.target_anims.set_index] = false
  else
   if player.starget_found_boom_time <= 0 then
    booms.spawn( 0.5*(player.x+4+player.starget_x), player.y+4, 10, 4, 30 )
    player.starget_found_boom_time = 0.4
   end
  
   player.starget_found_boom_time -= one_frame
   player.starget_found_after_time += one_frame
  
   player.last_found = player.anim_set.starget_anims.set_index
  
   if player.locked_status[player.anim_set.starget_anims.set_index] then
    player.just_unlocked = true
   
    -- save unlocked status
    dset( #player.best_times + #player.sbest_times + player.anim_set.starget_anims.set_index, 1 )
   
   end
  
   player.locked_status[player.anim_set.starget_anims.set_index] = false
  end
 end
end

---------------------
player.draw_target = function()
 if player.has_target then
 
  local target_anim_flip = (player.target_x > player.x )
  
  if not player.target_found then
   player.draw_char_sprite( player.anim_set.target_anims.launch_anim[1], player.target_x-4, player.target_y-4, target_anim_flip )
  else
   local anim_len = #player.anim_set.target_anims.cheer_anim
   local target_anim_index = 1 + (player.anim_index + anim_len/2 ) % anim_len 
   player.draw_char_sprite( player.anim_set.target_anims.cheer_anim[target_anim_index], player.target_x-4, player.target_y-4, target_anim_flip )
   
   print_outline( player.anim_set.win_text, cam.x + 64, cam.y + 32, 7, 1 )
   
   print_outline( "in "..time_to_text(player.target_found_time), cam.x + 64, cam.y + 39, 7, 1 )
   
   if player.just_beat_record then
    print_outline( "new record!", cam.x + 64, cam.y + 84, 8 + sin(t), 1 )
   end
   
   if player.just_unlocked then
    print_outline( "new character unlocked!", cam.x + 64, cam.y + 91, 8 + sin(t), 1 )
   end
  end
  
  local cam_bounds_check = (player.target_x+4) >= (cam.x) and
                           (player.target_x-4) <= (cam.x + 127) and
                           (player.target_y+4) >= (cam.y) and
                           (player.target_y-4) <= (cam.y + 127)
  
  if not cam_bounds_check then
   local player_cx = player.x + 4
   local player_cy = player.y + 4
  
   local dist_x = (player.target_x - player_cx)/100
   local dist_y = (player.target_y - player_cy)/100
   
   local nx, ny, dist_mag = normalizewithmag( dist_x, dist_y )

   local to_edge_x = -1
   local to_edge_y = -1   
   
    if nx >= 0 then
     to_edge_x = ((cam.x + 127) - player_cx)/nx
    else
     to_edge_x = (cam.x - player_cx)/nx
    end

    if ny >= 0 then
     to_edge_y = ((cam.y + 127) - player_cy)/ny
    else
     to_edge_y = (cam.y - player_cy)/ny
    end
   
    local to_edge = (abs(to_edge_x) <= abs(to_edge_y)) and to_edge_x or to_edge_y

    local edge_x = player_cx + to_edge*nx
    local edge_y = player_cy + to_edge*ny
    
    arrow.x = flr(edge_x)
    arrow.y = flr(edge_y)
    
    arrow.nx = nx
    arrow.ny = -ny
    arrow.scale = dist_mag*0.4

    arrow.draw()
  end
 end
end

---------------------
player.draw_starget = function()
 if player.has_starget then
 
  local target_anim_flip = (player.starget_x > player.x )
  
  if not player.starget_found then
   player.draw_char_sprite( player.anim_set.starget_anims.launch_anim[1], player.starget_x-4, player.starget_y-4, target_anim_flip )
  else
   local anim_len = #player.anim_set.starget_anims.cheer_anim
   local target_anim_index = 1 + (player.anim_index + anim_len/2 ) % anim_len 
   player.draw_char_sprite( player.anim_set.starget_anims.cheer_anim[target_anim_index], player.starget_x-4, player.starget_y-4, target_anim_flip )
   
   print_outline( player.anim_set.swin_text, cam.x + 64, cam.y + 32, 7, 1 )
   
   print_outline( "in "..time_to_text(player.starget_found_time), cam.x + 64, cam.y + 39, 7, 1 )
   
   if player.just_beat_record then
    print_outline( "new record!", cam.x + 64, cam.y + 84, 8 + sin(t), 1 )
   end
   
   if player.just_unlocked then
    print_outline( "new character unlocked!", cam.x + 64, cam.y + 91, 8 + sin(t), 1 )
   end
  end
 end
end

---------------------
player.draw_char_sprite = function( sprite, x, y, anim_flip )
 for i=1,15 do
  pal( i, 0 )
 end

 spr( sprite, x+1, y, 1, 1, anim_flip )
 spr( sprite, x-1, y, 1, 1, anim_flip )
 spr( sprite, x, y+1, 1, 1, anim_flip )
 spr( sprite, x, y-1, 1, 1, anim_flip )
 
 spr( sprite, x+1, y+1, 1, 1, anim_flip )
 spr( sprite, x-1, y-1, 1, 1, anim_flip )
 spr( sprite, x-1, y+1, 1, 1, anim_flip )
 spr( sprite, x+1, y-1, 1, 1, anim_flip )
 
 pal()
 spr( sprite, x, y, 1, 1, anim_flip )
 --rect( x, y, x+7, y+7, 7)
end
 
---------------------
player.draw_find_text = function( delta, text )
   local offset = ease_out( max( 0, 1 - 10*delta ), 0, 64 + #text*4, 1 )
   local x = cam.x + 64 + offset
   print_outline( text, x, cam.y + 88, 7, 1 )
end

---------------------
player.draw_start_bubble = function( delta, text, size, color )
 local radius = ease_out( 1-delta, 1, size, 1 )
 local offset = ease_out( max( 0, 1 - 1.8*delta ), 0, 64 + size*2, 1 )
 local x = cam.x + 64 + offset
 circfill( x - 1, cam.y + 82, radius, color )
 circ( x - 1, cam.y + 82, radius, 1 )
 print_outline( text, x, cam.y + 80, 7, 1 )
end

---------------------
player.draw = function( delta, text )
 local sprite = player.anim[flr(player.anim_index)]
 
 player.draw_char_sprite( sprite, player.x, player.y, player.anim_flip )
 
 player.draw_target()
 player.draw_starget()
 
 if player.start_timer > 0 then
  if player.start_timer > 3 then
   local delta = player.start_timer - 3
   player.draw_start_bubble( delta, "3", 8, 8 )
  elseif player.start_timer > 2 then
   local delta = player.start_timer - 2
   player.draw_start_bubble( delta, "2", 9, 8 )
  elseif player.start_timer > 1 then
   local delta = player.start_timer - 1
   player.draw_start_bubble( delta, "1", 10, 8 )
  elseif player.start_timer > 0 then
   local delta = player.start_timer
   player.draw_start_bubble( delta, "go!", 16, 11 )
  end
  
  
  local delta = player.start_timer
  player.draw_find_text( delta/4, player.anim_set.objective_text )
  
 end
 
end


---------------------
-- camera
---------------------
cam = {}
cam.x = 0
cam.y = 0
cam.max_x = 8*16*7 -- 8 full screens
cam.max_y = 8*16*3 -- 4 full screens
cam.border = 48

---------------------
cam.init = function()
 cam.x = 0
 cam.y = 0
end

---------------------
cam.snap = function()
 cam.x = player.x + 4 - 64
 cam.y = player.y + 4 - 64

 cam.x = max( 0, min( cam.x, cam.max_x ) )
 cam.y = max( 0, min( cam.y, cam.max_y ) ) 
end

---------------------
cam.update = function()
 if player.x > cam.x + 128-cam.border-8 then
  cam.x += .3* ( player.x - (cam.x + 128-cam.border-8) )
 elseif player.x < cam.x + cam.border then
  cam.x -= .3* ( cam.x + cam.border - player.x )
 end
 
 if player.y > cam.y + 128-cam.border-8 then
  cam.y += .3* ( player.y - (cam.y + 128-cam.border-8) )
 elseif player.y < cam.y + cam.border then
  cam.y -= .3* ( cam.y + cam.border - player.y )
 end
 
 cam.x = max( 0, min( cam.x, cam.max_x ) )
 cam.y = max( 0, min( cam.y, cam.max_y ) )
end


---------------------
-- title_screen
---------------------
title_screen ={}
title_screen.active = true
title_screen.anim_index = 1
title_screen.selected = 1
title_screen.text = scan_text("cave runners!")
title_screen.title_offsetx = 0

---------------------
title_screen.init = function()
 title_screen.active = true
 music(20)
 title_screen.anim_index = 1
 title_screen.selected = 1
 
 if player.last_found != -1 then
  title_screen.selected = player.last_found
 end
 
 title_screen.title_offsetx = 0
end

---------------------
title_screen.start_level = function()
 views.set_current( game_view, 0.25, 0.5 )
end

---------------------
title_screen.update = function()
 
 if time_since_release < 0.1 then

  sfx(0)
  button_consume()
  
  title_screen.selected += 1

  if title_screen.selected > #player.anim_sets then
   title_screen.selected = 1
  end
  
  local locked = player.locked_status[title_screen.selected]
  
  while locked do
   title_screen.selected += 1
   
   if title_screen.selected > #player.anim_sets then
    title_screen.selected = 1
   end
   
   locked = player.locked_status[title_screen.selected]
  end
  
 end
 
 if time_held >= 1.2 then
  title_screen.start_level()
 end

 title_screen.title_offsetx = 0
 
 if t <= 1 then
  title_screen.title_offsetx = ease_out( t, -256, 256, 1 )
 end 
 
end

---------------------
title_screen.draw = function()
 local title_height = 16

 -- main title
 local colors={1,5,13,6,7}
 for i=1, #colors do
  print_scaled( title_screen.text, title_screen.title_offsetx + 2 + i*5, 5 + (2 + 2*i/#colors)*sin(i/#colors + 2*t), 96, title_height, colors[i] )
 end
 
 print_outline_scaled( title_screen.text, title_screen.title_offsetx + 2 + #colors*5, 5 + 4*sin(1 + 2*t), 96, title_height, 7, 1 )

 -- character selection section
 title_screen.anim_index+=1
 
 if title_screen.anim_index > #player.anim_sets[1].run_anim then
  title_screen.anim_index = 1
 end

 local offsetx = 4 + min(90, time_held*90)
 local anim_i = title_screen.anim_index
 for i=#colors,1,-1 do
  anim_i += 1

  if anim_i > #player.anim_sets[1].run_anim then
   anim_i = 1
  end  
  
  local sprite = player.anim_sets[title_screen.selected].run_anim[anim_i]
  
  for c=1,15 do
   pal( c, colors[#colors - i + 1] )
  end
  
  local offx_multiplier = 2 + title_screen.selected*0.1
  
  -- draw the trials
  spr( sprite, title_screen.title_offsetx*offx_multiplier + 58 + offsetx - i*4, 28 + title_screen.selected*10 )
 end
 
 pal()
 
 local one_secret_found = false
 local one_score_set = false
 
 local total_best = 0
 local worst_medal = 1
 local show_total = true
 
 local total_sbest = 0
 local sworst_medal = 0
 local show_stotal = true
 
 local medal_sprites = { 10,11,12,13 }
 local medal_colors = { 10,7,9,6 }
 
 -- draw selectable chars on the title screen
 for i=1,#player.anim_sets do
  local locked = player.locked_status[i]
  
  if not locked then
  
   -- draw some floor tiles
   for j=-1,16 do 
    spr( 100, j*8 + (t*80)%8, 36 + i*10 )
   end
  
   local offsetx = 0
   local best_score_offset = 0
   local best_score_color = 6
   local sbest_score_color = 6
  
   if title_screen.selected == i then 
    offsetx = 4 + min(90, time_held*90 ) 
    best_score_offset = -4
   else
    if time_held > 0.5 then
     offsetx = -(4 + min(60, (max(0, time_held-0.5)*80 )))
    end
   end
   
   local offx_multiplier = 2 + i*0.4
  
   player.draw_char_sprite( player.anim_sets[i].run_anim[title_screen.anim_index], title_screen.title_offsetx*offx_multiplier + 58 + offsetx, 28 + i*10, false )
  
   if player.best_times[i] < player.max_best_time then
    one_score_set = true
    total_best += player.best_times[i]
    
    local medal_index = 1
    
    local time_offset_x = 0
    if player.best_times[i] <= player.gold_scores[i] then
     time_offset_x = -8
     best_score_color = 10
    elseif player.best_times[i] <= player.gold_scores[i]+5 then
     time_offset_x = -8
     best_score_color = 7
     medal_index = 2
    elseif player.best_times[i] <= player.gold_scores[i]+10 then
     time_offset_x = -8
     best_score_color = 9
     medal_index = 3	 
    else
     medal_index = 4
	end
    
    if worst_medal < medal_index then
	 worst_medal = medal_index
	end
    
    spr( medal_sprites[medal_index], title_screen.title_offsetx*offx_multiplier + 121 + best_score_offset, 30 + i*10 ) -- draw medal
    print_outline( time_to_text(player.best_times[i]), title_screen.title_offsetx*offx_multiplier + 128 + time_offset_x + best_score_offset, 31 + i*10, best_score_color, 1, align_right )
   else
    show_total = false
   end

   if player.sbest_times[i] < player.max_best_time then
    one_secret_found = true
    total_sbest += player.sbest_times[i]
    
    
    local smedal_index = 1
    
    local stime_offset_x = 0
    if player.sbest_times[i] <= player.sgold_scores[i] then
     stime_offset_x = 8
     sbest_score_color = 10
    elseif player.sbest_times[i] <= player.sgold_scores[i]+5 then
     stime_offset_x = 8
     sbest_score_color = 7
     smedal_index = 2
    elseif player.sbest_times[i] <= player.sgold_scores[i]+10 then
     stime_offset_x = 8
     sbest_score_color = 9
     smedal_index = 3	 
    else
     smedal_index = 4
	end
    
    if sworst_medal < smedal_index then
	 sworst_medal = smedal_index
	end
    
    spr( medal_sprites[smedal_index], title_screen.title_offsetx*offx_multiplier - best_score_offset, 30 + i*10 ) -- draw medal
    print_outline( time_to_text(player.sbest_times[i]), title_screen.title_offsetx*offx_multiplier + 1 + stime_offset_x - best_score_offset, 31 + i*10, sbest_score_color, 1, align_left )
   else
    show_stotal = false
   end

  end
 end
 
 local msg_offsetx = 128
 
 if t <= 1 then
  msg_offsetx = ease_out( t, 0, 128, 1 )
 end
 
 if one_secret_found then
  print_outline( "secrets found", title_screen.title_offsetx*1.5 + 1, 30, 6, 1, align_left )
 end
 
 if one_score_set then 
  print_outline( "best times", title_screen.title_offsetx*1.5 + 128, 30, 6, 1, align_right )
 end
 
 print_outline( "tap to select! hold to run!", title_screen.title_offsetx + 64, 23, 7, 1 )
 
 if show_total or show_stotal then
  print_outline( "<total>", title_screen.title_offsetx*5 + 64, 110, 7, 1 )
  
  if show_stotal then
   best_score_offset = 0
   
   if sworst_medal != 4 then
    best_score_offset = 8
    spr( medal_sprites[sworst_medal], title_screen.title_offsetx*5, 109 )
   end
   
   print_outline( time_to_text(total_sbest), title_screen.title_offsetx*5 + 1 + best_score_offset, 110, medal_colors[sworst_medal], 1, align_left )  
  end
  
  if show_total then
   best_score_offset = 0
   
   if worst_medal != 4 then
    best_score_offset = -8
    spr( medal_sprites[worst_medal], title_screen.title_offsetx*5 + 121, 109 )
   end
   
   print_outline( time_to_text(total_best), title_screen.title_offsetx*5 + 128 + best_score_offset, 110, medal_colors[worst_medal], 1, align_right )   
  end
 end
 
 print_outline( "guerragames 2016", title_screen.title_offsetx*6 + 66, 120, 7, 1 )
 
 --rect( 0, 0, 127, 127, 7 )
end

---------------------
-- on-load stuff
---------------------
cartdata( "caverunners" )
poke(0x5f2d, 1) -- enable mouse stuff

menuitem( 1, "restart run \129", title_screen.start_level )

-- load best times
for i=1, #player.best_times do
 local best = dget( i )
 if best > 0 then
  player.best_times[i] = best
 end
end

-- load sbest times
for i=1, #player.sbest_times do
 local best = dget( #player.best_times + i )
 if best > 0 then
  player.sbest_times[i] = best
 end
end

-- load unlocked statuses
for i=2, #player.locked_status do
 player.locked_status[i] = ( dget( #player.best_times + #player.sbest_times + i ) == 0 )
end

---------------------
function _init()

 -- init globals
 t = 0
 time_since_press = 100
 time_since_release = 100
 time_held = 0
 button_held = false
 
 trail.init()
 cam.init()
 player.init()
 title_screen.init()
end

---------------------
function screen_fade_out( fade_out_time, max_fade_out_time )
 local px = {}
 
 local end_x = 128 - 128 * ( fade_out_time / max_fade_out_time )
 
 for j = 0, 128 do
  px[j] = end_x
 end

 for j = 0, 128 do
  local vx = 10 + rnd(50)
   
  px[j] += vx
   
  rectfill( cam.x, cam.y + j, cam.x + px[j], cam.y + j + 1, 0 )
 end

end

---------------------
function screen_fade_in( fade_in_time, max_fade_in_time )
 
 local px = {}
 
 local start_x = 128 - 128 * ( fade_in_time / max_fade_in_time )
 
 for j = 0, 128 do
  px[j] = start_x
 end

 for j = 0, 128 do
  local vx = 10 + rnd(50)
   
  px[j] += vx
   
  rectfill( cam.x + px[j], cam.y + j, cam.x + 128, cam.y + j + 1, 0 )
 end
  
end

---------------------
-- views
---------------------

---------------------
-- front end view
---------------------
front_end_view = {}

---------------------
front_end_view.start = function()
 _init()
end

---------------------
front_end_view.update = function()
 title_screen.update()
 booms.update()
end

---------------------
front_end_view.draw = function()
 camera( 0, 0 )
 title_screen.draw()
  
 --print(time_held, cam.x+1, cam.y+1+6, 7)
end


---------------------
-- game view
---------------------
game_view = {}

---------------------
game_view.start = function()
 t = 0
 time_since_press = 100
 time_since_release = 100
 time_held = 0
 button_held = false

 trail.init()
 cam.init()
 player.init()  

 title_screen.active = false
 music(-1)
  
 player.anim_set = player.anim_sets[title_screen.selected]
  
 player.find_start()
 player.find_target()
 player.find_starget() 
 
 cam.snap()
  
 player.set_anim( player.anim_set.start_anim, true, false )
 player.vx = 0
end

---------------------
game_view.update = function()
 booms.update()
 player.update()
 cam.update()
 trail.update(player.x, player.y, player.anim[flr(player.anim_index)], player.anim_flip )

 if player.target_found_after_time > 1 or player.starget_found_after_time > 1 then
  if time_since_release < 0.2 then
   views.set_current( front_end_view, 0.25, 0.5 )
  end
 end 
end

---------------------
game_view.draw = function()
  camera( cam.x, cam.y )
  map( 0, 0, 0, 0, 16*16, 16*16, 0x10 )
 
  if not player.target_found and not player.starget_found then
   trail.draw()
  end
 
  booms.draw()
  player.draw()
 
  --print(player.x..","..player.y, cam.x+1, cam.y+1+6, 7)
  --print(player.vx..","..player.vy, cam.x+1, cam.y+1+12, 7)

  --print(arrow.scale, cam.x+1, cam.y+1+12, 7)

  
  
  local offset_y = 0
  local timer = 1 - (player.start_timer - 3)
  
  if timer > 0 and timer < 1 then
   offset_y = 7 - ease_out( timer, 0, 7, 1 )
  end
  print_outline("time:"..time_to_text(player.running_time), cam.x+1, cam.y+1-offset_y, 7, 1, align_left )
  print_outline("best:"..time_to_text(player.best_times[title_screen.selected]), cam.x+128, cam.y+1-offset_y, 7, 1, align_right )

  --print( "t:"..player.start_timer, cam.x+1, cam.y+1+18, 7 )
  
  --print( "target:"..player.target_x..","..player.target_y, cam.x+1, cam.y+1+18, 7 )
  --print( nx..","..ny..","..dist_mag, cam.x+1, cam.y+1+24, 7 )
end

----------------

views = {}
views.last_view = nil
views.current_view = front_end_view
views.fade_out_time = 0
views.fade_in_time = 0

---------------
views.set_current = function( new_view, fade_out_time, fade_in_time )
 -- do screen transition management here
 views.max_fade_out_time = fade_out_time
 views.max_fade_in_time = fade_in_time
 views.fade_out_time = fade_out_time
 views.fade_in_time = fade_in_time

 views.last_view = views.current_view
 views.current_view = new_view
end

---------------
views.update = function()
 if views.fade_out_time > 0 and views.last_view then
  --views.last_view.update()
  views.fade_out_time -= one_frame
  
  if views.fade_out_time <= 0 then
   views.current_view.start()
   views.current_view.update()
  end
  
 else
  views.current_view.update()
  
  if views.fade_in_time > 0 then
   views.fade_in_time -= one_frame
  end
 end 
end

---------------
views.draw = function()
 if views.fade_out_time > 0 and views.last_view then
  views.last_view.draw()
  screen_fade_out( views.fade_out_time, views.max_fade_out_time )
 else
  views.current_view.draw()
  
  if views.fade_in_time > 0 then
   screen_fade_in( views.fade_in_time, views.max_fade_in_time )
  end
 end
end

---------------------

function _update()
 t += one_frame
 
 button_update()
 
 views.update()
end

---------------------

function _draw()
 cls()

 views.draw()
 
 --[[
 if title_screen.active then
  front_end_view.draw()
 else
  game_view.draw()
 end
 --]]
end

__gfx__
00000000000000000000000000033300000000000000000000333000000333000000000000033300001110000011100000111000000000000000000077000000
0000000000033300000333000003f0000003330000033300000f30040000f304000000000003f000017771000166610001ddd100000000000000000078700000
000000000003f0000003f0000003f0000003f0000003f000000f30400000f304000333000003f00017aaa91016777d101d999410000000007777777778870000
00000000000b90000009b0009999b4440099b0000009b0000099b40000099b400003f000444b999917aaa91016777d101d999410000000007666666668987000
00000000004bb990009bb400000bb000090bb440004b9900090bb0000090bb00000bb000000bb00017aa791016776d101d99d410000000007888888888998700
0000000004093000009399400003999009039000040934000009344000009340003bb300000934400199910001ddd100014441000000000078999999999a9870
0000000009990400000409004440000904440900000904000090000400090004000334009990000400111000001110000011100000000000789aaaaaaaaaa987
000000000000040000049000000000000000090000094000009000000009000009900400000000000000000000000000000000000000000078999999999a9876
a0aaaa000000000000000000a0aaaa00000000000000000000aaaa0a000aaaa00000000004440000000000000000a00000000800000000007888888888998760
0aacfca000aaaa0000aaaa000aacfca000aaaa0000aaaa000acfcaa000acfcaa00aaaa0002224000044400004222207004222270000000007222222228987600
0aafff00aaacfca0aaacfca00aafff00aaacfca0aaacfca000fffaaf000fffaa0aacfca002211440022240004222271704222617000000007777777778876000
f999899f0aafff000aafff00f998999f0aafff000aafff000009899000009899aaafff00022222240221144042122d6004212270000000006666666672760000
00088000009980f00009800000088000009890f000089000009880000009880ff999899fa22222240222222404122d00004122d0000000000000000077600000
00eeeee00f08890000f88f0000eeeee00f08890000f88f000f0eee0000f0eee000088000007ddd608262227200422d7000042270000000000000000066000000
feeeee0ffeeeee00000ee000feeeee0ffeeeee00000ee00000eeeeef000eeeef00eeeee0071607170717d7160042261700042717000000000000000000000000
0000000000eeeef000eeef000000000000eeeef000eeef0000f00000000f0000feeeeef000700070007000700004407000004260000000000000000000000000
00000090000000000000000000000090000000000000000000090000000090000000000000dddd00000000000000000600000000000000000000000077000000
9009999909090090090900909009999909090090090900900999990000999990000000000dd1d1d000dddd00000000d600000006000000000000000078700000
9000919109009999090099999000919109009999090099990191900900191909090900900dddddd00dd1d1d00dddd05000dddd05000000007777777778870000
09009999090091910900919109009999090091910900919109999990009999990900999900dddd000dddddd0d1d1dd600d1d1dd6000000007666666668987000
0999948009009999090099990999948009009999090099990080994400000994090091910006600600dddd00dddddd600dddddd6000000007888888888998700
0999990099999480099994800999990099999400099994000000994000000994090099996dddddd6000660000dddd05000dddd050000000078999999999a9870
9400049044999400099994009400049044999400099994000000999400000999099994006000000000655d00000000d60000000600000000789aaaaaaaaaa987
000000000000940009494000000000000000940009494000009900090009900999999940000000000006066000000006000000000000000078999999999a9876
0d00000000000000000000000d00000000000000000000000dd0dd0000dd0dd000000000000000000000000000003b00000000b0000000007888888888998760
d00dd0dd0d0000000d000000d00dd0dd0d0000000d0000000fdddf0000fdddf00000000000000000000000000003bbb0000003bb000000007222222228987600
d00fdddfd00dd0dd0d0dd0ddd00fdddfd00dd0dd0d0dd0dd0d1d1d0f00d1d1df0d000000003bb00000000000003bbbbb00003bbb000000007777777778876000
0d0d1d1dd00fdddfd00fdddf0d0d1d1dd00fdddfd00fdddf00fffdd4000fffd40d0dd0dd03bbbb00000bbb00003bbbbb0003bbbb000000006666666672760000
0dddfff0d00d1d1dd00d1d1d0dddfff0d00d1d1dd00d1d1d0070ddd000070dddd00fdddf3bb7b7b003bbbbb0003b7b7b0003b7b7000000000000000077600000
0dddd0700dddfff00dddfff00dddd0700dddfff00dddfff00000dddf00000ddfd00d1d1d3bb7b7b03bb7b7bb003b7b7b0003b7b7000000000000000066000000
f4004f00fdddd0700dddd070f4004f00fdddd0700dddd0700d000d04000d00d40dddfff03bbbbbb03bb7b7bb003bbbbb0003bbbb000000000000000000000000
000000000000f4000f4f4000000000000000f4000f4f400000ddd0000000dd00f4dd447003bbbb0003bbbbb00003bbb000003bbb000000000000000000000000
0dd5d5d00d555dd0000001000000000000000000000000000101010000000000000001000dd33dd003b33b3003b33b3000000000044459900444599449994440
d52d2d2dd2ddd52d01010000000000002000000020020000010100000000000000010100d312253d3b9b92b33b9bb9b320000000429944244299442144499524
d212552dd25102d501010000000002001000201010000000000100500000000000000101d251022db222b22bb92b222b10002010552115243521152004515245
5d20025d5d20015d01000000000000010101002000010200000051010000000000000100322001533b2bb2bb3b23b2b301010020920101059201010201101129
5d2015d55d0101d50000000000010005521051055100500005000501000000000000000032010123b9b92b9303b92b9b52105105991001299910000000000249
d25102d5d215152d01000000000000525251525252500000005051000000000000000100d215152db2b22b2b003b2b2b52515252492112294921000000001245
5d22052dd2dd522d01000000000010022d2ddd2222505020011511500010011000000001d322332d3b2bb2b30003b22b233ddd22452522544425100000001594
5d20125d0d55ddd00000000000000525d5d555dd522510005510511551150155000000010d3dddd003b33b3000003bb3d5d5533d045994404920000000000594
d251025d0ddd55dddd55ddd00000022d00000010d25500000001000000000000667777660ddd533dd355ddd00000023d00000010d25500009102000000000034
5d20152dd225dd2122dd252d0000052d100000105d211000010101000051005165111156d233dd2122d3352d0000053d001010103d2110009220100000000129
d520152dd5211520025152d5000012d5000000005d200000010000010005000500ddd50035211520025152d50000123510100010532000009451000000002519
5d0101d5d20101020110112d000005d500000000d2100000010001000551055000111100d201010201101123000005d500301030d31000009410000000010249
5d20152dd2100000000002d5000101d501000000d2550000000000000105510000ddd500d3100000000002d3000101d300001000d25500009321010000101245
d12012d55d210000000012d50025222d01000000d221110000000100055105000011110053210000000012d50025222300100000322111004220152002521254
d25102d55d2510000000152d0000102d000000005d500000000001010100010001ddd5105d2510000000153d0000102d101030003d5000004992445329924424
d210155d5d2000000000052d0001552d00000000d225200001000100005100501dcccd515d2000000000053d0001552d10100010d22520000449994444999940
d251012dd10200000000002d00015225d55dd55d52550000010100010000500000000000310200000000003d03b33b30d55d333d101000109999444449550000
5d20122dd22010000000012d020005222dd22dd22221100001010101050105500000000032201000000001233b9bb9b32d332dd2101040002444299249211000
5d2105d55d5100000000251d0000150525200205255200000100010101055105000000003d51000000002513b222b22b25200205004000002520020554200000
d25101d55d100000000102d50005001550100200500010000101010000510000000000005d100000000102d33b2b32b350100200000010005010020094100000
d210152d5d210100001012d500200000000005001505000001010000510500006677776653210100001012d5b9b22b3000000500001010100000050099550000
d122212dd22015200252125d000000000100020000002000000101000550055065111156d220152002521253b2222b3001000200401000100100020049911100
d2dddd2dd252dd522d22dd2d000000000000000002000000000101010100510501ddd510d352dd532332dd2d3b22b30000000000001040100000000044400000
0d5555d00ddd55ddd5dd55d000000000000000000000000001000101000105001dcccd510dd333ddd5dd33d003bb300000000000000000400000000042252000
0d555ddddddd555ddddd55d001110151010101010010001001000101210002112100021103bb303003bbbb300525121005251210052512100000000000000249
d2ddd5252212ddd55521dd2d0511510005050101051001000001010125101152251011523b92b3b33b3223b35dd5d1d15dd1ddd15d15ddd12000000000000944
d2510222125102122252525d001505000005050101000510000001001d22522d1d22522db9222b3bb329923b1551515215525252155151521000201000009949
5d201100020000201100152d00500001010000010000001000010000d5d125d5d2d1d5d5b2222b2bb292222b21d1d5112d1dd1d12dd1d5110101002000000549
5d55002010051101000102d5001001010100000100100050010101001d5d5d5d1d5d1d5d3b22bb2bb222222b5d1d15d25dd1d5125d1dd5125210410500010194
d205152222152522212252d50001010100000500005100100100010111d5d1d111d111d103bb33b3b322223b2552125125521251255152515251425900254444
d12dddd555ddd25552dd252d01010100050100000101010001010100011d11d101d010113b22b3303b3223b35dd1ddd15dd1d1d15dd5d1d12994449900001049
0dd5555ddd555ddddd55ddd001010000000100000101010001000000010d01010100100103bb300003bbbb300211211001121110012112109449944400015549
a7a4a4a7a4a784666666666666164444444444444444444426656566653765656537676737766755356767676776676767656767677667766745676567162665
65656545456565656565656565474747656565656565652465656565650565655565656565656565242465656565c7d6d66565d465d6656565f7656565f60000
a497a7a7979775846766656566665757376637666637666665656566666565656567676667676755356767676767676767656565676767676745454567656565
65656566456666454545656565474747652424656565652424656565650565655565652424656565652424d62465c765d66565d4656565d665f765d665f60000
a797a7a7a797a77484c566575766c566756666575757655766656565666565651467666667676755356774676767746767676574656465656566666466656565
666666656565646565656565a1656565656565656565650424242465650524655565242424242465c765d6656565c7652465e4e6f4654765e4f4656565e5e7e7
97a7a4a7a797a4a764846666575766666657c5666675655766656565656565656667676714677655354646464646464614676714464646464646464646152514
6645651465d7d7c7c76565c7b7c76565c7d7d7c76565650665656565650524655565246565652465c765246565c7c7656565f600f7656565e5f565d6656565f6
a7a797a4979797a4a47466c564667666661546464646464646256565142465646567676737676755356767676767676737656547656567454545676767553565
4545656565c765c7656565656565656565c765c76566656565656507270624655565656565656565c7652447c7c7474747e4000000f4654747d46565476565f6
a7a497a797a79797a4a78464a4a4a757665500000000000000356565246565146565656565766555356767456767676767646767676764676765676467553565
66666665656465c7656624242424666565b765656566242424246565656524651546464646464646c765d624c7474747e40000000000f46547656565d465d6f6
a7a497979797a7979797979797a7a776575500000000000034266565666665376565146565656555354614454514464646464646464646461465671446553514
6565146566b7c7d7656566666624246565d765656666656565242465652465155665656565656565c7654724c7475747f6000000000000f447476447d44747f6
a7a497a7a4979797a797a797a7a7b657c55500000000003426376566666565656584246566656555356767674537676767676745677567454765676567553565
6565656566c700c7656565652424246565c7656566651465656524242465655565656565246565c7c765474747d65747e500000000e7e7f5e6e6e6e6d44747f6
a79797979797a7a7a7a797a7b6846666661644444444543565656566846565656565656566656555356767674567676767646765676767646774674767553566
6524246666b700b7c765656565656565c7c7652466656565652465246515465665656565246565c7c76547474757d64747e5e7e7f54747f747d64757474747f6
a7a79797a7a7a7a7a7a497a784665766c56637656584553565656565656514656665656466666555354646146767044646464614464646464646464646553566
2424646665c70000c7b76591656565c7c76524246666662424656565655565652424c765246565c7c7c7c7c7c7c7475747473747474747f74747574757d647f6
a7b4a4a4a4a7a49797a7a4a4c56657575765c565c566553565651465656537656684651465666555356767676767064646464646464614656514464646553566
241414146565c7c765c7c7d7b7d7b7c7652424656565646565656565155665242465c765242465c7c7c7c7c7c7c7474757575757d64747f747476247474764f6
a7a7a7b4979797a4a497a4b666656666646664666666553565653765656565656665653765846555356767674567676704676767656537656565656565553565
65656665656565656565c7c7b7c7d724242465144646464646146565554724246565c765652465c7c7c7c7c7c7c7c7c7c75757d64747e4f44747d4d4d4d4e4e6
9797a7a7a497a4a7a7a4a78466a74646464646464646563565656565666565146565656645656555354646146767140405040727656565656565656565553565
2465656666666665242465656565656565651414656565656514656555476565c7c7c7c7c76565656565656565654747c74747474747e5f5656765656565f600
a7c5663766c566376666656566974444444444444444442665656665656565656565656566656555356767646767670505064646464604656514464646162674
6465656565656665652464656465656565141465666666656514c7c7c7c76565c7c7c7c7c7656524674545676765d647c74747e4e6f46565d6676565d665f600
a76666576565c566666466c566a77676753757575765653766656514656566454565651465656555356767144646460505656565656506656565656565071717
1717171717171717171717171717171717276565662465146565c7c7c7c76565c7c7c7c7656524246565456565654747474747f600f765646565d4656765e5e7
9766c5c56566666697a7a497a4a77675374757476565656566666537656566454545656565656555356565656565650505144646464607172765650717172765
376537650465653765656565d46565656565656566242465656565c7c7c7656565656565652424656565d4d4e4f44747d64747e5e7f5e6e6e6e6d465676565f6
9765666566b4a7a7b665663765973737476565666566666565656565654545664545454565656416266565656665650506656565656514656565656565650465
656565650665656564656566d4656565d66565d665656665656565c765476565656767242424d46567d66565e5f5d447474747e4f46565656565656767d665f6
a7656665666666656565656665a75764656665656666656565656564656565656565456565650717171717172765650565656665072715256565242424240565
652424652465650727652466d46566d6d665666666666665656565c765476565656724656565d465676767676565d447474747e5f56567d665d46565646565f6
a76565c5665766656565c5656597a497656565656565646595a595a5656565651465656565656515464646256565650565656665656555356524656564650665
242465652424650727652465d4656666d66665e4f44646464646c7c76547d4d4d4d4d4d4d4d4d4d4d4d4d465656700e4f4e4f4e4f465656765d4d4d4d4d4d4f6
97666466665766a46566666565a7a4a7c4c4c4c4c495c6a596a696a695a564451465651465656516444444266565040646464646464655356624650717172724
246507171717171727666665d4656665656665e5f5656565656565656547d447656565656767656565d46565d6d665e5f5e5f5e5f565836565656565656565f6
97a7b665666666a76565646665376565656537656596c4a63765653796a695a51465656565656515256565656665056565656565656516266665072765656524
666505656537656565666565d46565d6d6666666666666d6d6d6d6656547d44765656567676767d665d46565d66765e4f4e4f46565d4d4d465646565d66565f6
a466666657b49797a797a76565c5656565c565c565b5653765656565653796a66565656565656555356565656665056565651446464614656665046565666666
656506656666662424246565d4656565d6d6656564656565656565646547d44765d465676765d4d665d46567656565e5f5e5f56565656565d4d4d465676765f6
a4666557666666b4a7a49765656565a76665656565b5656565666666656565376565656564656555354614656665056565656565001525656565066565656565
071727656665140466652465e4e6e6e6e6f4e6e6e6e6e6e6e6e6e6e6e4e6f44765d465656765d4d665d465d665d4d4d4d4d4d465656567d6653765656765e4f6
9764576665666566a7a7a7a4656565a76665c56566b5656666666565656565656507171717172716266565456504066565144646155635656565072765a26565
071717276666650565656465e5e7e7e7e7f56565656565d6d6d6d665e5e7f54765d465656564d46765d4656767656537656565d4656567d6d6d6d6d66765f6f6
a797a4a7b666c566663766b4a497a7a76665656565b565666565656565656595c6c6c6a565656565656565654505656565656565550035656566650717171717
17172765656665054646464646464646462565d665656565656565656537f74765d4e6e6e6e6d467d6f66565d6676765d6656565d4d4d465d64545d6d665f6f6
a4663765666566666457576666656697c4c4c4c4c4a66565656565656595a596c4c4c4a665242465651446464606656566666665164426046566656565654545
65652424246665054444444444444444543565d665e4f46565d6d6d66565f7476565d6d6d665d46767f66565656565e4f465d665d665f665656565656564f6f6
a7666666c56665b49766665766c5669737656537656565646595a595a596a6656565656565652424656565656565656545656665656565056566246565656666
66242465071727066565656537656537553565d665f6e4f4656565656465f74765d6d6676765d46567e5e7e7d4d4e4f4e4f465656565f667d66565d4d4d4e5f6
a7a7b6665757666697a7a7a497a497a76565656565656595a596a696a66565656566246565656524456465666666651446461465666565056564242424666665
656565072737656565242424242465651626656565f6f6e4e6f4e6e6e6e6e6e6e6e6e6e6e6e6e66567d6d66565e4f4e4f4e4f4646565f66564676765376565f6
a737665757666664a797b6663766b4a79494949494656596a6656565656524656524246595c6c6c6c6c6c6a56565656565656524246565061546462524246565
0717172765656566666666666524246565e4f465d6f6f6f600f76565d665d6d66767676765d6646567d66565e4f4e4f4e4f4e4f4e4f4e4f4e4f46567d66765f6
9766c55766b497a797a46666c565c5b56565656565652465656524246624241465656565d500000000000036c6a5242465656565154646465600003625656565
65656565656666666565656565926565d6e5f56565f6f6f6e4e6e6f4656767656565e4e6e6e6e6f4656565e4f4e4f4e4f4e4f4e4f4e4f4e4f4e4f465656565f6
a466656465666665656664669365c5b565c565c565656524646564656565651465646565d5000000000000000036a56564651546560000000000000036256565
65656465666665651546e6e6e6e6e6e6e6e6e6e6e6e6f6f6f60000f7e6e6e6e6e6e6e6e6e6e6e6e6e6e6e4f4e4f4e4f4e4f4e4f4e4f4e4f4e4f4e4f4650365f6
a7a7a7a4a4a4a7a4a497b6b4a7b6b497a49797a495c6c6c6c6c6c6c6c6c6c6c6c6c6c6c65600000000000000000036c646465600000000000000000000364646
46464646464646465600000000000000000000000000f6f6f60000f700000000000000000000000000e4f4e4f4e4f4e4f4e4f4e4f4e4f4e4f4e4f4e4f4e4f4f6
__gff__
008080808080808080800000000000008080808080808080808080808000000080808080808080808080808080000000808080808080808080808080800000001b1f101014101010101f1f1f141f13191a13191810121010001319181012161c1e161c101110101000161c1f1110111217151d101010101e1e1f1f1f1f1f1418
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
5344445500000000000000004344444444444c4c4c4c4c4c4c4c4c4c4c6a6144444444444444444444444444444444444444444444444444444444444444444444445d005b777877785078785500000000000053775077555377550000537855000000537877777755007c6f005e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f5e5f6f
5356736144444444444444446273545673565656565656735656565642735656565673415656415656565656565673415656565656567356565656565673567356565d005b747474747774747778787778777778745000507856777777785678787777785656565678787b6f00437e7e7e5f5656565e7e7e7e7e7e7e7e7e7e6f
5356565666565673665666565054755656465656565656565656565646475646565656565656565656565656565656565656565656564856565656747474745656565d005b745656747474747474747474747474747777785656565656565656565656565656565674747d6f007f74745673565456565454547356567356566f
534609560874547474566656505654707171717171717171717171717172595a565656565656666656484056565666747474565656564656565656565656567456565d005b747456567474747474567456745474747474745667565656675656566754545456565674747b6f007f74745656546d565654564256546d4256566f
5364646464646464515267565056567554565656425673565442425656565d5b56566666664242425648505656747474665656415656596c5a5656565656565656565d005b7474745674596c5a51527474745454545674565656567474565656565656565656565674747c5e7e5f7474565454567b56566d424256564256566f
5356545454566656555356675056424242565656545656564254565642565d5b565666664841425666485041417456564156565656565d005b465674747474747474694c6a515274747461446261627428747474545474567474747456567b7b7c7b7c7b7d7c7b7c74747d56565656546d4656567c16565646424242426d566f
5354546656545756555356665054545656515a70717171717171717256565d5b56486648664256565656505656565656565656565656694c6a596c5a747474596c5a596c5a6162745674745673747441414141596c5a74745454567451527d56565673565656565674747d5656565654567b7b7c7b7c7c7b7b7c56565656566f
5356566675745656616257665046427546555b56565656734073565642565d5b56564242666666745656505656564156565641565656596c5a5d005b5656745d005b5d005b7474417474747456567474747474694c6a74677454547455535656565656565656565674747c5656545456567c5656565656565656566d5656566f
5356745451525456567454565164646464655b56565656425056565656565d5b565646565656747446565056565656565656565656565d005b694c6a745674694c6a5d005b747470717171717274747474567474596c6c5a7474567455535656567d56567d56565667747c5646565454567b5656566d5642425656565642566f
5354567655534757567456765500000000005b56544056546056564056565d5b6c6c6c6c6c6c6c6c6c6c5b5656747474747456465656694c6a5656745656567474745d005b747474747474745152596c5a567456694c4c6a5152747455535656567d7d7b7c7b7d7c7b7b7d7c7d7c5654567b565642565656425454545642566f
5356667655536464646464646144444444446a66665056565656565056425d5b4c4c4c4c4c4c4c4c4c456364646464646464646464645256565656565674567456745d005b5656596c5a747461625d005b74745656735656616251525553565674565656565656565656565656565656567c565442564d56564242425656566f
5366677655535656466676465666666654565654466056565656566056565d5b567356565656735656694c4c4c444444444444450000535656565656747446565674694c6a74565d005b74747474694c6a74747474565656735661625553565674745656565454545656545456564256567c565442564d566d5656425642566f
5344444455636464526464645164646464645a6c6c70717172596c5a56565d5b5656747474745656565656565656565656565655000053565656567474596c5a7474596c5a7456694c6a747456747474745152596c5a5674565656565563525656745656565656565656545456425656567c565456564d5656564d565642426f
5354566655000000535474565543444444455b5654566666565d005b56425d5b56565666666674747456565656565656565656550000535656515274745d005b74745d005b7474596c5a7474565674747461625d005b56565656565655005356745656567b7b565642424242425654567c7b564256564d5656564d565642426f
5356677455000000535667746162746666555b565656564266694c6a4656696a56565656566666565656596c6c6c6464525656550000535656555356565d005b5656694c6a74745d005b596c5a745674747474694c6a5656415656565500535674745656567d565656425656465654567b56565656564d56425656565642426f
536674755543444462566656747466675655635a5656406666707171717171725656596c6c6c6c6c6c6c650000000000635256550000535656555356565d005b5656596c5a5674694c6a5d005b74567474596c5a56565656565667565500537474747474747b5656564256567c5654567c566d56566d4e4f566d56564d42746f
537467756162747456567456545656565655005354565066426666667366565656565d00000000000000000000000000005356550000535656555356575d005b57565d005b5674596c5a694c6a747456745d005b56675656565656565500537474747474747d565656424242565656567b56566d56565e5f4d5656564d74746f
53747474747374565456546756565656565500535656506c6c6c6c6c6c6c6c6c6c6c6543444444444444444445000000005356550000535656555356565d005b56565d005b5656694c6a74747474745674694c6a51525656415656565500537474747b7d7d7b565656565642425656567c565656565656564d4654565674746f
536774677474755447674754565656565455005356566044444444444444444543444462735656565356567355000000005356550000535656555356565d005b5656694c6a74747474596c5a7474565674747474616256565656565655005374747474747b7b56567d565656425656567b56565656566d564d4d54425674546f
64646464646464646464646452565656755500535656565656565656545656555356565656565656535656565500000000535655000053565655535656694c6a565655537474747474694c6a7474567474747474745152565656745655005356567456567d7b5656567474747474747d7b56564d4d565656564d46425454466f
444444444444444444444400535656567555005356745656567456745656565553565656567454565356565661444444446256550000535656616256565556565656555374745774747451527474565656747456746162565656745655005356567474567c7d5656567442424274747b5656564d56565656564d67674647676f
5342667366736666736666555356566767550053565674565656565674565661625656565654747453565656565656565656565500005356565656565655564674425553747657747474555374747474515274565674515256567474550053567c5656567b7c56564242747474747b7c566d564d5656564d4d4d4d675767576f
53665675667475667575665553565656745500535656745656565656747456565656565651525656537456565656565656565655000053465667565651646464646455535674747451525553515274745553745656746162675656745500535656565656567b56564274747474747b565674564d4d56565656564d4d4d4d4d6f
5376665c565c66667456665553565656745500535656745651525654565656565674565661625656537456565164646464646465000063646452565655565774747655537456747455535553616251525553745651645251527456745500535656562056567d56424274747d74747c56567456564d56566d56565656736d6d6f
53766666665c6675665c765553646464645500636452565661625656565152565656565673735656405656566144444444444444444444444462566755565676767455537456747461626162747461625553747461446255537456745543626464646464647b56425674747474747b74747474744d565656565646565656566f
5346663a565c66756666765553757456565500000053565673565674566162565656005656565656605656565673565656565673565656737673767655565676767461627454567474745574747474745553747474737455537456745553565656565656565656565674744274747c7474744e6e4f545656564e4f56566d566f
79797a7a485656667566665553477556566144444462565656745674565656565656767676767651527071717171717171717171717171717171717172565674747474747454565674745574567474745553745674747455537456745553565656565656565674747474744274747c7442746f4d7f56564e6e6e4f565656566f
7a4a7a4a466666665c66665563527556565656735656747474565674566756675651646452767661627676767656567474745676765656747474747476740676747674747454745674575574565674745553745656747455536774745553565656567d56745674567c74744274747c7442745e4e6e6e4f5e7e7e5f565456566f
7a79794a7a4866666656565500537575567456745656566756565674745656565655000053567676767474565656565656745656565152567474747474745152747674745152747474425574745656746162747456427461627474745553565656567d56747474565674424274747c746d42746f00007f56567354565656566f
7a797a4b7a4875756666565500635267745656745656565656565656565152565655000053767674747676767651525656565656745553747474747474745553747476745553767674425574745656747474565656427474737474675553565656567d56565674747474424274747b744642746f00007f5656565656566d566f
7a797a7a7948665c75665c6100006352741074565618675656565656566162565661444462767676767676767661624656745656466162465676516464526162747446746162007676575574747474747474747474747474744674746162565656465656565646565646747474467b7b7c74745e7e7e5f56564e4f465656566f
797a4a7a4a477666755c666661000063646464646464646452707171717171717171717172646451526464646464646464646464646464646464646464515264646464646464646464646464646464646464646464646464646464646440565651646464646464646464646464647c737474744d73565656565e5f6e6e4e6e6e
__sfx__
000100001d27020260222602226022260202601d2601a27016260112500e2500a2500624005230032200122002100012000110001100060000500005000050000500006000060000600007000040000400004000
000100000f2700f2600f2601026011260112601226014270152601b2501d25023200292002b2002a2002a20002100012000110001100060000500005000050000500006000060000600007000040000400004000
010300002817028170281702817028170281702817028170281702817028170281002610026100261002610000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300003427034270342703427034270342703427034270342703427034270342703427034270342703427034270342703427034270342703427034270342703427034270342703427034270342703427034270
010300003427034270342703427034270342703427034270342703427034270342703427034270342703427034270342703427034270342703820038200382000020000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000c4430c4030c4430c4030c443180030c443000000c443000000c443000000c443000000c443000000c443000000c443000000c443000000c443000000c443000000c443000000c443000000c44300000
010c00000c4430c4030c4430c4030c663180030c443000000c443000000c443000000c663000000c663000000c443000000c443000000c663000000c443000000c443000000c663000000c443000000c66300000
010c00000c4430c4030c4430c4030c663180030c443000000c443000000c443000000c663000000c663000000c443000000c443000000c663000000c443000000c443000000c6630c6630c6630c6630c6630c663
010c0000217622176221762217622176221762217622176224762247622476221702217622176221762217022176221762217622176221762217622176221762237622376223762217022176221762217620c602
010c00002176221762217622176221762217622176221762247622476224762217022176221762217622170221762217622176221762217622176221762217622676226762267622170221762217022176221702
010c00002176221762217622176221762217622176221762247622476224762217022176221762217622170221762217022476221762217022376221762217022676224762267022176224762217022176221702
010c00002d7623076234762397622d7623076234762397622d7623076234762397622d7623076234762397622b7622f76232762377622b7622f76232762377622b7622f76232762377622b7622f7623276237762
010c0000297622d7623076235762297622d7623076235762297622d7623076235762297622d76230762357622b7622f76232762377622b7622f76232762377622b7622f76232762377622b7622f7623276237762
010c0000217622176221762217622176221762217622176224762247622476221702217622176221762217021f7621f7621f7621f7621f7621f7621f7621f762237622376223762217021f7621f7621f7620c602
010c00001d7621d7621d7621d7621d7621d7621d7621d762217622176221762217021d7621d7621d762217021f7621f7621f7621f7621f7621f7621f7621f762237622376223762217021f7621f7621f7620c602
010c00002d7623076234762397622d7623076234762397622d7623076234762397622d7623076234762397622d76221702307622d762217022f7622d762217023276230762267022d76230762217022d76221702
010c00002d7622d7622d7622d76230702307622d7622b7022b762307022b762397022b7622b7622b7022b762297622f70229762377022676229762267622b7622b7022b7622b762397022d7622b7622b7022b702
010c00002b762307022b762397022b7622d7622b7622b7022b762307022b762397022b7622d7622b7622d7622b7622f7022b762297022676229762267622b7622b7022b7622b762397022d7622b7622b7022b702
010c0000157620c762107620c762107620c762157620c76213762177620e762177620e76217762137621776211762157621876215762187621576218762117621370213762137621570215762137621370213702
010c000013762177620e762177620e76217762137621776213762177620e762177620e762177621376217762137621770213762117020e762117620e762137621370213762137621570215762137621370213702
010c00001f762217621f762397021f762217621f7622b7022376224070237623970223762247622376224762287622f7022f762297022f7622b762287622b7622b7022b7622b762397022d7622b7622b7022b702
010c000013762177620e762177620e762177621376217762177621a7621d7621a7621c7621a762177621a7621c7621f762237621f762237621f7621c7621f7621370213762137621570215762137621370213702
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01160000213752130521375213752437521375217012170121375247012137521375263752137521701217022137521701213752137524375213752170121701213752670121375213751f375213752170121702
011600002107337603376232107323673376033762321073210733760337623210732367321073210733762321073210033762321073236732130337623210732107326701376232107323673210732107321073
011600001577015770157701577018770157011570115701157701577015770157701a77015700157001570015770157701577015770187701570015700157001577015770157701577013770157701570015700
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000021332213022133221302233322133223332183022133221302213322130226332243322633237302213322130221332213022833226332283322833228332283322833228332283323b3022830226302
010c00001533215332153321533217332173321733217332153321533215332153321a3321a3321a3321a332153321533215332153321c3321c3321c3321c3321c3321c3321c3321c3321c3323b3022830226302
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 0a424344
00 0a424344
01 0b424344
00 0b424344
01 0b424344
00 0c424344
01 0b0d4344
00 0b0e4344
00 0b0d4344
00 0b0f4344
00 0b121044
00 0b131144
00 0b121044
00 0b0f1444
00 0b171544
00 0b181644
00 0b171544
02 0b1a1944
00 41424344
00 41424344
01 1e5f4344
00 1e424344
00 1e1f4344
00 1e1f4344
00 1e1f2044
00 1e1f2044
00 5e1f2044
00 5e1f2044
00 5e1f6044
02 5e1f6044
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
04 28294344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

