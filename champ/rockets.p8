pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

debug=false
screen={x=0,y=0,w=128,h=128}

cart_update=function() end
cart_draw=function() end

game_time,collected,quota,shake,mx,my,mb,lives,stage,gst=0,0,25,false,0,0,0,3,0,0
grav=0.5
cam={x=0,y=0}
mapoff=24
medal_mult=1

bgtheme=3 --1=forest,2=mounts,3=tanks,4=subs
bgstars={}
for n=0,32 do add(bgstars,{x=rnd(127),y=rnd(64)}) end






-- #player
p1={
	pos={x=60,y=0},
	hitbox={x=0,y=0,w=5,h=8},
	dx=0,
	dy=0,
	isgrounded=false,
	jumpvel=5,
	camx=0,
	idle=true,
	flip=false,
	speed=2,
	dir=1,
	dt=0,
	layer=1,
	ammo=5,
	dive=false
}

function p_update()
	p1.dx=0
	p1.idle=true

	-- player can jump if on the ground
	if btnup or btndp then
		if btnup and p1.isgrounded then
			if p1.layer>1 then
				p1.dy=-p1.jumpvel
			else
				p1.dive=true
			end
		end

		if btndp and p1.isgrounded and p1.layer<4 then
			p1.drop=true
			p1.dt=0
		end
	else
		if btnl or btnr then
			if btnl then --left
				p1.flip=true
				p1.dir=-1
			end

			if btnr then --right
				p1.flip=false
				p1.dir=1
			end

			p1.idle=false
			p1.dx=p1.speed*p1.dir
			p1.pos.x+=p1.dx
		end
	end

	--shoot
	if btnzp and p1.ammo>0 then
		p1.ammo-=1
		gunner.new_bullet()
	end

	--reload
	if btnxp then
		p1.ammo=5
	end

	--stop at edge
	if p1.pos.x<=1 then p1.pos.x=1 end
	if p1.pos.x>=120 then p1.pos.x=120 end

	--accumulate gravity
	p1.dy+=grav
	p1.pos.y+=p1.dy

	--assume they are floating until we determine otherwise
	p1.isgrounded=false

	--only check for floors when moving downward
	if not p1.drop and not p1.dive then
		if p1.dy>=0 then
			if fallcheck(p1, 1,8, 5,8) then
				p1.pos.y = flr((p1.pos.y)/8)*8
				p1.dy=0
				p1.isgrounded=true
				row_time+=1
				p1.layer=gunner.get_layer(p1.pos.y)
			end
		end
	end

	if not p1.isgrounded then row_time=0 end

	if p1.drop then p1.dt+=1 end
	if p1.dt>8 then p1.drop=false end
	if p1.pos.y>90 then p1.dive=false end

	if p1.pos.y>127 then gunner.pdie() end	--die if you fall off bottom
	
end


function p_draw()
	palt(13,true)
	palt(0,false)
		
	--if lives>0 then
		local guny=0
		if not p1.idle then 
			anim(p1, 1, 8, 10, p1.flip) -- running
		else
			guny=1
			if p1.isgrounded then
				spr(1,p1.pos.x,p1.pos.y,1,1,p1.flip) --standing
			else
				spr(6,p1.pos.x,p1.pos.y,1,1,p1.flip) --jumping
			end
		end
		if p1.flip then p1.dir=-1 else p1.dir=1 end
		spr(9,p1.pos.x+(3*p1.dir),p1.pos.y+guny,1,1,p1.flip) --gun
	--end	
	palt()
end


--cart_draw=gunner_title_draw

gunner={
	actors={},
	bullets={},
	bombs={},
	layery={24,48,72,96}, --layer y values for actors
	t=0,
	shoot=15,
	lastbomb=0,
	lastbombd=1,
	_update=function()
		foreach(gunner.actors, function(b) b.update(b) end)
		
		-- timer to launch another missile, minimum .5s, max 1.5s
		if game_st==1 then
			if gunner.t>bomb_time then
				gunner.t=0
				
				if #gunner.bombs<bomb_max then gunner.new_bomb() end
			end
			
			--start dropping blocks if player spends too long on a single level
			if row_time>300 then
				gunner.remove_ground(p1.layer,1)
				row_time=260
			end
		end
		
		--if lives<=0 then gameover_init() end
		
		gunner.t+=1
	end,
	_draw=function()
		
		--camera shake
		cam.x=0 cam.y=0
		if shake then
			local shaker=1
			if rnd()<.5 then shaker=-1 end
			cam.x+=shaker
			cam.y+=shaker
			
			shake+=1
			if shake>4 then shake=false end
		end
		
		--#theme
		-- warehouse background wall only
		if bgtheme==3 then
			palt(0,false)
			palt(13,true)
			for n=0,15 do
				for m=0,15 do map(0,20, 32*n,32*m+8, 4,4) end
			end
			spr(168,10,112,8,2)
			spr(168,80,112,8,2)
		end
		
		--forest
		if bgtheme==1 then
			rectfill(0,0, 127,127, 15) --far
			rectfill(0,88, 127,127, 14) --mid
			--rectfill(0,0, 127,38, 10) --yellow
			
			palt(13,true)
			--palt(0,false)
			
			skyfade(11,7,1)
			skyfade(80,10)
			pal(2,14)
			map(0,16, 0,56, 24,4) --far trees
			pal()
			palt(13,true)
			
			
			--pal(14,2)
			rectfill(0,100, 127,127,2) --close
			map(0,16, -25,70, 24,4) --mid trees
			map(24,16, 0,90, 40,2) --close trees
			
			
			rectfill(0,105, 127,127,1) --close
			skyfade(128,0)
			pal()

			palt(0,false)
			palt(1,true)
		end
		
		
		--mourntains
		if bgtheme==2 then
			rectfill(0,0,127,100,1) --sky blue
			rectfill(0,80,127,127,0) --lower black
			palt(13,true)
			palt(0,false)
			skyfade(75,2)
			map(16,35, 0,68, 16,5) -- mountains
			
			for s in all(bgstars) do pset(s.x,s.y,7) end
			
			palt(1,true)
		end
		
		
		--subs
		if bgtheme==4 then
			rectfill(0,0,127,77,12) --sky blue
			palt(0,false)
			palt(13,true)
			skyfade(75,6)
			rectfill(0,77,127,127,1) --water
			skyfade(127,12)
			map(64,0, 0,0, 16,16) -- subs
			map(0,2, sub_x,sub_y, 10,2)
			palt(1,true)
		end
		
		
		map(0,24, 0,0, 16,16) --steel level layers
		pal()

		
		for b in all(gunner.actors) do b.draw(b) end
	end,
	pdie=function() --reset player at top
		gunner.bombs={}
		lives=max(0,lives-1)
		
		--if lives>0 then
			if collected>0 then
				local lose=flr(max(0,collected/2))
				collected=max(0,collected-lose)

				local px=p1.pos.x
				local py=p1.pos.y
				for n=0,lose do
					item_medal(px,py, rand(.125,.375), rand(1,5), .25)
				end
			end

			p1.pos.x=60
			p1.pos.y=10
			p1.speed=2
			medal_mult=1
			

			game_clear()
		--end
	end,
	remove_ground=function(layer,dir,slot)
		-- l1=28, l2=31, l3=34, l4=37
		-- slots 0-15
		local uselayer=gunner.rows[layer]
		local slot=slot or 0
		
		if dir>0 then
			gunner.rows[layer].last-=1
			slot=uselayer.last
		elseif dir<0 then
			gunner.rows[layer].front+=1
			slot=uselayer.front
		end
		
		local mapy=uselayer.y
		
		mset(slot,mapy,0) --change tile sprite to transparent
		
		if gunner.rows[layer].last > gunner.rows[layer].front then --make sure row has bricks
			shake=1
			explode_spark(slot*8+4, (mapy-25)*8)
			gunner.new_falling(slot*8, (mapy-25)*8)
		end
	end,
	get_layer=function(objy)
		local lid=1
		local layer=1
		foreach(gunner.layery, function(l)
			if l==objy then layer=lid end
			lid+=1
		end)
		
		return layer,gunner.layery[lid]
	end,
	new_falling=function(x,y)
		local obj={
			pos={x=x,y=y},
			st=1,
			t=0,
		}
		
		obj.update=function(self)
			if self.st==1 then
				self.pos.y-=1
				if self.t>3 then self.st=2 self.t=0 end
			end
			
			if self.st==2 then
				self.pos.y+=4
			end
			
			if self.pos.y>127 then del(gunner.actors,self) end
				
			self.t+=1
		end
		
		obj.draw=function(self)
			spr(51,self.pos.x,self.pos.y)
		end
		
		
		add(gunner.actors,obj)
	end,
	new_bomb=function()
		local obj={
			pos={x=0,y=0},
			hitbox={x=0,y=1,w=8,h=6},
			st=1,
			flip=false,
			t=0,
		}
		
		local getdir=rnd()
		if getdir>.5 then 
			obj.dir=1
			obj.pos.x=1
			obj.flip=true
		else
			obj.dir=-1
			obj.pos.x=118
		end
		
		
		
		obj.layer=lastbomb
		
		while obj.layer==lastbomb do
			obj.layer=flr(rnd(4))+1
		end
		
		lastbomb=obj.layer
		lastbombd=obj.dir
		
		
		
		
		obj.pos.y=gunner.layery[obj.layer]
		
		
		obj.update=function(self)
			if self.st==1 then
				if self.t>=15 then 
					self.st=2 
					self.t=0 
				else
					self.pos.x+=1*self.dir*-1
				end
			end
			
			if self.st==2 then
				
				self.pos.x+=bomb_speed*self.dir
			end
			
			
			--wall hit
			if ((self.pos.x<=-8 and self.dir<0) or (self.pos.x>=127 and self.dir>0)) and self.st==2 then 
				if self.layer==p1.layer then item_lose(p1.pos.x,p1.pos.y,p1.dir) end
				
				explode_wall(self.pos.x,self.pos.y, self.dir)
				gunner.remove_ground(self.layer,self.dir)
				
				--bomb_time=max(20,bomb_time-.5)
				--bomb_speed=min(bomb_speed+.2, 3)


				del(gunner.actors,self)
				del(gunner.bombs,self) 
				
			end
			
			--player hit
			if collide(self,p1) then
				del(gunner.actors,self)
				del(gunner.bombs,self) 
				
				explode_blood(p1.pos.x,p1.pos.y)
				item_skull(p1.pos.x,p1.pos.y)
				gunner.pdie()
				
				
			end
			
			--bullet hit
			foreach(gunner.bullets,function(b)
				if collide(self,b) then
					del(gunner.actors,self)
					del(gunner.bombs,self) 
					del(gunner.bullets,b)
					del(gunner.actors,b) 
					--sfx(0)
						

					explode_bomb(self.pos.x,self.pos.y)
					item_drop(self.pos.x,self.pos.y)
					
				end
			end)
			
			self.t+=1
		end
		
		obj.draw=function(self)
			spr(20,self.pos.x,self.pos.y,1,1,self.flip)
		end
		
		add(gunner.actors, obj)
		add(gunner.bombs, obj)
	end,
	new_bullet=function()
		local obj={
			pos={x=p1.pos.x+(4*p1.dir),y=p1.pos.y+3},
			hitbox={x=0,y=0,w=5,h=3},
			t=0,
			speed=5,
			dir=p1.dir,
			bullet=true
		}
		
		obj.update=function(self)
			self.pos.x+=self.speed*self.dir
			
			if self.pos.x<=-10 or self.pos.x>=136 then 
				del(gunner.bullets,self) 
				del(gunner.actors,self) 
			end
			
			self.t+=1
		end
		
		obj.draw=function(self)
			spr(21,self.pos.x,self.pos.y,1,1)
		end
		
		add(gunner.actors, obj)
		add(gunner.bullets, obj)
	end,
}


-- #items




items={}

function item_drop(x,y) 
	--if rnd()<.75 then
	if medal_mult>1 then
		item_medal(x,y,.375,2)
		item_medal(x,y,.151,2)
	else
		item_medal(x,y)
	end
	--end
end

function item_lose(x,y,dir)
	if collected>0 then
		local ang=.375
		if dir<0 then ang=.151 end
		item_medal(x,y,ang,3,.6)
		
		collected=max(0,collected-1)
	end
end

function item_medal(x,y,ang,speed,grav)
	local ang=ang or 0.25
	local speed=speed or 3
	local grav=grav or .8
	
	local obj={
		lasty=y,
		pos={x=x,y=y},
		hitbox={x=0,y=0,w=8,h=8},
		ang=ang,
		g=grav,
		blx=1,bly=8,brx=7,bry=8,
		isgrounded=false,
		t=0
	}
	
	obj.dx,obj.dy=dir_calc(obj.ang,speed)
	
	obj.update=function(self)
		
		--only move when it's not on a layer
		if not self.isgrounded then
			self.dy+=self.g --gravity
			self.pos.y+=self.dy
			self.pos.x+=self.dx
			
			if self.pos.y>self.lasty then
				if fallcheck(self, 1,8, 7,8) then
					self.pos.y=flr((self.pos.y)/8)*8
					self.dy=0
					self.dx=0
					self.isgrounded=true
				end
			else
				self.lasty=self.pos.y
			end
		else
			self.t+=1
		end
		
		--constant checks
		if collide(self,p1) and self.isgrounded then
			collected+=1
			del(gunner.actors,self)
			del(items,self) 
			--sfx(0)
		end

		if self.t>120 or self.pos.y>127 then
			del(gunner.actors,self)
			del(items,self) 
		end
	end
	
	obj.draw=function(self)
		spr(19,self.pos.x,self.pos.y)
	end
	
	
	add(items,obj)
end


function item_skull(x,y)
	local obj={
		lasty=y,
		pos={x=x,y=y},
		isgrounded=false,
		t=0,
		blx=0,bly=5,brx=0,bry=5
	}
	
	obj.dx,obj.dy=dir_calc(.25,4)
	
	obj.update=function(self)
		--only move when it's not on a layer
		if not self.isgrounded then
			item_fall(self, 0,5, 0,5)
		else
			self.t+=1
		end

		if self.t>150 or self.pos.y>127 then
			del(items,self) 
		end
	end
	
	obj.draw=function(self)
		spr(36,self.pos.x,self.pos.y+3)
	end
	
	
	add(items,obj)
end


function item_bonus(x,y)
	local bonustypes={53,55,56}

	local obj={
		lasty=y,
		pos={x=x,y=y},
		isgrounded=false,
		hitbox={x=0,y=0,w=7,h=7},
		t=0,
		blx=0,bly=5,brx=0,bry=5,
		sp=random_pick(bonustypes)
	}
	
	obj.dx,obj.dy=dir_calc(.25,3)
	
	obj.update=function(self)
		--only move when it's not on a layer
		if not self.isgrounded then
			item_fall(self, 0,7, 7,7)
		else
			self.t+=1
		end

		if self.t>150 or self.pos.y>127 then
			del(items,self) 
		end
		
		if collide(self,p1) then
			bonus_pickup(self)
			del(items,self) 
		end
	end
	
	obj.draw=function(self)
		spr(self.sp,self.pos.x,self.pos.y+1)
	end
	
	
	add(items,obj)
end



function item_fall(self, blx,bly,brx,bry)
	self.dy+=.8 --gravity
	self.pos.y+=self.dy
	self.pos.x+=self.dx
	
	if not self.drop then
		if self.pos.y>self.lasty then
			if fallcheck(self, blx,bly,brx,bry) then
				self.pos.y=flr((self.pos.y)/8)*8
				self.dy=0
				self.dx=0
				self.isgrounded=true
			end
		else
			self.lasty=self.pos.y
		end
	end
end



function item_update()
	for self in all(items) do self.update(self) end
	
	item_t+=1
end

function item_draw()
	for self in all(items) do self.draw(self) end
end



-- #bonus
bonus_all={}
bonus_t=0
function bonus_create()
	local obj={
		pos={x=random(16,100),y=-20},
		hitbox={x=0,y=0,w=8,h=16}
	}
	add(bonus_all,obj)
end

function bonus_update()
	for self in all(bonus_all) do
		self.pos.y+=1
		
		for b in all(gunner.bullets) do
			if collide(self,b) then
			
				item_bonus(self.pos.x,self.pos.y)
				del(bonus_all,self)
				del(gunner.bullets,b)
				del(gunner.actors,b) 
			end
		end
		
		if self.pos.y>127 then del(self,bonus_all) end
	end
	
	if bonus_t==450 then --450=15s
		bonus_t=0
		bonus_create()
	end
	
	bonus_t+=1
end

function bonus_draw()
	for self in all(bonus_all) do
		spr(24,self.pos.x,self.pos.y,2,2)
		--debug_hitbox(self.pos.x,self.pos.y,self.hitbox) 
	end
end

function bonus_pickup(obj)
	--53=timeup,54=multi,55=speed,56=slowdown

	if obj.sp==53 then
		game_clock+=5
	end
	
	if obj.sp==54 then
		medal_mult=2
	end
	
	if obj.sp==55 then
		p1.speed=min(3,p1.speed+.25)
	end
	
	if obj.sp==56 then
		bomb_speed=max(1.5,bomb_speed-.5)
	end
end






--[[ #explode
explode={
	all={},
	spark=function(x,y)
		--explode.create(x,y, 24, 20, {7,9,10}, .3)
		explode.create(x,y, 24, {
			size=24,
			dur=20,
			colors={7,9,10},
			grav=.3
		})
	end,
	blood=function(x,y)
		explode.create(x,y, 48, {
			dur=90,
			colors={15,8,8,2,14,2,2},
			grav=2,
			den=3,
			speed={min=2,max=2}
		})
	end,
	boom=function(x,y)
		explode.create(x,y, 32, {
			dur=60,
			colors={8,9,10,5},
			grav=0,
			den=7,
			speed={min=2,max=3}
		})
	end,
	boom_small=function(x,y)
		explode.create(x,y, 32, {
			dur=60,
			colors={8,9,10,5},
			grav=0,
			den=3,
			speed={min=2,max=3}
		})
	end,
	
	--create=function(x,y, size, dur, colors, grav, den, speed)
	create=function(x,y, size, options)
		--if not den then den=0 end
		--if not speed then speed=1 end
		
		for n=0,size do
			
			local obj={
				x=x,y=y,
				t=0,
				dur=30,
				den=0,
				dia=0,
				colors={7,10},
				speed={min=1,max=1},
				grav=.3,
				dirmin=0,
				dirmax=1
			}
			
			if options then
				for k,v in pairs(options) do obj[k] = v end
			end
			
			local c=flr(rnd(#obj.colors))+1
			
			obj.c=obj.colors[c]
			obj.gv=rnd(obj.grav)+.1
			
			
			--obj.dir=rnd(obj.dirmax)+obj.dirmin
			obj.speed=rnd(obj.speed.max-obj.speed.min)+obj.speed.min
			obj.dir=rnd(obj.dirmax-obj.dirmin)+obj.dirmin
			
			obj.dx,obj.dy=dir_calc(obj.dir,obj.speed)
			
			add(explode.all,obj)
		end
	end,
	update=function()
		foreach(explode.all, function(self)
			self.dy+=self.gv    -- gravity
			self.y+=self.dy
			self.x+=self.dx   -- update position

			self.t+=1
			self.den-=.25
			self.dia=max(self.den,0)

			if self.t>self.dur then del(explode.all, self) end
		end)
		
	end,
	draw=function()
		foreach(explode.all, function(e)
			--pset(e.x,e.y, e.c)
			circfill(e.x,e.y, e.dia, e.c)
		end)
	end
	
}
]]



--#boss
boss_init=function()
	boss_st=1
	ship_x=127
	ship_y=112
	bgun_x=127
	boss_t=0
	boss=true
	bgun_time=60
	bgun_dir=-1
	bgun_speed=1.5
	sub_x=24
	sub_y=112
end

boss_update=function()
	if boss_st==0 then
		
	end

	if boss_st==1 then
		
		if sub_y<127 then sub_y+=.35 end
		if ship_x>-64 then ship_x-=1 else boss_st=2 end
	end
	
	if boss_st==2 then
		if bgun_x>64 then bgun_x-=2 else boss_st=3 boss_t=0 end
	end
	
	if boss_st==3 then
		bgun_x+=bgun_speed*bgun_dir
		if bgun_x<10 or bgun_x>105 then
			bgun_dir*=-1
		end
		
		local wait=random(bgun_time-10,bgun_time)
		
		if boss_t>wait then 
			boss_st=4 
			boss_t=0 
			explode_bgun(bgun_x+8,bgun_y)
			bshot_create(bgun_x+8,bgun_y)
		end
	end
	
	if boss_st==4 then
		
		if boss_t>30 then 
			boss_st=3 
			boss_t=0 
		end
	end
	
	bgun_y=ship_y+1
	boss_t+=1
	
	bshot_update()
end


boss_draw=function()
	palt(13,true)
	palt(0,false)
	map(0,0, ship_x,ship_y, 24,2) --far trees
	spr(58, bgun_x,bgun_y, 2,1)
	bshot_draw()
	
	
	palt()
end
bshot_force={7,9,11,13}
bshot_all={}
bshot_create=function(x,y)
	local obj={
		lasty=y,
		pos={x=x,y=y},
		isgrounded=false,
		hitbox={x=1,y=2,w=6,h=5},
		t=0,
		drop=false,
		blx=1,bly=8,brx=1,bry=8,
		blink=0
	}
	
	obj.dx,obj.dy=dir_calc(.25,random_pick(bshot_force))
	
	
	add(bshot_all,obj)
end

bshot_update=function()

	for self in all(bshot_all) do
		--only move when it's not on a layer
		item_fall(self, 0,7, 7,7)
		if self.isgrounded and not self.drop then
			self.t+=1
		end

		if self.drop and self.pos.y>120 then
			explode_bgun(self.pos.x,self.pos.y)
			ship_y+=1
			bgun_speed=min(5,bgun_speed+.5)
			bgun_time=max(45,bgun_time-5)
			del(bshot_all,self)
		end
		
		if (self.t>150 or self.pos.y>127) and not drop then
			local tile=self.pos.x+4/8
			
			--remove_ground=function(layer,dir,slot)
			
			del(bshot_all,self) 
		end
		
		if collide(self,p1) and self.isgrounded and not drop then
			self.drop=true
			--bonus_pickup(self)
			--del(bshot_all,self) 
		end
	end
end

bshot_draw=function()
	for b in all(bshot_all) do
		if b.blink>5 then pal(0,7) pal(5,7) palt(0,false) palt(13,true) b.blink=0 end
		spr(22,b.pos.x,b.pos.y)
		pal()
		b.blink+=1
	end
end




-- #game

game_wait=55
boss=false
function game_init()
	cart_update=game_update
	cart_draw=game_draw
	
	game_clear()
	
	clock_running=true
	collected=0
	--quota+=5
	p1.pos={x=60,y=10}
	game_st=2
	game_t=0
	item_t=0
	row_time=0
	gunner.t=bomb_time-20
	items={}
	bonus_all={}
	
	if stage>5 then
		bgtheme=stages[stage][1]
		quota=stages[stage][2]
		bomb_time=stages[stage][3]
		bomb_max=stages[stage][4]
		bomb_speed=stages[stage][5]
		
		--resets all tiles to proper sprites (51=red steel)
		gunner.rows={
			{y=28,front=-1,last=16},
			{y=31,front=-1,last=16},
			{y=34,front=-1,last=16},
			{y=37,front=-1,last=16}
		}
		
		game_levelmap()
	else
		--start boss
		boss_init()
		bgtheme=4
		quota=99
		bomb_time=90
		bomb_max=20
		bomb_speed=2.5
		
		--resets all tiles to proper sprites (51=red steel)
		gunner.rows={
			{y=28,front=-1,last=16},
			{y=31,front=-1,last=16},
			{y=34,front=-1,last=16},
			{y=37,front=-1,last=16}
		}
		
		game_levelmap()
	end
	
	--bomb_time=max(25,bomb_time-5) --time between bomb spawns
	--bomb_max=min(32,bomb_max+4) --max number of bombs on screen
	--bomb_speed=min(flr(bomb_speed+.25), 3) --motion speed of bombs
	
	
	--if stage>3 then bgtheme=2 end --10,15,20 -forest
	--if stage>6 then bgtheme=3 end --25,30,35 -mountain
	--if stage>9 then bgtheme=4 end --40,45,50 -subs
end

function game_update()
	p_update()
	gunner._update()
	item_update()
	expl_update()
	bonus_update()
	boss_update()
	
	if clock_running then
		game_clock=clock.update(game_clock,-1)
	end
	
	bomb_time=max(20,bomb_time-.002)
	bomb_speed=min(bomb_speed+.0005, 3)
	
	
	if collected>=quota then
		clock_running=false
		
		if game_st==1 then
			game_clear()
			game_st=2
			game_t=0
		end
		
		if game_st==2 then
			if game_t>30 then chapter_init() end
		end
	else
		if game_t>game_wait-15 then game_st=2 end
		if game_t>game_wait then game_st=1 end
	end
	
	game_t+=1
	
end


function game_draw()
	camera(cam.x,cam.y)
	gunner._draw()
	boss_draw()
	p_draw()
	expl_draw()
	item_draw()
	bonus_draw()
	
	status_draw()
	--[[
	if game_st==0 then
		print("collect "..quota.." medals",30,46,0)
		print("collect "..quota.." medals",31,45,10)
	end]]
	
	local bordercolor=6
	if p1.ammo<=0 then bordercolor=8 end
	rect(0,11,127,127, bordercolor)
end

function game_reset() --starting values for a new game
	--collected=9
	--quota=5
	stage=0	
	bgtheme=1
	bomb_time=40
	bomb_max=8
	bomb_speed=2
	lives=3
	game_clock=120
	clock_running=false
	
	expl_all={}
	items={}
	
	
	
	game_clear()
end

function game_levelmap() --rebuilds levels to show proper sprite
	for block in all(gunner.rows) do
		for n=0,15 do mset(n,block.y,51) end
	end
end

function game_clear()
	gunner.actors={}
	gunner.bombs={}
	gunner.medals={}
	
	
	p1.ammo=5
end




-- #chapter

stages={
	{4,20,40,10,1.85,"forest","shoot rockets to get medals"}, --1theme,2quota,3minbombtime,4bombmax,5maxbombspeed,6textname
	{2,30,35,15,2.25,"mountains","don't forget to reload"},
	{3,40,30,20,2.5,"weapons warehouse","use \148 to fall from top floor"},
	{4,50,30,25,2,"submarine base","save the world!"},
}

chapter_init=function()
	cart_update=function() end
	cart_draw=chapter_draw
	
	
	stage+=1
	quota=stages[stage][2]
	
	p1.idle=false
	p1.flip=false
	p1.pos.x,p1.pos.y=-8,85
end

chapter_draw=function()
	rectfill(0,0,127,127,1)
	center_text("stage "..stage, 29, 0)
	center_text("stage "..stage, 30, 7)
	
	
	center_text(stages[stage][6], 39, 0)
	center_text(stages[stage][6], 40, 7)
	
	center_text("collect "..quota.." medals", 59, 0)
	center_text("collect "..quota.." medals", 60, 10)
	
	center_text(stages[stage][7], 109, 0)
	center_text(stages[stage][7], 110, 6)
	
	p1.pos.x+=1
	
	if p1.pos.x>128 or btnzp or btnxp then game_init() end
	
	p_draw()

end





-- #status
function status_draw(x,y)
	camera(0,0) --keeps status bar still while camera shake
	rectfill(0,0,127,11,0) --background
	line(0,11,127,11,6)
	
	--ammo count?
	local thisx=130
	for n=1,p1.ammo do spr(52,thisx-6*n, 3) end
	if p1.ammo<=0 then
		rectfill(94,2,126,8,8)
		print("\151reload",95,3,7)
	end

	--stage number
	--print("stage "..stage,3,3,6)
	--for n=0,lives-1 do print("\135", 7*n,3, 8) end
	print(clock.text(game_clock), 7,3,7)

	 --medal count
	spr(19, 51,2)
	print(collected.."/"..quota,61,3,9)
end




-- #title

function title_init()
	cart_update=function() end
	cart_draw=title_draw
	
	game_reset()
end

function title_draw()
	print("press x to start",60,40,7)
	if btnzp then chapter_init() end	
end



-- #gameover
function gameover_init()
	cart_update=gameover_update --lets explosions finish up, still using game draw
	
	game_clear()
	t=0
end

function gameover_update()
	item_update()
	expl_update()
	
	if t>60 then cart_draw=gameover_draw end
end

function gameover_draw()
	print("game over",60,40,7)
	if btnzp then title_init() end	
end


-- #loop
function _init()
	t=0
	title_init()
end


function _update()
	btnl=btn(0)
	btnr=btn(1)
	--btnlp=btn(0)
	--btnrp=btn(1)
	--btnu=btn(2)
	--btnd=btn(3)
	btnup=btnp(2)
	btndp=btnp(3)
	--btnz=btn(4)
	--btnx=btn(5)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	--mx,my = mouse.pos()
	--mb = mouse.button()
	
	cart_update()
	t+=1
end

function _draw()
	cls()

	cart_draw()
	
	if debug then print(debug, 10,30, 1) print(debug, 10,29, 11) end
end


--#util
function debug_hitbox(x,y,hitbox) 
	rect(x+hitbox.x,y+hitbox.y, x+hitbox.w,y+hitbox.h, 11)
end


clock={
	update=function(cv,d)
		d=d or 1
		cv+=1/30*d
		
		if d<0 and cv<=0 then cv=0 end

		return cv
	end,
	text=function(cv)
		local mins=flr(cv/60)
		local sec=flr(cv%60)
		if (sec<10) then sec="0"..sec end
		
		return(mins..":"..sec.."."..(flr(10*(cv-flr(cv)))).."")
	
	end
}



function fallcheck(obj, blx,bly, brx,bry)
	local botl=mget((obj.pos.x+blx)/8,((obj.pos.y+bly)/8)+mapoff)
	local botr=mget((obj.pos.x+brx)/8,((obj.pos.y+bry)/8)+mapoff)

	if fget(botl,0) or fget(botr,0) then
		return true
	end
	
	return false
end


function skyfade(y,c,inv,rows)
	rows=rows or {0,1,2,4,5,7,10,15}
	inv=inv or -1

	for b in all(rows) do
		line(0,y+b*inv, 127,y+b*inv, c)
	end
end

function center_text(s,y,c) print(s,64-(#s*2),y,c) end

function random_pick(t)
	local r=flr(rnd(#t))+1
	return(t[r])
end


function anim(o,sf,nf,sp,fl)
	if(not o.a_ct) o.a_ct=0
	if(not o.a_st)	o.a_st=0

	o.a_ct+=1

	if(o.a_ct%(30/sp)==0) then
	 o.a_st+=1
	 if(o.a_st==nf) o.a_st=0
	end

	o.a_fr=sf+o.a_st
	spr(o.a_fr,o.pos.x,o.pos.y,1,1,fl)
end
			
function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end
			
		
			
			
function collide(obj, other)
    if
        other.pos.x+other.hitbox.x+other.hitbox.w > obj.pos.x+obj.hitbox.x and 
        other.pos.y+other.hitbox.y+other.hitbox.h > obj.pos.y+obj.hitbox.y and
        other.pos.x+other.hitbox.x < obj.pos.x+obj.hitbox.x+obj.hitbox.w and
        other.pos.y+other.hitbox.y < obj.pos.y+obj.hitbox.y+obj.hitbox.h 
    then
        return true
    end
end			

			
function offscreen(x,y)
	if (x<screen.x or x>screen.w or y<screen.y or y>screen.h) then 
		return true
	else
		return false
	end
end
			
-- get a random number between min and max
function random(min,max)
	n=round(rnd(max-min))+min
	return n
end
			
function rand(min,max)
	return rnd(max-min)+min	
end

-- round number to the nearest whole
function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end			
			

			
function explode_wall(x,y,dir)
	local wdir=.5
	if dir<0 then wdir=1 end
				
	expl_create(x,y,20,{
		dur=30, --last for 15 frames
		den=8, --start with 3-diameter circles
		decay=.4, --reduce circles by .4 each tick
		colors={10,10,9,7}, --pick a random color from this list
		smin=1, --minimum speed
		smax=3, --maximum speed
		grav=.3, --no gravity, so they don't fall
		dir=wdir, --force it to the right
		range=.5 --limit range to .125 around direction (.0625 on either side)					
	})
end
			
function explode_bomb(x,y)
	expl_create(x,y,16)			
	expl_create(x,y,20,{
		dur=30, --last for 15 frames
		den=5, --start with 3-diameter circles
		decay=.2, --reduce circles by .4 each tick
		colors={5,0,6}, --pick a random color from this list
		smin=1, --minimum speed
		smax=2, --maximum speed
		grav=-.1, --no gravity, so they don't fall
		dir=.25, --force it to the right
		range=.0625 --limit range to .125 around direction (.0625 on either side)					
	})
end
			
function explode_blood(x,y)
	expl_create(x,y,32,{
		dur=30, --last for 15 frames
		den=5, --start with 3-diameter circles
		decay=.4, --reduce circles by .4 each tick
		colors={8,2,8,8,2,14}, --pick a random color from this list
		smin=1, --minimum speed
		smax=4, --maximum speed
		grav=.8, --no gravity, so they don't fall
		dir=0, --force it to the right
	})
end
			
function explode_spark(x,y)
	expl_create(x,y,24,{
		dur=15, --last for 15 frames
		colors={10,7,9,6}, --pick a random color from this list
		grav=.6, --no gravity, so they don't fall
		dir=.25, --force it to the right
		range=.25
	})		
end

function explode_bgun(x,y)
	expl_create(x,y,24,{
		dur=22, --last for 15 frames
		colors={10,7,9,6}, --pick a random color from this list
		den=4, --start with 3-diameter circles
		decay=.2, --reduce circles by .4 each tick
		grav=.8, --no gravity, so they don't fall
		smin=2, --minimum speed
		smax=6, --maximum speed
		dir=.25, --force it to the right
		range=.5
	})		
end

			
expl_all={}
expl_create=function(x,y, size, options, callback)
	for n=0,size do
		local obj={
			x=x,y=y,
			t=0,
			dur=30,
			den=0,
			decay=.25,
			dia=0,
			colors={7,10,9},
			smin=.25,
			smax=1,
			grav=.3,
			dir=0,
			range=0
		}
		
		if options then
			for k,v in pairs(options) do obj[k] = v end
		end
		
		local c=flr(rnd(#obj.colors))+1
		local sp=rnd(obj.smax-obj.smin)+obj.smin

		if obj.dir>0 then
			local dirh=obj.range/2
			local dira=obj.dir-dirh
			local dirb=obj.dir+dirh
			
			obj.dir=rnd(dirb-dira)+dira
		else
			obj.dir=rnd()	
		end
	
		obj.c=obj.colors[c]
		obj.g=rnd(abs(obj.grav))
		obj.dx=cos(obj.dir)*sp
		obj.dy=sin(obj.dir)*sp
		
		if obj.grav<0 then obj.g*=-1 end

		add(expl_all,obj)
	end
end

expl_update=function()
	foreach(expl_all, function(o)
		o.dy+=o.g
		o.y+=o.dy
		o.x+=o.dx
		o.t+=1
		o.den-=o.decay
		o.dia=max(o.den,0)

		if o.t>o.dur then del(expl_all, o) end
	end)
end

expl_draw=function()
	foreach(expl_all, function(e)
		circfill(e.x,e.y, e.dia, e.c)
	end)
end			

__gfx__
00000000ddddddddd9999dddd9999ddd89999dddddddddddd9999dddd9999ddd89999ddddddddddddddddddddddddddddddddddd000000000000000000000000
00000000d9999dddd8888ddd88888dddd8888dddd9999dddd8888ddd88888dddd8888ddddddddddddd00000000000000ccccc7cc000000000000000000000000
00000000d8888ddd891f1dddd91f1dddd91f1ddd88888ddd891f1dddd91f1dddd91f1dddddddddddddd0d0dd0d0d0d00dddddddd000000000000000000000000
00000000891f1dddd9fffdddd900fdddd9fffdddd91f1dddd9fffdddd9ff00ddd9fffddddd5555dddddd0000000000d0dc77cccd000000000000000000000000
00000000d9fffdddd3333dddd3003dddd3333dddd9fffdddd3333ddd033300ddd3333ddddd544dddddddd0ddddddd0d0dddddddd000000000000000000000000
00000000d3333dddd00bbdddddddddddd00bbdddd3333dddd3300dddddddddddd3300dddddddddddddddd0ddddddd000ddddcc7d000000000000000000000000
00000000d33bbdddddd0ddddddddddddddd0ddddd33bbddd0ddddddddddddddd0dddddddddddddddddddd0ddddddd0d0dddddddd000000000000000000000000
00000000d0dd0dddddddddddddddddddddddddddd0dd0ddddddddddddddddddddddddddddddddddddddd0dddddddd0d0dddddddd000000000000000000000000
b3bb3bbb004444007a00000008788780000000000aaa0000d55ddddd00000000000bbb0000000000ddddddddddddd000dddddddddddddddd0000000000000000
3333333304999950abbb00000878878000000000aaaaa0009dd5dddd0000000000bbbbb000000000ddddddddddddd0d0dddddddddddddddd0000000000000000
54545454499944956bbbb000087887800777770709990000dd0055dd000000000b3bbb3b00000000ddddddddddddd0d0dddddddddddddddd0000000000000000
44444444449945956bbbb300006226008666666600000000d000065d000000003303b30330000000ddd000000d000000d000000d000000dd0000000000000000
44444444494999956bbb3333000aa0002666666600000000d000005d000000003000300030000000dd00000000000000000000000000000d0000000000000000
45444454499599956003333000aa99000555550500000000d000000d000000005000500050000000dd00000005000000500000050000000d0000000000000000
44444544049999506000000000a999000000000000000000d000000d000000000600500600000000dd00000000000000000000000000000d0000000000000000
445444440055550060000000000990000000000000000000dd0005dd000000000600600600000000dddddddddddddddddddddddddddddddd0000000000000000
22224222111111116004444000000000067770007707700007070000007000000060606000000000dddddddddddddddddddddd0ddddddddd0000000000000000
24222242111111116041111400000000088880000060000000600000006000000006660000000000dddddddddddddddddddd0d0ddddddddd0000000000000000
222222224141414160411114cccccccc861610000060888000608880006088800944444900000000ddddddddddddddddd0000000dddddddd0000000000000000
221221222414242460411114cccccccc0677700000681f1000681f1000681f100494449400000000dddddddddddddddd00000000dddddddd0000000000000000
212222125152525260411114cccccccc006700000558fff00558fff00558fff0044aaa440000000000ddddddddddddd000000110dddddddd0000000000000000
1222122212221222604111141c1c1c1c000000000552222005522220055222200444a44400000000000dd000000000000000000000000ddd0000000000000000
212121212121212160415514c1c1c1c10000000000522880005228800052288004944494000000000000000000000000000000000000000d0000000000000000
1111111111111111604555541c1c1c1c000000000002002000020020000200200944444900000000000000000000000000000000000000000000000000000000
44444444dddddddd66666666888888880a000000a99999a028888820b33333b01ccccc1000000000dddddddddddddddd00000000000000000000000000000000
44544454dddddddd55566555222882229a700000999799908878788033373330ccccccc000000000ddddd000000ddddd00000000000000000000000000000000
44454444dddddddd00605600008028009a700000999799908878788033377330cc77c7c000000000ddddd500056ddddd00000000000000000000000000000000
44444445dddddddd06000560080002809a700000977777908887888037777730c77777c000000000ddddd500056ddddd00000000000000000000000000000000
45444454dddddddd60000056800000289aa00000999799908877788033377330cc77c7c000000000dddd66666667dddd00000000000000000000000000000000
44445444dddddddd666666668888888899900000999799908887888033373330ccccccc000000000d66666866666667d00000000000000000000000000000000
44444444dddddddd555555552222222200000000a99999a028888820b33333b01ccccc1000000000d65656666665656d00000000000000000000000000000000
44544444dddddddd0000000011111111000000000000000000000000000000000000000000000000dd0d0dddddd0d0dd00000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddd61111101111101111101111101111116ddddddddddddddd7dddddddddddddddd00000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddd56111101111101111101111101111166ddddddddddddd777dddddddddddddddd00000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddd05611101111101111101111101111616ddddddddddd7706677dddddddddddddd00000000
ddddddddddddddddddddddddddddddddddddddddddddddd1dddddddd01561101111101111101111101116516dddddddddd7066676677dddddddddddd00000000
dddddddddddddddddddddddddddddddddddddddddddddd11dddddddd01156101111101111101111101165116dddddddd77667706776077dddddddddd00000000
ddddd2dddddddddddddddddddddddddddddd1dddddddddd11ddddddd00005600000000000000000000650006dddddd77760767076076607ddddddddd00000000
ddddd2dddddddddddddddddddddddddddddd1ddddddddd11dddddddd01111561111101111101111106511106ddddd77660767060766776777ddddddd00000000
ddddd2ddddddddddddddddddddddddddddd11dddd1ddddd1ddddd1dd01111106111101111101111165111106ddd776600660060070060766777ddddd00000000
dddd222dddddddddddddddddddddddddddd111ddd1ddd1111dddd1dd01111105611101111101111651111106d7766000600000000000607766777ddd00000000
ddddd2dddddddddddddddddddddddddddd1d1ddd11dddd1111dd11dd011111015611011111011165011111067060000600006000000006007067077d00000000
dddd222dddddddddddddddddddddddddddd111ddd11d11111dddd11d011111011561011111011651011111060000000000070000007000000006600700000000
ddd222ddddddddddddddd2dddddddddddd1d11dd11dddd1111dd11dd011111011156011111016511011111060070067000000000007000700000060000000000
ddddd222ddddddddddddd2ddddddddddd1111d1d1111d111111d1111011111011115611111065111011111060700600000000000000700066000000000000000
ddddd22ddddddd2ddddd22dddddddddd1d1111d1d11d11d111111111011111011111561111651111011111060000000000000000000000000760000000000000
ddd22222dddddd2dddddd22ddddddddd1111111d1111111111d11111011111011111056116511111011111060000000000000000000000000000000000000000
dddd22d2ddddd22ddddd222dddd2dddd111111111111111111111111011111011111015665011111011111060000000000000000000000000000000000000000
ddd222222ddddd22ddddd2ddddd2dddd111111110000000000000000011111011111011661011111011111060000000000000000000000000000000000000000
ddddd22dddddd22ddddd2222ddd2dddd111111110000000000000000011111011111016556011111011111060000000000000000000000000000007000000000
ddd222222ddd2222ddd2222ddd222ddd010101010000000000000000011111011111065115611111011111060000077000000070000001000000c0c000000000
dd222222dddddd2d2dddd2ddddd22ddd10101010000000000000000001111101111165111106111101111106007700000008090000c710000000000000000000
dddd2d222dddd222ddd222222d22dddd010101010000000000000000011111011116011111056111011111060000000077000000000000008080070000000000
ddd22222222d222222dd222dddd222dd101010100000000000000000011111011165011111015611011111060ca009000000000090990000000000c000000000
dd2222d22dddd2d22dd222222d222ddd000000000000000000000000011111011651011111011561011111060000000000000000007770000888080000000000
d2d2222222dd2222d22dd222d222222d0000000000000000000000000111110165110111110111560111110600000099009000000000000a0000000000000000
2d2d22222d22d22222d222d2222d22d2000000000000000000000000011111065111011111011115611111060000000000000000000000000000000000000000
222d2222222d222d222d222222d22222000000000000000000000000011111651111011111011111061111060000000000000000000000000000000000000000
d2d222222d2222222d2d2222d22222d2000000000000000000000000011116011111011111011111056111060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000011165011111011111011111015611060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000011651011111011111011111011561060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000016511011111011111011111011156060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000065111011111011111011111011115660000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000651111011111011111011111011111560000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000ddddddddddddddddddddddd0dddddddddddddddd000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000ddddddddddddddddddddddd0dddddddddddddddd000000000000000000000000
0000000000000000000000000000000000000000003333000033330000000000ddddddddddddddddddddd0d0dddddddddddddddd000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000ddddddddddddddddddddd0d0dddddddddddddddd000000000000000000000000
3333333333333333333333333333333300000000000000000000000000000000ddddddddddddddddd00000000000000000dddddd000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd055660566666565550dddddd000000000000000000000000
00000000000000000000000000000000b4c4d4e4b4c4d4e4b4c4d4e4b4c4d4e4dddddddddddddddd0560006000000000000ddddd000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd0500005000000000000ddddd000000000000000000000000
00000000000000000000000000000000b5c5d5e5b5c5d5e5b5c5d5e5b5c5d5e5dddddddddddddddd05000050000000000000dddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd05555556550066006600dddddddddddddddddddddddddd00
333333333333333333333333333333330000000000b6000000000000e6000000dddddd0000000000500000000006006006000dddddddddddddddddddddddd050
0000000000000000000000000000000000000000000000000000000000000000dddd0005555665565666555500060060060000dddddddddddddddddddddd0500
00000000000000000000000000000000b600d6c6e600000000d6c6d600c60000dd006555555500000000000000060060060000000000000000000000ddd00500
0000000000000000000000000000000000000000000000000000000000000000d06655555500000000000000000066006660000555555556560056550d005000
000000000000000000000000000000000000c60000c600000000b60000e600000655555000000000000000000000000000000000000000000000000000050000
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000ddddddddddddddddd3dddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd33dddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd33dddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000ddddddddddddddddd3dddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd5dddddddbbbbbbbddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000ddddddddddddddddd3bbb3333333333bddd3dddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddd333333333333333bbd3bdddddddddddddddddd3bbbbddddd
0000000000000000000000000000000000000000000000000000000000000000ddddddddddddddd333333333333373333d33bbbbbbbbbbbbbbbb333333bddddd
0000000000000000000000000000000000000000000000000000000000000000ddddbbdddddddd3333bbb3bbb3377733b3b33330000000000000033333bddddd
0000000000000000000000000000000000000000000000000000000000000000ddd333bdddd333b3b330b330b333733333b3dddddddddddddddddd30000ddddd
0000000000000000000000000000000000000000000000000000000000000000ddd0333ddd333303033333333333333333333ddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddd0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbdddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dd333333333333333333333333333333333333333333bbdddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000d3333333333333333333333333333333333333333333333ddddddddddddddddd
000000000000000000000000000000000000000000000000000000000000000033333300000003330000000333000000033300000003333bdddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddd8ddddddddddddddddddddddddddddddd6ddddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddd7ddddddddddddddddddddddddddddd6dd6dddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddd7d8dddddddddddddddddddddddddddd6dd6ddddddddddddddddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddd7d7ddddddddddddddddddddddddddddd6dd6d67777777777dddddddddddd
0000000000000000000000000000000000000000000000000000000000000000dddd7d7dddddddddddddddddddddddddddddd6dd677555555555dddddddddddd
0000000000000000000000000000000000000000000000000000000000000000566777777777777777777ddddddddddddddddd677555555588555ddddddddddd
00000000000000000000000000000000000000000000000000000000000000005556666666666666666666ddd77dd77ddddddd655555555555555ddddddddddd
0000000000000000000000000000000000000000000000000000000000000000d555566666666666666666666666666666666666666666666666666666666666
0000000000000000000000000000000000000000000000000000000000000000dd55555555555555555555555555555555555555555555555555555555555555
0000000000000000000000000000000000000000000000000000000000000000dd55555555555555555555555555555555555555555555555555555555555555
0000000000000000000000000000000000000000000000000000000000000000ddd5555557777775577755555555665665555555555555555555555556656655
0000000000000000000000000000000000000000000000000000000000000000ddd5555557777775577755555555005005555555555555555555555550050055
0000000000000000000000000000000000000000000000000000000000000000dddd555557755775557755555555555555555555555555555555555555555555
0000000000000000000000000000000000000000000000000000000000000000ddddd55557755775557755555555555555555555555555555555555555555555
0000000000000000000000000000000000000000000000000000000000000000ddddd88887788778887788888888888888888888888888888888888888888888
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
0000000000000000000000000000000001010002000000000000000000000000010904000000000000000000000000000102010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
c8c9cacbcccdcecfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcfcf00000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d8d9dadbdcdddedfdfdddddddfdfdddddddfdfdddddddfdfde00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88898a8b8c888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
98999a9b9c9d9d9e9d9f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003100000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000310000000000000031000000000000000000000000111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031000000000000000000000011000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000001111001111110000110000000000000000000000000000000a0b000000000000000a0b00000000000000000000000000000000000000000000000000000000000000003232323200000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000010000000000000003232323232323232323200000000000000000000310032001a1b1c1d00001a1c1d1a1b1c1c1c1d000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000100030000000000000000000000000000000000000000000000000000000000000000c0c0c00000000000c0c0c00000000000000000000000000000000000000320000000000000000323232000000000000003200000000000000000000000000
1100000000000000310000000000001100000000000000110000000000100030003000000000000000000000000000000000000000000000100010100000000000000000002a2b2c2d0000002a2b2c2d000000000000000000000000003200000000000000000000000000000031000000000000000000100000003100000011
11001200000000001100000000001111310000000032323200000031003000300030000000000000000000000000000000000000000000103000303000000032002a2b2c2d00000c0c00002a2b2c2d0c000000000000000000000032000000000000000000000000000000001010000000320000000000300000000000120011
110022000000001111000000001111113232320000000000000000100030003000300000000011000000000000000000000000310000103030000031000000000000000c0c000000000000000c0c0c00000000000000001111110000000000000000000000000000000010003030000000003100000000300000000000220011
1010101010101010101010101010101023232323232323232323103023300030003000000000101010100000000010000000101023233030302323232310101000000000000000000000000000000000101023232310101010102323231000000000000000001010102330233030000000001000000000300000101010101010
2020202020202020202020202020202021212121212121212121202021206420642064000000202020206464646420646464202021212020202121212120202000000000000000000000000000000000202021212120202020202121212064646464646464642020202120212020646464642064646464206464202020202020
4041424340414240414243434041404140414243404100004445464444454646444546444546444546444546444546464445464444454646444445464445464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051525350515250515253535051505150515253505100005455565454555656545556545556545556545556545556565455565454555656545455565455565600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626360616260616263636061606160616263606100006464646464646464646464646464646464646464646464646464646464646464646464646464646400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727370717270717273737071707170717273707100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4748494a0000000000000000000000007d7e7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5758595a0000000000000000000000008d8e8f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6768696a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7778797a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333333333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333333333333333333333333333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100003b0503c0403c0503c0501e0503c05009050090503b0503a05000000380503505033050310502f0502b050270502505019050110500d05000000000000000000000000000000000000000000000000000
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

