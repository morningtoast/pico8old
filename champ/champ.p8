pico-8 cartridge // http://www.pico-8.com
version 8
__lua__

screen={x=0,y=0,w=128,h=128}

cart_update=function() end
cart_draw=function() end

game_time=0
g={grav=0.5}
collected=0
quota=25
cam={x=0,y=0}
mx=0 my=0 mb=0
shake=false

actors={}
bullets={}
shots={}
medals={}


pepsi_title_draw=function()
	print("shoot 15 medals\n\n\139 \145 jumps\n\nuse mouse/touch to aim+shoot\n\n\n\151 to start",10,20,7)
	if btnzp or btnxp then 
		pepsi._init()
		cart_update=pepsi._update
		cart_draw=pepsi._draw
	end
end

cart_draw=pepsi_title_draw

-- #pepsi
pepsi={
	t=0,
	grav=2.3,
	kills=0,
	reset=function()
		p1.pos={x=75,y=30}
		p1.dx=0
		p1.dy=0
		p1.isgrounded=false
		p1.dir=1
		p1.t=0
		p1.jumping=false
		p1.ang=0
		p1.bt=0
		p1.st=0
	end,
	_init=function()
		collected=0
		quota=15
		p1={
			hitbox={x=0,y=0,w=5,h=8},
			jumpvel=3,
			idle=true,
			flip=false,
			speed=3,
			gunx=0,
			guny=0,
		}
		
		pepsi.reset()
	end,
	_update=function()
		--remember where we started
		local startx=p1.pos.x
		
		p1.pcx=p1.pos.x+3
		p1.pcy=p1.pos.y+5
		p1.ang = atan2(mx-p1.pcx, my-p1.pcy)
		
		p1.guntipx,p1.guntipy=get_line(p1.pcx,p1.pcy, 6, p1.ang)
		
		--if btnzp then pepsi.new_drone(rnd()) end
		
		p1.dx=0
		p1.idle=true
		
		if mb==1 and not p1.jumping then
			if p1.bt==0 then pepsi.new_bullet() end
			p1.bt+=1
			if p1.bt>3 then p1.bt=0 end
		else
			p1.bt=0
		end

		-- player can jump if on the ground
		if (btnrp or btnlp) and not p1.jumping then
			p1.t=0
			p1.jumping=true
			--p1.dir=1
			
			if p1.dir==1 then 
				p1.dir=-1 
				p1.flip=true
			else
				p1.dir=1
				p1.flip=false
			end
		end
		
		if p1.jumping and p1.t<10 then
			p1.dy=-p1.jumpvel
			p1.t+=1
		else
			p1.jumping=false
		end

		if p1.jumping then
			p1.dx=p1.speed*p1.dir
			p1.pos.x+=p1.dx
		end
		
		--hit side walls
		local mapoffy=24
		local mapoffx=16
		local xoffset=0
		if p1.dx>0 then xoffset=5*p1.dir end

		--look for a wall in front of player
		local h=mget(((p1.pos.x+xoffset)/8)+mapoffx,((p1.pos.y+7)/8)+mapoffy)
		if fget(h,0) then p1.pos.x=startx end

		--accumulate gravity
		p1.dy+=pepsi.grav
		p1.pos.y+=p1.dy
		
		--check bottom corners of player. note offset from actual x value
		local botl=mget(((p1.pos.x+1)/8)+mapoffx,((p1.pos.y+8)/8)+mapoffy)
		local botr=mget(((p1.pos.x+5)/8)+mapoffx,((p1.pos.y+8)/8)+mapoffy)

		--assume they are floating until we determine otherwise
		p1.isgrounded=false

		--only check for floors when moving downward
		if p1.dy>=0 then
			if fget(botl,0) or fget(botr,0) then
				p1.pos.y = flr((p1.pos.y)/8)*8
				p1.dy = 0
				p1.isgrounded=true
			end
		end
		
		pepsi.t+=1
		
		
		if pepsi.t>40 then pepsi.new_drone() pepsi.t=0 end
		--explode.update()
		
		foreach(actors, function(b)	b.update(b) end)
		
		explode.update()
	end,
	_draw=function()
		rectfill(0,0,127,127,1)
		palt(0,false)
		rectfill(0,100,127,127,0)
		map(16,24, 0,0, 16,16) -- level
		--debug(mx..","..my)
		
		palt(13,true)
		
		

		if p1.isgrounded then
			spr(1,p1.pos.x,p1.pos.y,1,1,p1.flip) --standing
		else
			spr(6,p1.pos.x,p1.pos.y,1,1,p1.flip) --jumping
		end
		--if p1.flip then p1.dir=-1 else p1.dir=1 end
		--spr(9,p1.pos.x+(3*p1.dir),p1.pos.y+guny,1,1,p1.flip) --gun
		line(p1.pcx,p1.pcy, p1.guntipx,p1.guntipy, 0)
		draw_line(p1.pcx,p1.pcy+1, 4, p1.ang, 5)
		
		-- remove layer slots that have been destroyed (set map tile to empty)
		
		
		
		palt()
		
		--line(mx-1,my, mx+1,my, 10)
		--line(mx,my-1, mx,my+1, 10)
		circ(mx,my,1,10)
		
		status._draw(0,0)
		
		--circ(64,70, 50, 11) --inner for top/bottom
		--pset(64,75,11)
		--circ(64,70, 62, 12) --outer for corners
		
		foreach(actors, function(b) b.draw(b) end)
		
		--debug(foo.." / "..bar)
		explode.draw()
	end,
	new_bullet=function()
		local obj={
			pos={x=p1.guntipx,y=p1.guntipy},
			hitbox={x=0,y=0,w=1,h=1},
			t=0,
			speed=5,
			dx=0,
			dy=0,
			ang=p1.ang,
			bullet=true
		}
		
		obj.dx,obj.dy=dir_calc(obj.ang+rnd(.02),obj.speed)
		
		obj.update=function(self)
			self.pos.x+=self.dx
			self.pos.y+=self.dy
			
			if offscreen(self.pos.x,self.pos.y) then
				del(actors,self)
				del(bullets,self)
			end
			
			self.t+=1
		end
		
		obj.draw=function(self)
			--spr(21,self.pos.x,self.pos.y,1,1)
			pset(self.pos.x,self.pos.y, 7)
			
			draw_line(self.pos.x,self.pos.y, 3, self.ang+.5, 7)
		end
		
		add(actors, obj)
		add(bullets, obj)
	end,
	new_medal=function()
		local obj={
			pos={x=random(16,120),y=-5},
			hitbox={x=0,y=0,w=8,h=8},
			hp=2,
			st=1,
			t=0,
			speed=1,
		}
		
		obj.update=function(self)
			if self.st==1 then
				obj.pos.y+=1

				foreach(bullets, function(b)
					if collide(self,b) then
						self.hp-=1
						del(actors,b)
						del(bullets,b)

						if self.hp<=0 then
							sfx(0)
							collected+=1

							explode.spark(self.pos.x,self.pos.y)
								
							del(medals,self)
							del(actors,self)
						end
					end
				end)
				
				if collide(self,p1) then
					sfx(0)
					collected+=1
								
					del(medals,self)
					del(actors,self)
				end

				if obj.pos.y>130 or self.hp<0 then 
					del(medals,self)
					del(actors,self)
				end
			end
		end
		
		obj.draw=function(self)
			spr(19,self.pos.x,self.pos.y)
		end
		
		add(actors, obj)
		add(medals, obj)
		
	end,
	new_drone=function()
		local dir=1
		
		if rnd()<.5 then dir=-1 end
		
		
		
		local obj={
			pos={x=0,y=0},
			hitbox={x=0,y=0,w=8,h=8},
			hp=2,
			dir=dir,
			st=1,
			attack=random(40,120),
			t=0,
			speed=1,
			fr=15,
			flip=false
		}
		
		--bx,by=dir_calc(obj.ang,.5)
		--obj.pos.x,obj.pos.y=pt_on_circle(obj.ang,obj.circ.x,obj.circ.y,obj.circ.rad)
		obj.pos.y=random_pick({15,25,35,40,100,105,115})
		if obj.dir>0 then obj.pos.x=-10 else obj.pos.x=135 obj.flip=true end
		
		--obj.pos.x,obj.pos.y=get_line(obj.circ.x,obj.circ.y, obj.circ.rad, obj.ang)
		
		
		
		obj.update=function(self)
			--enter field
			if self.st==1 then
				self.pos.x+=self.speed*self.dir
				self.t+=1
				
				if self.t>self.attack then --time to wait before attacking
					self.st=2 self.t=0
				end
			end
			
			if self.st==2 then
				if self.t>15 then --delay before blitz
					self.ang=atan2(p1.pos.x-self.pos.x, p1.pos.y-self.pos.y)
					self.speed=1.25
					self.dx,self.dy=dir_calc(self.ang, self.speed)
					self.hp+=2
					self.st=3
					self.fr=30
					
					if self.pos.x>p1.pos.x then self.flip=true else self.flip=false end
				end
				
				self.t+=1
			end
			
			if self.st==3 then
				self.pos.x+=self.dx
				self.pos.y+=self.dy
				
				if offscreen(self.pos.x,self.pos.y) then del(actors,self) end
			end
			
			foreach(bullets, function(b)
				if collide(self,b) then
					self.hp-=1
					del(actors,b)
					del(bullets,b)
						
					if self.hp<=0 then
						if rnd()<.5 then pepsi.new_drone() end
						pepsi.kills+=1
						
						if pepsi.kills>3 then pepsi.new_medal() pepsi.kills=0 end
						sfx(0)

						explode.boom_small(self.pos.x,self.pos.y)
							
							del(actors,self)
					end
				end
			end)
			
			if not p1.jumping then
				if collide(self,p1) then
					explode.blood(p1.pos.x,p1.pos.y)
					collected=flr(collected/2)
					if collected<0 then collected=0 end
					pepsi.reset()
					del(actors,self)
					pepsi.kill_all()
				end
			end
		end
		
		obj.draw=function(self)
			--debug(self.ang)
			if self.st>2 then pal(11,8) end
			
			--spr(37,self.pos.x,self.pos.y)
			anim(self, 37, 3, self.fr, self.flip) -- running
			pal()
		end
		
		add(actors,obj)
	end,
	kill_all=function()
		actors={}
	end,
	new_tent=function(ang)
		local ang=ang or rnd()
		local dir=1
		
		if rnd()<.5 then
			dir=-1
		end
		
		
		
		local obj={
			pos={x=0,y=0},
			hitbox={x=0,y=0,w=8,h=8},
			hp=3,
			ang=ang,
			dir=dir,
			st=1,
			attack=random(60,150),
			t=0,
			speed=.0018,
			fr=15,
			flip=false,
			circ={x=64,y=70,rad=52}
		}
		
		--bx,by=dir_calc(obj.ang,.5)
		obj.pos.x,obj.pos.y=pt_on_circle(obj.ang,obj.circ.x,obj.circ.y,obj.circ.rad)
		
		--obj.pos.x,obj.pos.y=get_line(obj.circ.x,obj.circ.y, obj.circ.rad, obj.ang)
		
		
		
		obj.update=function(self)
			--enter field
			if self.st==1 then
				--self.pos.x+=2*self.dir
				self.t+=1
				if self.t>30 then --time to wait before attacking
					self.st=2 self.t=0
				end
				
				
				
			end

			-- circle player
			if self.st==2 then
				
				self.pos.x = cos(self.ang)*self.circ.rad+self.circ.x;
				self.pos.y = sin(self.ang)*self.circ.rad+self.circ.y;
				
				self.t+=1
				if self.t>self.attack then --time to wait before attacking
					self.st=3 self.t=0
				end
				
				self.ang+=self.speed*self.dir
				
				if self.pos.x>p1.pos.x then self.flip=true else self.flip=false end
			end
			
			if self.st==3 then
				if self.t>15 then --delay before blitz
					self.ang=atan2(p1.pos.x-self.pos.x, p1.pos.y-self.pos.y)
					self.speed=1.25
					self.dx,self.dy=dir_calc(self.ang, self.speed)
					self.hp+=3
					self.st=4
					self.fr=30
					
					if self.ang>.25 and self.ang<.75 then self.flip=true end
				end
				
				self.t+=1
			end
			
			if self.st==4 then
				self.pos.x+=self.dx
				self.pos.y+=self.dy
				
				--if offscreen(self.pos.x,self.pos.y) then del(actors,self) end
			end
			
			
			
			if self.pos.x<-20 or self.pos.x>140 or self.pos.y<-12 or self.pos.y>135 then 
				del(actors,self)
			end
			
			foreach(bullets, function(b)
				if collide(self,b) then
					self.hp-=1
					del(actors,b)
						del(bullets,b)
						
					if self.hp<=0 then
						del(actors,self)
						
						sfx(0)

						explode.spark(self.pos.x,self.pos.y)
					end
				end
			end)
		end
		
		obj.draw=function(self)
			--debug(self.ang)
			if self.st>2 then pal(11,8) end
			
			--spr(37,self.pos.x,self.pos.y)
			anim(self, 37, 3, self.fr, self.flip) -- running
			pal()
		end
		
		add(actors,obj)
	end
	
}



-- #gunner
gunner_title_draw=function()
	print("shoot bombs to\ncollect 25 medals\n\n\139 \145 runs\n\148 \131 jumps levels\n\142 shoots\n\151 reloads               \n\n\n\151 to start",10,20,7)
	if btnzp or btnxp then 
		gunner._init()
		cart_update=gunner._update
		cart_draw=gunner._draw
	end
end

--cart_draw=gunner_title_draw

gunner={
	actors={},
	bullets={},
	bombs={},
	layery={24,48,72,96}, --layer y values for actors
	t=0,
	shoot=15,
	rows={
		{y=28,front=-1,last=16},
		{y=31,front=-1,last=16},
		{y=34,front=-1,last=16},
		{y=37,front=-1,last=16}
	}, -- layer map y values for layers
	lastbomb=0,
	_init=function()
		collected=0
		quota=25
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
		
	end,
	_update=function()
		--remember where we started
		--local current_tile=mget(flr(p1.pos.x/8),flr(p1.pos.y/8))
		local startx=p1.pos.x
		
		--p1.dir=0
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
		
		if btnzp and p1.ammo>0 then
			p1.ammo-=1
			gunner.new_bullet()
		end
		
		if btnxp then
			p1.ammo=5
		end
		
		
		if p1.pos.x<=1 then p1.pos.x=1 end
		if p1.pos.x>=120 then p1.pos.x=120 end
		
		
		
		--hit side walls
		local mapoff=24
		local xoffset=0
		if p1.dx>0 then xoffset=5*p1.dir end

		--look for a wall in front of player
		local h=mget((p1.pos.x+xoffset)/8,((p1.pos.y+7)/8)+mapoff)
		if fget(h,0) then p1.pos.x=startx end

		--accumulate gravity
		p1.dy+=g.grav
		p1.pos.y+=p1.dy
		
		--check bottom corners of player. note offset from actual x value
		local botl=mget((p1.pos.x+1)/8,((p1.pos.y+8)/8)+mapoff)
		local botr=mget((p1.pos.x+5)/8,((p1.pos.y+8)/8)+mapoff)

		--assume they are floating until we determine otherwise
		p1.isgrounded=false

		--only check for floors when moving downward
		if not p1.drop and not p1.dive then
			if p1.dy>=0 then
				if fget(botl,0) or fget(botr,0) then
					p1.pos.y = flr((p1.pos.y)/8)*8
					p1.dy = 0
					p1.isgrounded=true
					
					--[[
					local lid=1
					foreach(gunner.layery, function(l)
						if l==p1.pos.y then p1.layer=lid end
						lid+=1
					end)]]
					p1.layer=gunner.get_layer()
				end
			end
		end
		
		if p1.drop then p1.dt+=1 end
		if p1.dt>8 then p1.drop=false end
		if p1.pos.y>90 then p1.dive=false end
		
		if p1.pos.y>127 then gunner.pdie() end

		--debug(p1.layer)
		
		foreach(gunner.actors, function(b)
			b.update(b)
		end)
		
		-- timer to launch another missile, minimum .5s, max 1.5s
		if gunner.t>gunner.shoot then
			gunner.new_bomb()
			gunner.shoot=25
			gunner.t=0
		end
		
		gunner.t+=1
		
		explode.update()
		status._update()
	end,
	_draw=function()
		cam.x=0 cam.y=0
		
		if shake then
			local shaker=1
			if rnd()<.5 then shaker=-1 end
			cam.x+=shaker
			cam.y+=shaker
			
			shake+=1
			if shake>4 then shake=false end
		end
		
		camera(cam.x,cam.y)
		
		palt(0,false)
		--pal(4,1)
		--pal(5,2)

		rectfill(0,0, 127,127, 1) --peach sky
		
		-- warehouse background wall only
		for n=0,15 do
			for m=0,15 do
				map(0,20, 32*n,32*m+8, 4,4)
			end
		end
		
		map(0,24, 0,0, 16,16) --level layers
		
		-- dude
		
		palt(13,true)
		
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
		
		
		-- remove layer slots that have been destroyed (set map tile to empty)
		
		
		palt()
		
		
		for n=1,p1.ammo do
			pset(p1.pos.x-3+2*n, p1.pos.y-3, 10)
		end
		--print(p1.ammo, p1.pos.x+3, p1.pos.y-7, 7)
		
		status._draw(0,0)
		
		foreach(gunner.actors, function(b)
			b.draw(b)
		end)
		
		explode.draw()
		skull.draw()
	end,
	pdie=function() --reset player at top
		--skull.create(p1.pos.x,p1.pos.y)
		
		p1.pos.x=60
		p1.pos.y=10
		p1.ammo=5
		
		collected=flr(collected/2)
		if collected<=0 then collected=0 end
	end,
	remove_ground=function(layer,dir)
		-- l1=28, l2=31, l3=34, l4=37
		-- slots 0-15
		local uselayer=gunner.rows[layer]
		local slot=0
		
		if dir>0 then
			gunner.rows[layer].last-=1
			slot=uselayer.last
		else
			gunner.rows[layer].front+=1
			slot=uselayer.front
		end
		
		local mapy=uselayer.y
		
		mset(slot,mapy,0) --change tile sprite to transparent
		
		if gunner.rows[layer].last > gunner.rows[layer].front then --make sure row has bricks
			shake=1
			explode.spark(slot*8+4, (mapy-25)*8)
			gunner.new_falling(slot*8, (mapy-25)*8)
		end
	end,
	get_layer=function()
		local lid=1
		local layer=1
		foreach(gunner.layery, function(l)
			if l==p1.pos.y then layer=lid end
			lid+=1
		end)
		
		return layer
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
			acc=.25
		}
		
		
		obj.layer=flr(rnd(4))+1
		local getdir=rnd()
		
		obj.pos.y=gunner.layery[obj.layer]
		if getdir>.5 then 
			obj.dir=1
			obj.pos.x=1
			obj.flip=true
		else
			obj.dir=-1
			obj.pos.x=118
		end
		
		
		obj.update=function(self)
			--local ox=self.pos.x
			--self.pos.x=ox
			
			if self.st==1 then
				if self.t>=15 then 
					self.st=2 
					self.t=0 
				else
					self.pos.x+=rnd()*self.dir*-1
				end
			end
			
			if self.st==2 then
				self.acc=min(self.acc+self.acc*2, 2)
				self.pos.x+=self.acc*self.dir
			end
			
			
			
			if ((self.pos.x<=-8 and self.dir<0) or (self.pos.x>=127 and self.dir>0)) and self.st==2 then 
				
				explode.boom(self.pos.x,self.pos.y)
				gunner.remove_ground(self.layer,self.dir)
				
				del(gunner.actors,self)
				del(gunner.bombs,self) 
			end
			
			if collide(self,p1) then
				del(gunner.actors,self)
				del(gunner.bombs,self) 
				
				explode.blood(p1.pos.x,p1.pos.y)
				--explode.blood(p1.pos.x+1,p1.pos.y-1)
				gunner.pdie()
				
			end
			
			foreach(gunner.bullets,function(b)
				if collide(self,b) then
					del(gunner.actors,self)
					del(gunner.bombs,self) 
					del(gunner.bullets,b)
					del(gunner.actors,b) 
					sfx(0)
						
					explode.spark(self.pos.x,self.pos.y)
					gunner.new_medal(self.pos.x,self.pos.y)
				end
			end)
			
			self.t+=1
		end
		
		obj.draw=function(self)
			spr(20,self.pos.x,self.pos.y,1,1,self.flip)
			--circfill(self.pos.x+5*self.dir*-1,self.pos.y+3, 4, 5)
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
	new_medal=function(x,y)
		local obj={
			t=0,
			pos={x=x,y=y},
			hitbox={x=0,y=0,w=8,h=8},
		}
		
		obj.update=function(self)
			if collide(self,p1) then
				collected+=1
				del(gunner.actors,self)
				del(gunner.medals,self) 
				sfx(0)
			end
			
			if self.t>120 then
				del(gunner.actors,self)
				del(gunner.medals,self) 
			end
			self.t+=1
		end
		
		obj.draw=function(self)
			spr(19,self.pos.x,self.pos.y,1,1)
		end
		
		add(gunner.actors, obj)
		add(gunner.medals, obj)
	end
	
	
}

-- #skull
skull={
	all={},
	create=function(x,y)
		local obj={x=x,y=y,t=0}
		add(skull.all, obj)
	end,
	draw=function()
		foreach(skull.all, function(self)
			spr(36,self.x,self.y+3)

			self.t+=1 
			if self.t>90 then del(skull.all,self) end
		end)
	end
	
}

-- #explode
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


-- #runner
runner_title_draw=function()
	print("collect 15 medals                \n\n\n\151 to start",10,20,7)
	if btnzp or btnxp then 
		runner._init()
		cart_update=runner._update
		cart_draw=runner._draw
	end
end
cart_draw=runner_title_draw

runner={
	grav=.4,
	restart=function()
		p1.pos={x=24,y=80}
		--camx=p1.pos.x-zone
		camx=0
		plax=0
		plax2=0
	end,
	_init=function()
		medals={}
		p1={
			pos={x=0,y=0},
			hitbox={x=0,y=0,w=5,h=8},
			dx=0,
			dy=0,
			isgrounded=false,
			jumpvel=3.8,
			camx=0,
			idle=true,
			flip=false,
			speed=2,
			dir=1
		}
		
		zone=30
		
		runner.restart()
		
		-- get positions of medals from the map
		for n=0,127 do
			local col=n

			for m=0,15 do
				local row=m
				
				-- medal
				if fget(mget(col,row),1) then
					add(medals,{pos={x=col*8,y=row*8},hitbox={x=0,y=0,w=8,h=8},visible=true})
				end
			end
		end
	end,
	_update=function()

		--remember where we started
		local current_tile=mget(flr(p1.pos.x/8),flr(p1.pos.y/8))
		local startx=p1.pos.x
		
		p1.dir=0
		p1.dx=0
		p1.idle=true
		camfront=camx+zone
		
		
		-- it's a door, warp back
		if fget(current_tile,2) then
			runner.restart()
		end

		-- player can jump if on the ground
		if btnzp and p1.isgrounded then
			p1.dy=-p1.jumpvel
		end
		
		if btnl then --left
			p1.idle=false
			p1.flip=true
			p1.dir=-1
		end
		
		if btnr then --right
			p1.idle=false
			p1.flip=false
			p1.dir=1
			
			if p1.pos.x>=camfront and p1.pos.x<926 then
				plax+=.10
				plax2+=.4
			end
		end
		
		p1.dx=p1.speed*p1.dir
		p1.pos.x+=p1.dx
		
		-- stop camera motion when in the last 128 screen
		if p1.pos.x<926 then
			if p1.pos.x<=camx then p1.pos.x=camx end
			if p1.pos.x>=camfront then camx=p1.pos.x-zone end
		end
		
		
		
		--hit side walls
		local xoffset=0
		if p1.dx>0 then xoffset=5*p1.dir end

		--look for a wall in front of player
		local h=mget((p1.pos.x+xoffset)/8,(p1.pos.y+7)/8)
		if fget(h,0) then p1.pos.x=startx end

		--accumulate gravity
		p1.dy+=runner.grav
		p1.pos.y+=p1.dy
		
		--check bottom corners of player. note offset from actual x value
		local botl=mget((p1.pos.x+1)/8,(p1.pos.y+8)/8)
		local botr=mget((p1.pos.x+5)/8,(p1.pos.y+8)/8)

		--assume they are floating until we determine otherwise
		p1.isgrounded=false

		--only check for floors when moving downward
		if p1.dy>=0 then
			if fget(botl,0) or fget(botr,0) then
				p1.pos.y = flr((p1.pos.y)/8)*8
				p1.dy = 0
				p1.isgrounded=true
				
				if fget(botr,3) or fget(botl,3) then
					p1.speed=.5 --normal speed
				else
					p1.speed=2 --slower in water
				end
			end
		end

		--hit ceiling
		v=mget((p1.pos.x+4)/8,(p1.pos.y)/8)
		if p1.dy<=0 then
			if fget(v,0) then
				p1.pos.y = flr((p1.pos.y+8)/8)*8
				p1.dy = 0
			end
		end		
		
		if p1.pos.y>127 then runner._init() end -- reset if you fall in pit
		
		-- collision with medals
		foreach(medals, function(m)
			if collide(p1, m) then
				m.visible=false
			end
		end)
		
		
		status._update()
		
	end,
	_draw=function()
		camera(camx, 0)
		
		-- background and level
		rectfill(camx,0, camx+127,127, 15) --peach sky
		rectfill(camx,90, camx+127,127, 2) --red bottom
		map(0,16, camx-flr(plax),58, 24,4) --trees
		
		palt(0,false)
		map(24,16, camx-flr(plax2),90, 40,2) --trees2
		rectfill(camx,106, camx+127,127,1) --blue
		palt()
		rectfill(camx,120, camx+127,127,0) --black
		
		palt(13,true) --transparent for medal markers
		map(0,0, 0,0, 128,16) --level
		palt()
		
		
		-- medals
		foreach(medals, function(m)
			if m.visible then
				spr(19,m.pos.x,m.pos.y)
			end
		end)
		
		
		
		-- dude
		palt(0,false)
		palt(13,true)
		if not p1.idle then 
			if p1.isgrounded then
				anim(p1, 1, 8, 15, p1.flip) -- running
			else
				spr(6,p1.pos.x,p1.pos.y,1,1,p1.flip) --jumping
			end
		else
			spr(1,p1.pos.x,p1.pos.y,1,1,p1.flip) --standing
		end
		palt()
		
		--line(p1.pos.x+2,p1.pos.y, p1.pos.x+2, p1.pos.y+10, 10)
		--debug_hitbox(p1)
		
		status._draw(camx,0)
		
	end
	
}





-----------------
-- time_to_text
-----------------
function time_to_text( time )
	local mins=0
	local secs=flr(time/30) --seconds
	local micro=time%30
	
	while secs>=60 do
		mins+=1
		secs-=60
	end
	
	if micro<10 then micro="0"..micro end
	if mins<10 then mins="0"..mins end
	if secs<=0 then
		secs="00" 
	elseif secs<10 then 
		secs="0"..secs
	end
	
	

	return mins..":"..secs..":"..micro
end


-- #clock
clock={
	running=false,
	_init=function()
		game_time=0
	end,
	_update=function()
		if clock.running then game_time+=1 end
	end,
	_draw=function()
		
	end
}


-- #status
status={
	_init=function()
		clock._init()
		clock.running=true
	end,
	_update=function()
		clock._update()
	end,
	_draw=function(x,y)
		rectfill(x,0,x+127,11,0)
		print(time_to_text(game_time),x+94,y+3,6)
		line(x,y+11,x+127,y+11,6)
		print("event 1/1",x+3,y+3,6)
		--print(time_to_text(30000),x+51,y+3,9)
		spr(19, x+51,y+2)
		print(collected.."/"..quota,x+61,y+3,9)
	end
	
}




-- #loop
function _init()
	mouse.init()
	status._init()
	
	pepsi._init()
end


function _update()
	btnl=btn(0)
	btnr=btn(1)
	btnlp=btn(0)
	btnrp=btn(1)
	btnu=btn(2)
	btnd=btn(3)
	btnup=btnp(2)
	btndp=btnp(3)
	btnz=btn(4)
	btnx=btn(5)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	mx,my = mouse.pos()
	mb = mouse.button()
	
	cart_update()
end

function _draw()
	cls()

	cart_draw()
	
	debug_out()
end


--print(#medals, camx+80,80,10)
--#util
debugtext=""
function debug(str) debugtext=str end
function debug_line(str) debugtext=debugtext.."\n"..str end
function debug_out() print(debugtext, 10,30, 1) print(debugtext, 10,29, 11) debugtext="" end
function debug_hitbox(obj,c) 
	local color=c or 11
	rect(obj.pos.x+obj.hitbox.x,obj.pos.y+obj.hitbox.y, obj.pos.x+obj.hitbox.x+obj.hitbox.w,obj.pos.y+obj.hitbox.y+obj.hitbox.h, color)
end

function random_pick(t)
	local r=flr(rnd(#t))+1
	return(t[r])
end

mouse = {
  init = function()
    poke(0x5f2d, 1)
  end,
  -- return int:x, int:y, onscreen:bool
  pos = function()
    local x,y = stat(32)-1,stat(33)-1
    return stat(32)-1,stat(33)-1
  end,
  -- return int:button [0..4]
  -- 0 .. no button
  -- 1 .. left
  -- 2 .. right
  -- 4 .. middle
  button = function()
    return stat(34)
  end,
}



function draw_line(x,y,dist,dir,color)
	fx = cos(dir)*dist+x
	fy = sin(dir)*dist+y

	line(x,y,fx,fy,color)
	
	return fx,fy
end

function on_circle(objpos, circ)
	local check=(objpos.pos.x-circ.x)^2 + (objpos.pos.y-circ.y)^2
	if check<circ.rad^2 then
		return true
	else
		return false
	end					
					
end

function pt_on_circle(angle,cx,cy,rad)
	local dx=cos(angle)*rad+cx
	local dy=sin(angle)*rad+cy
	
	return dx,dy
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
			

function get_line(x,y,dist,dir)
	fx = flr(cos(dir)*dist+x)
	fy = flr(sin(dir)*dist+y)
	
	return fx,fy
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

-- round number to the nearest whole
function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end			

__gfx__
00000000ddddddddd9999dddd9999ddd89999dddddddddddd9999dddd9999ddd89999ddddddddddd000000000000000000000000000000000000000000000000
00000000d9999dddd8888ddd88888dddd8888dddd9999dddd8888ddd88888dddd8888ddddddddddd000000000000000000000000000000000000000000000000
00000000d8888ddd891f1dddd91f1dddd91f1ddd88888ddd891f1dddd91f1dddd91f1ddddddddddd000000000000000000000000000000000000000000000000
00000000891f1dddd9fffdddd900fdddd9fffdddd91f1dddd9fffdddd9ff00ddd9fffddddd5555dd000000000000000000000000000000000000000000000000
00000000d9fffdddd3333dddd3003dddd3333dddd9fffdddd3333ddd033300ddd3333ddddd544ddd000000000000000000000000000000000000000000000000
00000000d3333dddd00bbdddddddddddd00bbdddd3333dddd3300dddddddddddd3300ddddddddddd000000000000000000000000000000000000000000000000
00000000d33bbdddddd0ddddddddddddddd0ddddd33bbddd0ddddddddddddddd0ddddddddddddddd000000000000000000000000000000000000000000000000
00000000d0dd0dddddddddddddddddddddddddddd0dd0ddddddddddddddddddddddddddddddddddd000000000000000000000000000000000000000000000000
b3bb3bbb004444007a0000000c7cc7c0000000000aaa00000000000000000000000bbb0000000000000000000000000000000000000000000000000000000000
3333333304999950abbb00000c7cc7c000000000aaaaa000000000000000000000bbbbb000000000000000000000000000000000000000000000000000000000
54545454499944956bbbb0000c7cc7c0077777070999000000000000000000000b3bbb3b00000000000000000000000000000000000000000000000000000000
44444444449945956bbbb30000611600877777770000000000000000000000003303b30330000000000000000000000000000000000000000000000000000000
44444444494999956bbb3333000aa000866666660000000000000000000000003000300030000000000000000000000000000000000000000000000000000000
45444454499599956003333000aa9900066666060000000000000000000000005000500050000000000000000000000000000000000000000000000000000000
44444544049999506000000000a99900000000000000000000000000000000000600500600000000000000000000000000000000000000000000000000000000
44544444005555006000000000099000000000000000000000000000000000000600600600000000000000000000000000000000000000000000000000000000
22224222111111116004444000000000067770007707700007070000007000000060606000000000000000000000000000000000000000000000000000000000
24222242111111116041111400000000088880000060000000600000006000000006660000000000000000000000000000000000000000000000000000000000
222222224141414160411114cccccccc861610000060888000608880006088800944444900000000000000000000000000000000000000000000000000000000
221221222414242460411114cccccccc0677700000681f1000681f1000681f100494449400000000000000000000000000000000000000000000000000000000
212222125152525260411114cccccccc006700000558fff00558fff00558fff0044aaa4400000000000000000000000000000000000000000000000000000000
1222122212221222604111141c1c1c1c000000000552222005522220055222200444a44400000000000000000000000000000000000000000000000000000000
212121212121212160415514c1c1c1c1000000000052288000522880005228800494449400000000000000000000000000000000000000000000000000000000
1111111111111111604555541c1c1c1c000000000002002000020020000200200944444900000000000000000000000000000000000000000000000000000000
44444444dddddddd6666666688888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544454dddddddd5556655522288222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44454444dddddddd0060560000802800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444445dddddddd0600056008000280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45444454dddddddd6000005680000028000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44445444dddddddd6666666688888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444dddddddd5555555522222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44544444dddddddd0000000011111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ffffffffffffffffffffffffffffffff222222222222222222222222611111011111011111011111011111161111111111111117111111111111111100000000
ffffffffffffffffffffffffffffffff222222222222222222222222561111011111011111011111011111661111111111111777111111111111111100000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee222222222222222222222222056111011111011111011111011116161111111111177066771111111111111100000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa222222222222222122222222015611011111011111011111011165161111111111706667667711111111111100000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa222222222222221122222222011561011111011111011111011651161111111177667706776077111111111100000000
fffff2ffffffffffffffffffffffffff222222222222222112222222000056000000000000000000006500061111117776076707607660711111111100000000
eeeee2eeeeeeeeeeeeeeeeeeeeeeeeee222212222222211112222222011115611111011111011111065111061111177660767060766776777111111100000000
aaaaa2aaaaaaaaaaaaaaaaaaaaaaaaaa222112222122221111222122011111061111011111011111651111061117766006600600700607667771111100000000
aaaa222aaaaaaaaaaaaaaaaaaaaaaaaa222111222122211112222122011111056111011111011116511111061776600060000000000060776677711100000000
eeeee22eeeeeeeeeeeeeeeeeeeeeeeee221111121111221111221122011111015611011111011165011111067060000600006000000006007067077100000000
aaaa222aaaaaaaaaaaaaaaaaaaaaaaaa222111221112111111122112011111011561011111011651011111060000000000070000007000000006600700000000
eeeee222eeeeeeeeeeeee2eeeeeeeeee221111112111221111221122011111011156011111016511011111060070067000000000007000700000060000000000
aaaa222aaaaaaaaaaaaaa2aaaaaaaaaa211111211111211111121111011111011115611111065111011111060700600000000000000700066000000000000000
99922222299999299999229999999999121111121112111111111111011111011111561111651111011111060000000000000000000000000760000000000000
99992222999999299999922999999999111111111111111111111111011111011111056116511111011111060000000000000000000000000000000000000000
99922229299999299999222999929999111111111111111111111111011111011111015665011111011111060000000000000000000000000000000000000000
aa2a22222aaaa222aaaaa2aaaaa2aaaa111111110000000000000000011111011111011661011111011111060000000000000000000000000000000000000000
99922222929999229999222999929999111111110000000000000000011111011111016556011111011111060000000000000000000000000000007000000000
aaa222222aaaa2222aa2222aaa222aaa010101010000000000000000011111011111065115611111011111060000077000000070000001000000c0c000000000
9922222229999922299922229992299910101010000000000000000001111101111165111106111101111106007700000008090000c710000000000000000000
92229222229992229992222229222299010101010000000000000000011111011116011111056111011111060000000077000000000000008080070000000000
99922222299922222299222999922299101010100000000000000000011111011165011111015611011111060ca009000000000090990000000000c000000000
99292222929992222992222229222999000000000000000000000000011111011651011111011561011111060000000000000000007770000888080000000000
922222222299222292999222922222290000000000000000000000000111110165110111110111560111110600000099009000000000000a0000000000000000
29222222292292222292222222222292000000000000000000000000011111065111011111011115611111060000000000000000000000000000000000000000
22222222222222222229222222222222000000000000000000000000011111651111011111011111061111060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000011116011111011111011111056111060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000011165011111011111011111015611060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000011651011111011111011111011561060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000016511011111011111011111011156060000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000065111011111011111011111011115660000000000000000000000000000000000000000
22222222222222222222222222222222000000000000000000000000651111011111011111011111011111560000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000033330000333300000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b4c4d4e4b4c4d4e4b4c4d4e4b4c4d4e40000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b5c5d5e5b5c5d5e5b5c5d5e5b5c5d5e50000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000b6c6d6e600000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000b6c6d6e6000000000000b6c6d6e600000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000001010002000000000000000000000000010904000000000000000000000000000102010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000003100000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000310000000000000031000000000000000000000000111100000000000000000000000000000000000000003232000000000000000000000000000000000000000000000000000000000031000000000000000000000011000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000111100111111000011000000000000000000000000000000000000000000000000000000310000000000000000000000000000000000000000000000000000000000003232323200000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000001000000000000000323232323232323232320000000000000000000031003232000000000000000000000000000000000000000000000000000000000000000032000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000010003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000320000000000000000323232000000000000003200000000000000000000000000
1100000000000000310000000000001100000000000000110000000000100030003000000000000000000000000000000000000000000000100010100000000000003232000000000000000000301100000000000000000000000000003200000000000000000000000000000031000000000000000000100000003100000011
1100120000000000110000000000111131000000003232320000003100300030003000000000000000000000000000000000000000000010300030300000003232000000000000000031000000301010000000000000000000000032000000000000000000000000000000001010000000320000000000300000000000120011
1100220000000011110000000011111132323200000000000000001000300030003000000000110000000000000000000000003100001030300000310000000000000000000000000000000000000031000000000000001111110000000000000000000000000000000010003030000000003100000000300000000000220011
1010101010101010101010101010101023232323232323232323103023300030003000000000101010100000000010000000101023233030302323232310101010101000000000000010232310101010101023232310101010102323231000000000000000001010102330233030000000001000000000300000101010101010
2020202020202020202020202020202021212121212121212121202021206420642064000000202020206464646420646464202021212020202121212120202020202000000000000020212120202020202021212120202020202121212064646464646464642020202120212020646464642064646464206464202020202020
4041424340414240414243434041404140414243404100004445464444454646444546444546444546444546444546464445464444454646444445464445464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051525350515250515253535051505150515253505100005455565454555656545556545556545556545556545556565455565454555656545455565455565600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626360616260616263636061606160616263606100006464646464646464646464646464646464646464646464646464646464646464646464646464646400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727370717270717273737071707170717273707100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4748494a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5758595a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

