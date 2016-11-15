pico-8 cartridge // http://www.pico-8.com
version 7
__lua__
-- bunyan's rage te
-- b vaughn, @morningtoast

-- v2.0, june 2016
-- brian vaughn, @morningtoast

debug=false
t=0
screen={x=0,y=0,w=128,h=128}
screen.window={pos={x=0,y=0},hitbox={x=0,y=0,w=128,h=128}}
clock=0

cart={}
cart.update=function() end
cart.draw=function() end


explode={all={}}
explode._update=function()
	update_psystems()
end
explode._draw=function()
	for ps in all(particle_systems) do
		draw_ps(ps)
	end
end



--
-- background
--
background={layers={}}
background._init=function()
	add(background.layers,{ax=0,bx=128,speed=2,y=100})
	add(background.layers,{ax=0,bx=128,speed=3,y=106})
end

background._update=function()
	foreach(background.layers, function(layer)
		layer.ax-=layer.speed
		layer.bx-=layer.speed
		
		if layer.ax<=-128 then layer.ax=128 end
		if layer.bx<=-128 then layer.bx=128 end
	end)
end

background._draw=function()
	rectfill(0,110,128,128,1)
	for n=0,16 do
		nx=n*8
		ny=n*8
		sspr(0,32,8,8,nx,98,8,8)
		sspr(0,32,8,8,nx,106,8,8)
	end
	moon._draw()
	foreach(background.layers, function(layer)
		map(0,0, layer.ax,layer.y, 16,3)
		map(0,0, layer.bx,layer.y, 16,3)
	end)
end


moon={alive=false,x=130,y=100,t=0}
moon._update=function()
	if moon.t==900 and moon.y>-32then moon.alive=true end
	if moon.alive then
		moon.x-=.25
	end
	
	if moon.x<=-32 then 
		moon.t=0
		moon.y-=15
		moon.x=130
		moon.alive=false
	end
	
	moon.t+=1
end

moon._draw=function()
	if moon.alive then
		spr(68,moon.x,moon.y,2,2)
	end
end




--
-- mobs
--
mobs={all={},alive={}}


mobs._update=function()
	-- check mob spawning
	foreach(mobs.all, function(mob)
		if waves.time==mob.spawn or mob.spawn<=0 then 
			add(mobs.alive, mob)
			del(mobs.all, mob)
		end
	end)

		
	-- move and action for active mobs
	foreach(mobs.alive, function(mob)
		
		
		
		-- check when to shoot
		
		if mob.shootnum<=mob.shootlen then
			
		
			local thisshoot=mob.shoot[mob.shootnum] --has t=frames, ang=angle

			if thisshoot.t and mob.timer.shoot==thisshoot.t then
				
				-- fire!
				
				--[[ if an x/y is provided, target that, otherwise just use provided direction angle
				if thisshoot.x and thisshoot.y then
					thisshoot.ang = atan2(thisshoot.x-mob.x, thisshoot.y-mob.y)
				end]]
				if player.state==1 then
					if thisshoot.target then
						local txy=thisshoot.target()
						thisshoot.ang = atan2(txy.x-mob.pos.x, txy.y-mob.pos.y)
					else
						
					end
					
					-- shoot bullets through pinwheel
					--sfx(3)
					pwg.shoot(mob.pos.x, mob.pos.y, thisshoot.ang, mob.cfg)
					
					mob.shootnum+=1
				end
				
				mob.timer.shoot=0
			end
			
			mob.timer.shoot+=1
		end
			
		
		
	
		-- check if new route, get calculations
		local segment=mob.routes[mob.routenum]
		local rndv=0
		if mob.lastroute~=mob.routenum then
			local segment=mob.routes[mob.routenum]
			
			if segment.s > 0 then
				if segment.tx and segment.ty then
					segment.ang = atan2(segment.tx-mob.pox.x, segment.ty-mob.pos.y)
				else
					if segment.v then
						rndv=rnd(segment.v)
					end
				end
				
				mob.nx=cos(segment.ang+rndv)*segment.s
				mob.ny=sin(segment.ang+rndv)*segment.s
				
				mob.lastroute=mob.routenum
			else
				mob.nx=0
				mob.ny=0
			end
		end
		

		
		-- move mob
		mob.pos.x+=mob.nx
		mob.pos.y+=mob.ny
		
		-- flip to alive state when new mob comes into the viewport for the first time
		if not mob.alive then
			if collide(mob, screen.window) then mob.alive=true end
		end

		if mob.timer.route==segment.t then
			mob.routenum+=1
			mob.timer.route=0
			mob.nx=0
			mob.ny=0
		else
			mob.timer.route+=1
		end

		
		-- bullet collisions
		mob.flash=false
		foreach(player.bullets, function(bullet) 
			if collide(mob, bullet) then 
				
				mob.hp-=min(.5*player.power,1)
				del(player.bullets, bullet)
				
				if mob.hp<=0 then
					sfx(1)
					mobs.kill(mob)
				else
					-- make em flash
					mob.flash=true
				end
			end
		end)
	
		-- remove from queue when it goes off screen
		if offscreen(mob.pos.x, mob.pos.y) and mob.alive then 
			mobs.die(mob)
		end
		
		
	end)
end

mobs._draw=function()
	foreach(mobs.alive, function(mob)
		if not mob.ani then mob.ani=0 end
		
		
		
		if not mob.flash then
			
			if mob.style then 
				if mob.style==6 then
					pal(4,5) --grey squrriel, red band
				elseif mob.style==7 then
					pal(4,7) --white squrriel
				else
					pal(8,mob.style) 
				end
				
				
				
			end
			
			if mob.ani<2 then
				spr(5,mob.pos.x, mob.pos.y,2,2)
				pal()
			else
				spr(7,mob.pos.x, mob.pos.y,2,2)
				pal()
			end
			mob.ani+=1
			if mob.ani>=4 then mob.ani=0 end
		end
		
	end)
end


-- when player kills mob
mobs.kill=function(mob)
	mob.alive=false
	player.score+=shr(mob.cfg.points,16)
	make_blood_ps(mob.pos.x+2,mob.pos.y+10)
	
	mobs.die(mob) 
	if mob.item then
		bonus.create(mob.pos.x,mob.pos.y)
	end
	
end

-- when mob just needs removed from queue
mobs.die=function(mob)
	del(mobs.alive, mob) 
	waves.active-=1
end




--
-- bonus item drop
--
bonus={all={}}
bonus.create=function(x,y)
	add(bonus.all,{pos={x=x,y=y},hitbox={x=0,y=0,w=7,h=7}})
end

bonus._update=function()
	foreach(bonus.all,function(o)
		o.pos.x-=1
		if offscreen(o.pos.x,o.pos.y) then del(bonus.all, o) end
	end)
	
	
end

bonus._draw=function()
	foreach(bonus.all,function(o)
		spr(15, o.pos.x, o.pos.y, 1,1)
	end)
end





--
-- pathing
--
routes={all={}}

routes.use=function(routeobj, mobobj, shoot, ox, oy, custom)
	local config={spawn=0,replay=1,incx=0,incy=0,delay=0,item=0}
	
	if custom then
		for k,v in pairs(custom) do config[k]=v end
	end
	
	--if config.replay>0 then config.replay+=1 end

	for n=1,config.replay do
	
		--if n>1 then config.delay=0 end
	
		local mob={pos={}}
		mob.item=false
		mob.cfg=mobobj
		mob.shoot=shoot
		mob.hp=mobobj.hp
		mob.spr=mobobj.spr
		mob.shootnum=1
		mob.shootlen=#mob.shoot
		mob.routes=routeobj
		mob.routenum=1
		mob.lastroute=99
		mob.offset=config.spawn
		mob.style=mobobj.style
		mob.spawn=config.spawn*n+config.delay
		mob.alive=false
		mob.pos.x=ox+config.incx*n-1
		mob.pos.y=oy+config.incy*n-1
		mob.hitbox=mob.cfg.hitbox
		mob.nx=0
		mob.ny=0
		mob.flash=false
		mob.timer={route=0, shoot=0, int=0}
		
		if n==config.item then mob.item=true end
		
		
		
		add(mobs.all, mob)
		waves.active+=1
		
	end
	
	
	
	
end




-- named path routes
--
--[[
	-- use -1 as frame time to be endless
	routes.routename=function()
		local paths={}
		add(paths, {ang=.5, t=15, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
		add(paths, {ang=.5, t=60, s=0})
		add(paths, {ang=.5, t=-1, s=3})
	
		return paths
	end
]]

-- in from right, stopwait, out to left
routes.stutter=function()
	local paths={}
	add(paths, {ang=.5, t=15, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=.5, t=60, s=0})
	add(paths, {ang=.5, t=-1, s=3})

	return paths
end


routes.centerstop=function()
	local paths={}
	add(paths, {ang=.5, t=25, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=.5, t=300, s=0})
	add(paths, {ang=.5, t=-1, s=2})

	return paths
end

-- in from right to left nonstop
routes.express=function(sp)
	local sp = sp or 2
	local paths={}
	add(paths, {ang=.5, t=-1, s=sp}) -- ang=direction angle, t=frame time in direction, s=speed

	return paths
end


-- right to left, exit up
routes.glideup=function()
	local paths={}
	add(paths, {ang=.5, t=15, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=.625, t=25, s=2})
	add(paths, {ang=.5, t=30, s=2})
	add(paths, {ang=.151, t=-1, s=3, v=.05})

	return paths
end

-- up, stopwait, exit left
routes.upstoptop=function(rev)
	local a = rev or .25

	local paths={}
	add(paths, {ang=a, t=40, s=3}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=a, t=90, s=0})
	add(paths, {ang=.5, t=-1, s=3})

	return paths
end


-- up, stopwait, exit left
routes.treeline=function()
	local paths={}
	add(paths, {ang=.25, t=10, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=.25, t=90, s=0})
	add(paths, {ang=.75, t=-1, s=2})

	return paths
end

-- left and down
routes.cliff=function()
	local paths={}
	add(paths, {ang=.5, t=20, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=.625, t=-1, s=2})

	return paths
end

-- left and down with variance 
routes.wanderdown=function(rev)
	local a = rev or .562

	local paths={}
	add(paths, {ang=.5, t=20, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=a, t=90, s=1, v=.15})
	add(paths, {ang=.5, t=-1, s=1,v=.15})
	
	return paths
end

-- left and up
routes.climb=function()
	local paths={}
	add(paths, {ang=.5, t=30, s=1}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=.375, t=-1, s=2})

	return paths
end


-- zigzag
routes.zigzag=function(up)
	local r2=.88
	if up then r2=.10 end

	local paths={}
	add(paths, {ang=.5, t=35, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=r2, t=25, s=2}) -- ang=direction angle, t=frame time in direction, s=speed
	add(paths, {ang=.5, t=-1, s=2})

	return paths
end





--
-- waves
--
waves={all={}}
waves._init=function()
	waves.all={}
	waves.current=1 --starting wave
	
	waves.start=30 --frames to launch first wave
	waves.next=210 -- frames to wait before next wave launches
	waves.time=0 -- cycle clock
	waves.active=0 -- number of active mobs, used to determine when to launch next wave
	waves.limit=waves.build() -- number of waves
	
	mgunshot={
		{t=20,target=player.target},
		{t=4,target=player.target},
		{t=4,target=player.target},
		{t=20,target=player.target},
		{t=4,target=player.target},
		{t=4,target=player.target},
	}
end


-- launch a wave
--[[
	--routes.use(pathfunc, mobobj, shotmatrix, originx,originy, settings)
	routes.use(routes.path(), mob, {
		{t=120,ang=.75,target=player.pos}, --t=time to fire, ang=direct angle, x=targetx, y=targety, target=position object
	}, 130,20, {replay=2,spawn=12,incy=6}) -- spawn=frames to wait before/between spawn, replay=number of additional (excluding), incx=increment to x, incy=increment to y
	
]]
waves.launch=function()
	waves.time=0
	waves.next=210
	waves.all[waves.current]()
end



waves._update=function()
	if waves.active<=0 then waves.active=0 end

	if waves.start>0 then
		if t==waves.start then
			waves.start=0
			waves.launch()
			bosswait=-1
		end
	else
		--if not boss.active then boss._init() end
		
		if waves.active<2 or waves.time>=waves.next then -- wait until 2 mobs or waves.next seconds to launch
			waves.current+=1
			
			if waves.current <= waves.limit then
				waves.launch()
			else
				if bosswait<0 then waves.time=0 end
				bosswait=90
				waves.next=9999
			end
		end
		
		if waves.time==bosswait then
			if not boss.active then boss._init() end
		end
	end
	
	waves.time+=1
end




waves.build=function()
	--waves
	add(waves.all, function()
		routes.use(routes.zigzag(), pwg.oneshot, {}, 130,20, {replay=4,spawn=8,item=4})
		routes.use(routes.zigzag(true), pwg.oneshot, {}, 130,80, {replay=4,spawn=8,delay=60})
	end)
	
	add(waves.all, function()
		routes.use(routes.stutter(), pwg.oneshot, {
			{t=20,ang=.5},
		}, 130,10, {replay=3,spawn=8,incy=20})
	end)
	
	add(waves.all, function()
		routes.use(routes.stutter(), pwg.spread, {
			{t=20,ang=.5},
		}, 130,10, {replay=3,spawn=8,incy=20})
	end)
	
	
	add(waves.all, function()
		routes.use(routes.express(), pwg.oneshot, {}, 130,10, {replay=6,spawn=10,item=6})
		routes.use(routes.cliff(), pwg.oneshot, {
			{t=25,target=player.target},
		}, 130,30, {delay=30,replay=6,spawn=15})
	end)
	
	
	add(waves.all, function()
		routes.use(routes.treeline(), pwg.mgun, mgunshot, 50,130, {replay=2,spawn=5,incx=25})
		
		routes.use(routes.wanderdown(), pwg.oneshot, {
			{t=20,target=player.target},
		}, 130,10, {delay=50,replay=4,spawn=10})
		
		routes.use(routes.wanderdown(), pwg.oneshot, {
			{t=20,target=player.target},
		}, 130,35, {delay=30,replay=4,spawn=10})
	end)
	
	
	add(waves.all, function()
		routes.use(routes.stutter(), pwg.spread, {
			{t=20,ang=.5},
		}, 130,15, {replay=3,spawn=8,incy=20})
	end)
	
	
	add(waves.all, function()
		routes.use(routes.centerstop(), pwg.omni, {
			{t=35,ang=.5},
			{t=40,ang=.5},
			{t=60,ang=.5},
			{t=90,ang=.5},
			{t=120,ang=.5},
			{t=150,ang=.5},
		}, 130,45, {})
		waves.next=120
	end)
	
	add(waves.all, function()
		routes.use(routes.express(), pwg.oneshot, {}, 130,10, {replay=5,spawn=13})
		routes.use(routes.express(), pwg.oneshot, {}, 130,80, {replay=5,spawn=13,item=5})
	end)
	
	add(waves.all, function()
		routes.use(routes.upstoptop(), pwg.spread, {{t=50,ang=.5}}, 55,210)
		routes.use(routes.upstoptop(), pwg.spread, {{t=50,ang=.5}}, 70,190,{delay=8})
		routes.use(routes.upstoptop(), pwg.spread, {{t=50,ang=.5}}, 85,170,{delay=16})
		routes.use(routes.upstoptop(), pwg.spread, {{t=50,ang=.5}}, 100,150,{delay=24})
	end)
	
	add(waves.all, function()
		routes.use(routes.wanderdown(), pwg.oneshot, {
			{t=20,target=player.target},
		}, 130,10, {delay=50,replay=4,spawn=10})
		
		routes.use(routes.wanderdown(), pwg.oneshot, {
			{t=20,target=player.target},
		}, 130,50, {delay=30,replay=4,spawn=10})
	end)
	
	
	add(waves.all, function()
		routes.use(routes.glideup(), pwg.oneshot, {
			{t=80,target=player.target},
		}, 130,20, {replay=4,spawn=10})
		
		routes.use(routes.treeline(), pwg.mgun, mgunshot, 70,130, {delay=40})

	end)
	
	add(waves.all, function()
		routes.use(routes.stutter(), pwg.spread, {
			{t=20,ang=.5},
		}, 130,10, {replay=3,spawn=8,incy=20})
		
		routes.use(routes.wanderdown(), pwg.oneshot, {
			{t=20,target=player.target},
		}, 130,30, {delay=85,replay=4,spawn=10})
		
		routes.use(routes.wanderdown(.375), pwg.oneshot, {
			{t=20,target=player.target},
		}, 130,110, {delay=95,replay=4,spawn=10,item=3})
	end)
	
	add(waves.all, function()
		routes.use(routes.express(), pwg.oneshot, {}, 130,10, {replay=6,spawn=10})
		routes.use(routes.express(), pwg.oneshot, {}, 130,40, {delay=30,replay=6,spawn=10})
		routes.use(routes.express(), pwg.oneshot, {}, 130,70, {delay=60,replay=6,spawn=10,item=6})
		routes.use(routes.express(), pwg.oneshot, {}, 130,100, {delay=90,replay=6,spawn=10})
	end)
	
	
	add(waves.all, function()
		routes.use(routes.upstoptop(.75), pwg.spread, {{t=50,ang=.5}}, 100,-30,{delay=48})
		routes.use(routes.upstoptop(.75), pwg.spread, {{t=50,ang=.5}}, 85,-50,{delay=32})
		routes.use(routes.upstoptop(.75), pwg.spread, {{t=50,ang=.5}}, 70,-70,{delay=16})
		routes.use(routes.upstoptop(.75), pwg.spread, {{t=50,ang=.5}}, 55,-90)
	end)
	
	
	add(waves.all, function()
		routes.use(routes.wanderdown(), pwg.oneshot, {
			{t=20,target=player.target},
		}, 130,10, {replay=4,spawn=10})
		
		routes.use(routes.treeline(), pwg.mgun, mgunshot, 30,130, {delay=40,incx=24,spawn=15,replay=3})

	end)
	
	
	add(waves.all, function()
		routes.use(routes.stutter(), pwg.oneshot, {
			{t=20,ang=.5},
		}, 130,10, {replay=4,spawn=8,incy=20})
	end)
	
	
	
	
	add(waves.all, function()
		routes.use(routes.zigzag(), pwg.oneshot, {}, 130,20, {replay=4,spawn=8,item=4})
		routes.use(routes.zigzag(true), pwg.oneshot, {}, 130,80, {replay=4,spawn=8,delay=60})
	end)
	
	
	
	add(waves.all, function()
		routes.use(routes.stutter(), pwg.spread, {
			{t=20,ang=.5},
		}, 130,10, {replay=3,spawn=8,incy=20})
	end)	
	
	
	
	
	add(waves.all, function()
		routes.use(routes.stutter(), pwg.spread, {
			{t=20,ang=.5},{t=30,ang=.5},
		}, 130,55)
		routes.use(routes.stutter(), pwg.mgun, mgunshot, 130,10, {delay=25,replay=2,incy=30})
	end)
	
	

	return #waves.all
end






--
-- boss
--

boss={active=false}
boss._init=function()
	boss.active=true
	boss.hp=100
	boss.pos={x=130,y=45}
	boss.hitbox={x=0,y=0,w=32,h=32}
	boss.t=0
	boss.state=1
	boss.attack={}
	boss.st=0
	boss.ani=0
	boss.smoke=false
end

boss._update=function()
	if boss.smoke then
		smoke.add(boss.pos.x-14, boss.pos.y+14)
		smoke.add(boss.pos.x+14, boss.pos.y+14)
	end

	if boss.state==1 then
		boss.pos.x-=1
		
		if boss.pos.x<=100 then 
			boss.state=4 
			boss.t=0
		end
	end
	
	if boss.state==2 then -- up
		boss.pos.y-=1
		
		boss.quickshoot()
		
		if boss.pos.y<=10 then 
			boss.state=4
			boss.t=0
		end
	end
		
	if boss.state==3 then -- down
		boss.pos.y+=1
		
		boss.quickshoot()
		
		if boss.pos.y>=100 then
			boss.state=4 
			boss.t=0
		end
	end
		
	if boss.state==4 then
		if player.state==1 then
			-- short laser
			if boss.st==5 or boss.st==30 then
				pwg.shoot(boss.pos.x, boss.pos.y+16, .5, {shots=15, speed=2, spread=.0625})
				pwg.shoot(boss.pos.x, boss.pos.y+16, .5, {shots=30, speed=1, spread=.0312})
			end
			
			if boss.st==10 then
				--pwg.shoot(boss.pos.x, boss.pos.y+16, .5, {shots=30, speed=1, spread=.0312})
			end
			
			-- long laser
			if boss.st>20 and boss.st<30 then
				--pwg.shoot(boss.pos.x, boss.pos.y+16, .5, {shots=10, speed=2, spread=.03})
			end
		end
		
		if boss.t>=75 then 
			boss.t=0
			boss.st=0
			if boss.pos.y>60 then
				boss.state=2
			else
				boss.state=3
			end
		end
		
		boss.st+=1
	end

	if boss.state==5 then
		boss.pos.x+=.5
		boss.pos.y+=1
		
		if boss.pos.x>148 or boss.pos.y>148 then
			player.state=4
			
		end
	
	end
	
	
	boss.t+=1
	boss.ani+=1
	
	if boss.ani>=30 then boss.ani=0 end
	
	boss.flash=false
	foreach(player.bullets, function(bullet) 
		if collide(boss, bullet) then 
			
			boss.hp-=.5*player.power
			del(player.bullets, bullet)
			
			if boss.hp<=0 then
				boss.kill()
			else
				-- make em flash
				boss.flash=true
			end
			
			if boss.hp<=30 then boss.smoke=true end
			
			
		end
	end)
end

boss._draw=function()
	--circfill(boss.pos.x,boss.pos.y,10,12)
	if not boss.flash then
		spr(12,boss.pos.x,boss.pos.y,2,2)
		spr(12,boss.pos.x-14,boss.pos.y,2,2,1)
		
		if boss.ani<15 then
			spr(42,boss.pos.x-14,boss.pos.y+16,4,2)
		else
			spr(38,boss.pos.x-14,boss.pos.y+16,4,2)
		end
		
		if boss.ani>20 and boss.ani<30 and boss.state<5 then
			spr(30,boss.pos.x+4,boss.pos.y+10,1,1)
			spr(30,boss.pos.x-10,boss.pos.y+10,1,1,1)
		end
	end
	
	if boss.state==5 then
		if boss.ani==10 then
			make_blood_ps(boss.pos.x+rnd(28),boss.pos.y+rnd(28))
		end
		
		if boss.ani==20 or boss.ani==10 then
			sfx(1)
			make_explosion_ps(boss.pos.x+rnd(28),boss.pos.y+rnd(28))
		end
	end
end

boss.quickshoot=function()
	if boss.t==10 or boss.t==20 or boss.t==30 or boss.t==40 or boss.t==50 then
		if player.state==1 then
			px, py = player.center()
			local direct = atan2(px-boss.pos.x,py-boss.pos.y)
			pwg.shoot(boss.pos.x, boss.pos.y, direct, {shots=1, speed=2, spread=.0625})
		end
	end

end

boss.kill=function()
	if boss.state<5 then
		sfx(1)
		boss.state=5
		boss.t=0
		boss.flash=false
		player.canshoot=false
		pwg.bullets.all={}

		player.score+=shr(30000,16)
	end
end



--
-- bullet generator
---
pwg={bullets={all={}}}
pwg.hitbox={x=0,y=0,w=16,h=13}

pwg.oneshot={spr=5,style=8,hp=1,shots=1,points=1000,speed=2, spread=0, accuracy=0, size=3, hitbox=pwg.hitbox}
pwg.mgun={spr=5,style=7,hp=6,shots=1, points=2500,speed=3, spread=0, accuracy=0, size=3, hitbox=pwg.hitbox}
pwg.spread={spr=5,style=6,hp=4,shots=3, points=1500,speed=1, spread=.0625, accuracy=0, size=3, hitbox=pwg.hitbox}
pwg.omni={spr=5,style=12,hp=10,shots=15, points=10000,speed=2, spread=.0625, accuracy=0, size=3, hitbox=pwg.hitbox}

pwg.shoot=function(x, y, angle, cfg)

	if cfg.shots%2!=0 then cfg.shots-=1 end
    
    local perside=cfg.shots/2
    local list={}
    
    for n=1,perside do add(list, angle-cfg.spread*n) end
    add(list,angle)
    for n=1,perside do add(list, angle+cfg.spread*n) end
	
	
    
    foreach(list, function(ang)
        add(pwg.bullets.all, pwg.bullets.create(x,y, ang, cfg.speed, cfg.size))
    end)
end

pwg.bullets.create=function(x,y,angle,speed,size)
    local obj={}

    obj.pos={x=x,y=y}
	obj.hitbox={x=1,y=1,w=6,h=7}
    obj.speed=speed
    obj.angle=angle
	obj.size=size
    
    obj.tx=cos(obj.angle)*obj.speed
	obj.ty=sin(obj.angle)*obj.speed

    return obj
end

pwg.bullets._update=function()
    foreach(pwg.bullets.all, function(obj) 
        obj.pos.x+=obj.tx
        obj.pos.y+=obj.ty
    
		if offscreen(obj.pos.x, obj.pos.y) then del(pwg.bullets.all, obj) end
    end)
end

pwg.bullets._draw=function()
	foreach(pwg.bullets.all, function(obj) 
		spr(16, obj.pos.x, obj.pos.y, 1,1)

    end)
end


--
-- player
--
player={
	hitbox={x=5,y=17,w=1,h=1},
	collectbox={x=0,y=0,w=16,h=24},
	score=shr(0,16)
}
player.target=function() return({x=player.pos.x+player.hitbox.x,y=player.pos.y+player.hitbox.y}) end

player.init=function()
	player.pos={x=16,y=45,dx=0,dy=0}
	player.ani={f=0}
	player.smoke=false
	player.canfire=true
	player.state=1
	--player.healtimer=45
	--player.hurt=false
	player.bullets={}
    
	
    --player.angle=.30
    player.btimer=0
    player.brate=4 -- bullet fire rate
    player.bspeed=5 -- bullet speed
	player.accel=1.5
	player.interia=.3
	player.power=1 -- bullet power
	
end

player._update=function()
	if player.smoke then
		smoke.add(player.pos.x, player.pos.y+12)
	end

	if player.state==1 then
		--movement
		player.pos.dx *= player.interia
		player.pos.dy *= player.interia
	
		if btn(0) then player.pos.dx -= player.accel end
		if btn(1) then player.pos.dx += player.accel end 
		if btn(2) then player.pos.dy -= player.accel end 
		if btn(3) then player.pos.dy += player.accel end
		
		player.pos.x+=player.pos.dx
		player.pos.y+=player.pos.dy
		
		if player.pos.x<=screen.x then player.pos.x=0 end
		if player.pos.x>=screen.w-16 then player.pos.x=screen.w-16 end
		if player.pos.y<=screen.y-16 then player.pos.y=-16 end
		if player.pos.y>=screen.h-20 then player.pos.y=screen.h-20 end
		
		
		--shooting
		if player.brate==player.btimer then
			if btn(4) or btn(5) and player.canfire then
				sfx(3)
				player.shootbullet(player.pos.x+12, player.pos.y+14, 0, player.bspeed, 1)
			end
			
			player.btimer=0
		end
	    player.btimer+=1
	
	
		-- enemy shot collision
		foreach(pwg.bullets.all, function(shot)  
			if collide(player, shot) then 
				del(pwg.bullets.all, shot)
				player.die()
			end
		end)
		
		-- enemy character collision
		foreach(mobs.alive, function(mob)  
			if collide(player, mob) then 
				mobs.kill(mob)
				player.die()
			end
		end)
	
	
		-- beer collision
		foreach(bonus.all,function(beer)
			if collide(player, beer, player.collectbox) then
				sfx(2)
				player.power+=1
				if player.power>3 then player.power=3 end
				del(bonus.all, beer)
			end
		end)
	else
		-- player got hit so bring them in from the left
		if player.state==2 then
			player.smoke=true
			player.pos.x+=.25
			player.pos.y+=1.25
			
			if offscreen(player.pos.x,player.pos.y) then 
				player.pos.x=-18
				player.pos.y=45
				player.state=3
				sfx(-1,1)
			end
		end
		
		-- playing coming back in from death
		if player.state==3 then
			player.smoke=false
			player.pos.x+=1
			
			if player.pos.x>=18 then 
				player.state=1 
				player.init()
			end
		end
		
		-- player won, speed off right
		if player.state==4 then
			player.pos.x+=2
			
			if player.pos.x>=130 then 
				gameover._init()
			end
		end
		
		-- time out, player goes out slowly
		if player.state==5 then
			player.pos.x-=.5
			player.pos.y+=1
			
			if player.pos.x<=-16 then
				gameover._init()
			end
		end
				
		
	end
	
	--player bullets, keep moving no matter what state
	foreach(player.bullets, function(obj) 
		obj.pos.x+=obj.tx
		obj.pos.y+=obj.ty

		if offscreen(obj.pos.x, obj.pos.y) then del(player.bullets, obj) end
	end)
	

end

player._draw=function()
	--character
	
	
	
	if player.ani.f<2 then
		spr(1,player.pos.x, player.pos.y,2,4)
	else
		spr(3,player.pos.x, player.pos.y,2,4)
	end
	player.ani.f+=1
	if player.ani.f>=4 then player.ani.f=0 end
	--anim(player, 1, 2, 10, 2,4)

	--bullets
	foreach(player.bullets, function(obj)
        --circfill(obj.pos.x, obj.pos.y, 2, 7)
		local bspr=48
		local bsize=1
		if player.power>1 then bspr=32 bsize=2 end
		--spr(bspr, obj.pos.x, obj.pos.y, 1,1)
		circfill(obj.pos.x, obj.pos.y, bsize, 7)
    end)
	
	
end

player.center=function()
	return player.pos.x+player.hitbox.x+player.hitbox.w, player.pos.y+player.hitbox.y+player.hitbox.h
end

player.bullet=function(x,y,angle,speed,size)
	local obj={}

    obj.pos={x=x,y=y}
    obj.hitbox={x=0,y=0,w=2,h=2}
    obj.speed=speed
    obj.angle=angle
	obj.size=size
	obj.tx=cos(obj.angle)*obj.speed
	obj.ty=sin(obj.angle)*obj.speed
	
	return obj
end

player.shootbullet=function(x,y,angle,speed,size)
    add(player.bullets, player.bullet(x,y,angle,speed,size))
	
	if player.power>=3 then
		add(player.bullets, player.bullet(x,y,.125,speed,size))
		add(player.bullets, player.bullet(x,y,.875,speed,size))
	end
end

player.die=function()
	sfx(1)
	sfx(0,1)
	make_explosion_ps(player.center())
	player.state=2
	player.canshoot=false
	pwg.bullets.all={}
	
	--player.pos.x=-16
	--player.pos.y=64
end

player.timeup=function()
	player.state=5
	player.canshoot=false
	pwg.bullets.all={}
	
	--player.pos.x=-16
	--player.pos.y=64
end






play={}
play._init=function()
	boss.active=false
	smoke.all={}

	player.init()
	player.score=shr(0,16)
	
	hud._init()
	waves._init()
	t=0
	
	cart.update=play._update
	cart.draw=play._draw
end

play._update=function()
	moon._update()
	smoke._update()
	player._update()
	explode._update()
	waves._update()
	mobs._update()
	pwg.bullets._update()
	
	if boss.active then boss._update() end
	
	bonus._update()
	hud._update()
	
	clock+=1
end

play._draw=function()
	smoke._draw()
	player._draw()
	mobs._draw()
	pwg.bullets._draw()
	explode._draw()
	bonus._draw()
	hud._draw()

	if boss.active then boss._draw() end
end


	
	
--
-- clock
--
--[[ hud map ]]
hud={status={}}


hud._init=function()
	hud.clock={m=1,s=59,t=0,str="1:59"}
end

hud._update=function()
	if hud.clock.s>=60 then
		hud.clock.m+=1
		hud.clock.s=hud.clock.s-60
	end
	
	if hud.clock.s<0 then
		hud.clock.m-=1
		hud.clock.s=59
	end
	
	if hud.clock.t==30 then
		hud.clock.s-=1
		hud.clock.t=0
	end
	
	if hud.clock.s<10 then
		hud.clock.str=hud.clock.m..":0"..hud.clock.s
	else
		hud.clock.str=hud.clock.m..":"..hud.clock.s
	end
	
	if hud.clock.m<=0 and hud.clock.s<=40 then
		player.smoke=true
	end
	
	
	
	if hud.clock.m<=0 and hud.clock.s<=0 then
		hud.clock.m=0
		hud.clock.s=0
		
		if player.state<5 then player.timeup() end
	end

	if player.state<4 then hud.clock.t+=1 end --only run clock when not game winning
end

hud._draw=function()
	print(hud.clock.str, 0,0,10)
	print(getscoretext(player.score),80,0,7)
end	



--
-- game over
--
gameover={score=0}
gameover._init=function()
	t=0
	timepoints = hud.clock.m*60 + hud.clock.s * 100
	
	local gamescore = player.score
	gameover.score=gamescore
	
	player.score+=shr(timepoints,16)
	
	if player.score>title.hiscore then
		dset(0,player.score)
	end
	
	cart.update=gameover._update
	cart.draw=gameover._draw
end

gameover._update=function()
	if t>=60 then 
		if btnp(4) or btnp(5) then title._init() end
	end
end

gameover._draw=function()
	rect(0,0,127,127,7)
	map(2,3, 25,10, 10,3) --logo

	center_text("game over",40,8)

	center_text("game score "..getscoretext(gameover.score),55,6)
	center_text("time bonus "..timepoints,65,6)
	
	
	
	if player.score>title.hiscore then 
		center_text("\146 total score "..getscoretext(player.score).." \146",78,10)
	else
		center_text("total score "..getscoretext(player.score),78,7)
	end
	
	if t>=60 then
		center_text("\151 to play again",90,11)
	end
end


--
-- title
--
title={hiscore=0}
title._init=function()
	title.hiscore=dget(0)
	
	cart.update=title._update
	cart.draw=title._draw
end
title._update=function()
	if btnp(4) or btnp(5) then play._init() end
end

title._draw=function()
	rect(0,0,127,127,7)
	map(2,3, 25,10, 10,3) --logo
	center_text("tournament edition",37,10)
	
	center_text("you have 2 minutes",52,7)
	center_text("worth of fuel",59,7)
	
	center_text("\151 to start",72,11)
	
	center_text("high score "..getscoretext(title.hiscore),88,6)
	
	--print("tournament edition",20,42,10)
	--print("you have 2 minutes\n   worth of fuel",25,50,7)
	--print("\151 to start",40,70,11)
	
	
	--print(,30,85,6)
end




--
-- loops
--

function _init()
	cartdata("bunyanshmup")
	--dset(0,0)

	enemy={}
	background._init()
	title._init()
end

function _update()
	background._update()
	cart.update()
	
	
	--if btnp(4) and btnp(5) then gameover._init() end
	
	t+=1
	
end

function _draw()
	cls()

	background._draw()
	cart.draw()
	--debug=smoke.t
	print(debug,0,70,12)
end




--
-- utility
--
function center_text(s,y,c) print(s,64-(#s*2),y,c) end

smoke={all={},t=0}
smoke.make=function(x,y,init_size)
	local s={}
	s.x=x
	s.y=y
	s.width=init_size
	s.width_final=init_size+rnd(3)+1
	s.t=0
	s.max_t=30+rnd(10)
	s.dx=(rnd(.8)*.4)
	s.dy=-rnd(.05)
	s.ddy=-.02
	add(smoke.all,s)
	return s
end

smoke.move=function(sp)
	local rc=flr(rnd(3))
	sp.col=8+rc
	if(sp.t>sp.max_t) then
		del(smoke,sp)
	end
	if(sp.t>sp.max_t-5) then
		sp.width+=1
		sp.width=min(sp.width,sp.width_final)
		sp.col=5
	end
	sp.x-=sp.dx
	sp.y+=sp.dy
	sp.dy+=sp.ddy
	sp.t+=1
	
	if offscreen(sp.x,sp.y) then del(smoke.all,sp) end
end

smoke.add=function(x,y)
	smoke.make(x,y,rnd(2),6)
end

smoke._update=function()
	foreach(smoke.all,smoke.move)
	smoke.t+=1
end


smoke._draw=function()
	foreach(smoke.all,function(s)
		circfill(s.x,s.y,s.width,s.col)
	end)
end




function offscreen(x,y)
	--screen={x=2,y=3,w=128,h=118,mid=60}
	if (x<screen.x-16 or x>screen.w or y<screen.y-16 or y>screen.h) then 
		return true
	else
		return false
	end
end

function collide(obj, other, custom)
	local bhitbox=obj.hitbox
	if custom then bhitbox=custom end
	
	

    if
        other.pos.x+other.hitbox.x+other.hitbox.w > obj.pos.x+bhitbox.x and 
        other.pos.y+other.hitbox.y+other.hitbox.h > obj.pos.y+bhitbox.y and
        other.pos.x+other.hitbox.x < obj.pos.x+bhitbox.x+bhitbox.w and
        other.pos.y+other.hitbox.y < obj.pos.y+bhitbox.y+bhitbox.h 
    then
        return true
    end
end

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


		
function getscoretext(val)
   local s = ""
   local v = abs(val)
   while (v!=0) do
     s = shl(v % 0x0.000a, 16)..s
     v /= 10
   end
   if (val<0)  s = "-"..s
   if (val==0)  s = "0"
   return s 
end 




--
-- explosions
--
-- particle system library -----------------------------------
particle_systems = {}

function make_psystem(minlife, maxlife, minstartsize, maxstartsize, minendsize, maxendsize)
	local ps = {}
	-- global particle system params
	ps.autoremove = true

	ps.minlife = minlife
	ps.maxlife = maxlife
	
	ps.minstartsize = minstartsize
	ps.maxstartsize = maxstartsize
	ps.minendsize = minendsize
	ps.maxendsize = maxendsize
	
	-- container for the particles
	ps.particles = {}

	-- emittimers dictate when a particle should start
	-- they called every frame, and call emit_particle when they see fit
	-- they should return false if no longer need to be updated
	ps.emittimers = {}

	-- emitters must initialize p.x, p.y, p.vx, p.vy
	ps.emitters = {}

	-- every ps needs a drawfunc
	ps.drawfuncs = {}

	-- affectors affect the movement of the particles
	ps.affectors = {}

	add(particle_systems, ps)

	return ps
end

function update_psystems()
	local timenow = time()
	for ps in all(particle_systems) do
		update_ps(ps, timenow)
	end
end

function update_ps(ps, timenow)
	for et in all(ps.emittimers) do
		local keep = et.timerfunc(ps, et.params)
		if (keep==false) then
			del(ps.emittimers, et)
		end
	end

	for p in all(ps.particles) do
		p.phase = (timenow-p.starttime)/(p.deathtime-p.starttime)

		for a in all(ps.affectors) do
			a.affectfunc(p, a.params)
		end

		p.x += p.vx
		p.y += p.vy
		
		local dead = false
		if (p.x<0 or p.x>127 or p.y<0 or p.y>127) then
			dead = true
		end

		if (timenow>=p.deathtime) then
			dead = true
		end

		if (dead==true) then
			del(ps.particles, p)
		end
	end
	
	if (ps.autoremove==true and count(ps.particles)<=0) then
		del(particle_systems, ps)
	end
end

function draw_ps(ps, params)
	for df in all(ps.drawfuncs) do
		df.drawfunc(ps, df.params)
	end
end

function emittimer_burst(ps, params)
	for i=1,params.num do
		emit_particle(ps)
	end
	return false
end

function emittimer_constant(ps, params)
	if (params.nextemittime<=time()) then
		emit_particle(ps)
		params.nextemittime += params.speed
	end
	return true
end

function emit_particle(psystem)
	local p = {}

	local e = psystem.emitters[flr(rnd(#(psystem.emitters)))+1]
	e.emitfunc(p, e.params)	

	p.phase = 0
	p.starttime = time()
	p.deathtime = time()+rnd(psystem.maxlife-psystem.minlife)+psystem.minlife

	p.startsize = rnd(psystem.maxstartsize-psystem.minstartsize)+psystem.minstartsize
	p.endsize = rnd(psystem.maxendsize-psystem.minendsize)+psystem.minendsize

	add(psystem.particles, p)
end

function emitter_point(p, params)
	p.x = params.x
	p.y = params.y

	p.vx = rnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = rnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

function emitter_box(p, params)
	p.x = rnd(params.maxx-params.minx)+params.minx
	p.y = rnd(params.maxy-params.miny)+params.miny

	p.vx = rnd(params.maxstartvx-params.minstartvx)+params.minstartvx
	p.vy = rnd(params.maxstartvy-params.minstartvy)+params.minstartvy
end

function affect_force(p, params)
	p.vx += params.fx
	p.vy += params.fy
end

function affect_forcezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx += params.fx
		p.vy += params.fy
	end
end

function affect_stopzone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = 0
		p.vy = 0
	end
end

function affect_bouncezone(p, params)
	if (p.x>=params.zoneminx and p.x<=params.zonemaxx and p.y>=params.zoneminy and p.y<=params.zonemaxy) then
		p.vx = -p.vx*params.damping
		p.vy = -p.vy*params.damping
	end
end

function affect_attract(p, params)
	if (abs(p.x-params.x)+abs(p.y-params.y)<params.mradius) then
		p.vx += (p.x-params.x)*params.strength
		p.vy += (p.y-params.y)*params.strength
	end
end

function affect_orbit(p, params)
	params.phase += params.speed
	p.x += sin(params.phase)*params.xstrength
	p.y += cos(params.phase)*params.ystrength
end

function draw_ps_fillcirc(ps, params)
	for p in all(ps.particles) do
		c = flr(p.phase*count(params.colors))+1
		r = (1-p.phase)*p.startsize+p.phase*p.endsize
		circfill(p.x,p.y,r,params.colors[c])
	end
end

function draw_ps_pixel(ps, params)
	for p in all(ps.particles) do
		c = flr(p.phase*count(params.colors))+1
		pset(p.x,p.y,params.colors[c])
	end	
end

function draw_ps_streak(ps, params)
	for p in all(ps.particles) do
		c = flr(p.phase*count(params.colors))+1
		line(p.x,p.y,p.x-p.vx,p.y-p.vy,params.colors[c])
	end	
end

function draw_ps_animspr(ps, params)
	params.currframe += params.speed
	if (params.currframe>count(params.frames)) then
		params.currframe = 1
	end
	for p in all(ps.particles) do
		pal(7,params.colors[flr(p.endsize)])
		spr(params.frames[flr(params.currframe+p.startsize)%count(params.frames)],p.x,p.y)
	end
	pal()
end

function draw_ps_agespr(ps, params)
	for p in all(ps.particles) do
		local f = flr(p.phase*count(params.frames))+1
		spr(params.frames[f],p.x,p.y)
	end	
end

function draw_ps_rndspr(ps, params)
	for p in all(ps.particles) do
		pal(7,params.colors[flr(p.endsize)])
		spr(params.frames[flr(p.startsize)],p.x,p.y)
	end	
	pal()
end

function make_blood_ps(ex,ey)
	local ps = make_psystem(2,3, 1,2,0.5,0.5)
	
	add(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 48}
		}
	)
	add(ps.emitters, 
		{
			emitfunc = emitter_point,
			params = { x = ex, y = ey, minstartvx = 1, maxstartvx = 3, minstartvy = -3, maxstartvy=-2 }
		}
	)
	add(ps.drawfuncs,
		{
			drawfunc = draw_ps_pixel,
			params = { colors = {8,2} }
		}
	)
	add(ps.affectors,
		{ 
			affectfunc = affect_force,
			params = { fx = 0, fy = 0.2 }
		}
	)
	add(ps.affectors,
		{ 
			affectfunc = affect_stopzone,
			params = { zoneminx = 0, zonemaxx = 127, zoneminy = 130, zonemaxy = 130 }
		}
	)
end


function make_explosion_ps(ex,ey)
	local ps = make_psystem(0.1,0.5, 9,14,1,3)
	
	add(ps.emittimers,
		{
			timerfunc = emittimer_burst,
			params = { num = 4 }
		}
	)
	add(ps.emitters, 
		{
			emitfunc = emitter_box,
			params = { minx = ex-4, maxx = ex+4, miny = ey-4, maxy= ey+4, minstartvx = 0, maxstartvx = 0, minstartvy = 0, maxstartvy=0 }
		}
	)
	add(ps.drawfuncs,
		{
			drawfunc = draw_ps_fillcirc,
			params = { colors = {7,0,10,9,9,4} }
		}
	)
end




__gfx__
00000000000000000000000000000000000000000000040408800000000004040800000000000000000000000000000000000000000044000000000007777000
00000000000000000000000000000000000000000000888880000000000088888088000000000000000000000000000000000000004440000000000077677700
00000000000bb00000000000000bb00000000000001424240844400000142424004440000000000000000000000000000cc04444444400000000000079779600
00000000000bb33000000000000bb33000000000004444440044440000444444004444000000000000000000000000000cc44444440000000000000069979966
0000000000003333000000000000333300000000000074444445440000007444444544000000000000000000000000000ccccccc000000000000000069494906
0000000000003333000000000000333300000000000044416654400000004441665440000000000000000000000000000ccc11ccc00000000000000069494966
0000000000003fff0000000000003fff00000000111111116644000011111111664400000000000000000000000000000cc11ccccc0000000000000069494600
00000000000041f100000000000041f100000000115115146600000011511514660000000000000000000000000000000118ccc0000000000000000006666000
0000000000004fff0000000000004fff00000000000044446660000000004444666000000000000000000000000000000c88cc00000000000770000000000000
0000200000004444000000000000444400000000000040040669000000004004066a00000000000000000000000000000ccccc00000000000007000000000000
00222200065644ff00000000065644ff000000000000040040990a0000000400409a90000000000000000000000000000cccc000000000007000077000000000
0222222066654444000066666665444400006666000004004000a0a000000400400009000000000000000000000000000c1cc100000000000700077700000000
008e8e0066658222000006666665822200000666000000500500000000000050050900000000000000000000000000000ccc1110000000000000007700000000
00e8e800668588880000066666858888000006660000000000000000000000000000900000000000000000000000000001111111000000000077000000000000
008e8e00664244444444444466424444444444440000000000000000000000000000000000000000000000000000000001111111100000000007700000000000
0008e0006842f4444f4444446842f4444f4444440000000000000000000000000000000000000000000000000000000001111111100000000007700000000000
00000000688828882000066668882888200006660000000066666666666665656555555555555500666666666666656565555555555555000000000000000000
0000000066011aa00000066666011790000006660000000066666666666666565656565655555500666666666666665656565656555555000000000000000000
00000000990c1aa0000066669a0c1970000066660000000066666666666666666666656565555500666666666666666666666565655555000000000000000000
00000000a90cccc000000000990cccc0000000000000000006666666666666666666665655555000066666666666666666666656555550000000000000000000
000000000a0c00c000000000a00c00c0000000000000000006666686666666c66666656855655000066666c6666666866666656c556550000000000000000000
000000009000c00c000000009000c00c00000000000000000066688866666ccc666656888555000000666ccc66666888666656ccc55500000000000000000000
000000000a00c00c000000000900c00c000000000000000000666686666666c66665655855550000006666c6666666866665655c555500000000000000000000
000000000000100100000000a0a01001000000000000000000066666666666666656555555500000000666666666666666565555555000000000000000000000
58985000000004004000000000000400400000000000000000006666666666666565655555000000000066666666666665656555550000000000000000000000
05000000000004004000000000000400400000000000000000000001111100000011111000000000000000011111000000111110000000000000000000000000
00000000000004404400000000000440440000000000000000000000aa9900000099aa900000000000000009aa990000009aaa90000000000000000000000000
0000000000000400400000000000040040000000000000000000000999a90000000a999900000000000000999a9900000099a990000000000000000000000000
000000000000000000000000000000000000000000000000000000099a9000000099a90000000000000000009a9000000009a990000000000000000000000000
000000000000000000000000000000000000000000000000000000009990a0000a09990000000000000000009990000000099000000000000000000000000000
0000000000000000000000000000000000000000000000000000000a09000000000090a000000000000000000900000000009000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
101010100000000000000000000000000000007677000000cccccccc00ccccc0cccccccccc0cccccccccc0ccccc0000ccc0000ccccc0cccccc0cc00cccccc000
010101010000000000000000000000000000d666667700000cccccccc00cccc00cccc0cccc00cccc0ccc000ccc00000cccc0000cccc00cccc00cc0cccccccc00
10101010000000000000000000000000000d6666666770000ccc00ccc00ccc000ccc00ccccc0ccc000ccc0ccc00000ccccc0000ccccc0ccc000c00ccc00ccc00
0101010100000000000000000000000000d666d6666677000ccc000ccc0ccc000ccc00ccccc0ccc000cccccc000000ccccc0000ccccc0ccc00c000ccc00ccc00
101010100000000000000000000000000ddd66dd666667700ccc00ccc00ccc000ccc00ccccccccc0000ccccc000000cc0cc0000ccccccccc000000cccc000000
010101010000000000000000000000000dddd76d766d666001c1c1c1c00c1c000c1c00c1c1c1c1c0000c1c1c00000c1c0c1c000c1c1c1c1c0000000cccc1c000
10101010000000000000000000000000dd66dd76d66666770c1c1c1c1001c10001c1001c101c1c100001c1c0000001c1c1c10001c101c1c100000000001c1c00
01010101000000000000000000000000d666ddd66666d66701110001110111000111001110011110000011100000011111110001110011110000001100011100
00000000000b00000000000000000000d6d66dd7dd66d76601110001110111100111001110011110000011100000111000111001110011110000001100011100
00000000000b00000000000000030000ddd666dddd66dd6701111111110011111188088888888110000888100000111000888001111001110088001111111100
000000000003b00000000000000300000d6d66dddd66dd6011111111100001111188888888888810000188880001111188888888811888888888800111111000
0000000000043000000000000003b0000ddd66d6dd666d6000000000000000000088888888088880000088888000000088888888808888888888800000000000
00000000000b3b00000000000003300000ddd6666d66660000000000000000000888888880008880000088888000000888880888880888888000000000000000
0000000000b30b0000000000003b3b00000d66dd6666600000000000000000000008888880008888000088888800000888880088880088888000000000000000
000000000b3530000000000000330b0000007d666666000000000000000000000000008980008989000089898980000898900008880000898000000000000000
000000000b0430000000000000353030000000776600000000000000000000000000009890009890000098980890000989800000000000989898900000000000
00000000000b0300000b00000b043000000000000000000000000000000000000000009999999990000099999999000099900000999900999999900000000000
000b000000b3b000000b0000030b0300000000000000000000000000000000000000009999999900000099999999900099900999999990999990000000000000
000b00000b343b000003b00030b300300000000000000000000000000000000000000009a9a9a000000a9a9000a9a900a9a90a9a9a9a9009a900000000000000
0003b0000b3330000004300000343b00000000000000000000000000000000000000000a9a9a90000000a9a0000a9a900a9a90a9a9a0000a9a0a9a0000000000
00043000b3053b00000b3b000b333000000000000000000000000000000000000000000aaa0aaa00000aaaa00000aaa000aaaa00aaa000aaaaaaaa0000000000
000b3b00000403b000b30b00b3053b00000000000000000000000000000000000000000aaa0aaa0000aaaaa00000aaaa000aaaaaaaa000aaaaaa000000000000
00b30b0000b300000b353000000403b00000000000000000000000000000000000000000aa00aaa0000aaaa000000aaa0000aaaaaaaa000aaaa0000000000000
0b3530000b3330000b043000000400000000000000000000000000000000000000000000aa000aaa00000aa0000000000000000000aa0000aa00000000000000
0b043000003b0300000b0300b033b000000000000000000000000000000000000000000000000aaa000000000000000000000000000000000000000000000000
000b03000333b33b00b3b000333430000000000000000000000000000000000000000000000000aaa00000000000000000000000000000000000000000000000
00b3b000b33533000b343b030b333b0000000000000000000000000000000000000000000000000aaa0000000000000000000000000000000000000000000000
0b343b00033403b00b333000030403b000000000000000000000000000000000000000000000000aaaa000000000000000000000000000000000000000000000
0b3330003004000bb3053b03b033b303000000000000000000000000000000000000000000000000aaa000000000000000000000000000000000000000000000
b3053b0b00033000000403b303333b330000000000000000000000000000000000000000000000000aa000000000000000000000000000000000000000000000
000403b0b3353b000004000000350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040003330400330004000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0060005300000051530000005100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626353006061636200006153606200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727363607071737262537161737200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4445464748494a4b4c4d4e4f4141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455565758595a5b5c5d5e5f4141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000666768696a6b6c6d6e6f4141000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000767778797a7b7c7d7e7f8081000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0607070506050607050607070506070500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011001050c6740c6740c6740c6740c6740c6740170001700017000170001700016000160001600016000160001600016000160001600017000160001700017000170002600017000170001700027000270000000
011200001367013630000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000200001d3701f37021370243702a3702e370353703d3003d30031300283002a3002b3002510027100000002a1002c1003010000000000000000000000000000000000000000000000000000000000000000000
01050000187740e6040e6040e6040c5000c5000c5000b70034500355003550000000000002b00000000000002c0002d000000002d000000000000000000000000000000000000000000000000000000000000000
010400000e4670e2600e4600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

