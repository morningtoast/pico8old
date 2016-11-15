pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


--
-- #globals
--
t=0
screen={x=0,y=0,w=128,h=128}
char={btnz="\142",btnx="\151"}
rail={pos={x=64,y=64},w=65,rad=56}
drain={pos={x=64,y=64},hitbox={x=-2,y=-2,w=4,h=4}}

test={pos={x=70,y=70},hitbox={x=0,y=0,w=8,h=8}}

--
-- #cart container
-- used in system loops
--
cart={update=function() end,draw=function() end}




--
-- #ghosts
--
ghosts={
	all={},
	create=function(x,y,ang)
		if p.ghostmax>0 then
			local obj={
				pos={x=x,y=y},
				t=0,
				shape=p.pos.shape,
				ang=ang
			}

			if #ghosts.all>=p.ghostmax then
				del(ghosts.all,ghosts.all[1])
			end	
			add(ghosts.all, obj)
		end
	end,
	_update=function()
		foreach(ghosts.all, function(g)
			if g.t>=8 then
				bullets.create(g.pos.x,g.pos.y, g.ang, 2)
				g.t=0
			end
				
			g.t+=1
		end)
		
		
	end,
	_draw=function()
		foreach(ghosts.all, function(g)
			--line(g.pos.x,g.pos.y, p.pos.x,p.pos.y, 14) --warp line

			line(g.shape[1].x,g.shape[1].y, g.shape[2].x,g.shape[2].y, 2)
			line(g.shape[2].x,g.shape[2].y, g.shape[3].x,g.shape[3].y, 2)
			line(g.shape[3].x,g.shape[3].y, g.shape[1].x,g.shape[1].y, 2)
		end)
		
	end
}


--
-- #warp
--
warp={
	all={},
	create=function(x,y,dir)
		for n=1,3 do
			local obj={x=x,y=y,d=dir,t=0}

			obj.d+=rnd(.01)
			obj.dx,obj.dy=dir_calc(obj.d, 8)
			obj.len=random(12,48)

			add(warp.all,obj)
		end
		
		for n=1,8 do
			local obj={x=x,y=y,d=dir,t=0}

			obj.d+=rnd(1)
			obj.dx,obj.dy=dir_calc(obj.d, 4)
			obj.len=1

			add(warp.all,obj)
		end
	end,
	_draw=function()
		foreach(warp.all, function(w)
			--circfill(w.x,w.y,1,8)
			--pset(w.x,w.y,10)
			
			draw_line(w.x,w.y, w.len, w.d, 10)
				
				w.x+=w.dx
				w.y+=w.dy
			w.t+=1
			if w.t>=8 then del(warp.all,w) end
		end)
	end
}

--
-- #player
--
p={
	_init=function()
		p.pos={x=0,y=0,dir=0,shape={}}
		p.hitbox={x=0,y=0,w=8,h=8}
		p.lives=3
		p.score=shr(0,16)
		p.st=1
		p.t={p=0,z=0,x=0}
		p.dx=0
		p.dy=0
		p.ang=.75
		p.dir=1
		p.speed=.006
		p.ghostmax=0
		p.power={current=50,max=100}
		p.circ={}
		p.canbehit=true
		
		
		p1={}
		p2={}
		p3={}
		--[[
		p.limit=(1/p.speed)
		
		for n=0,p.limit do
			
			p.da+=p.speed
		
			--debug(p.da)
			local dx = cos(p.da)*rail.rad+64;
			local dy = sin(p.da)*rail.rad+64;
			
			local newangle = atan2(64-dx, 64-dy)
			p1.x,p1.y=get_line(dx,dy,7,newangle-.437)
			p2.x,p2.y=get_line(dx,dy,7,newangle-.562)
			--line(p1.x,p1.y, p2.x,p2.y, 10)
			
			local shape={
				{x=dx,y=dy},
				{x=p1.x,y=p1.y},
				{x=p2.x,y=p2.y},
				{x=dx,y=dy}
			}
			
			add(p.circ,{x=dx,y=dy,dir=p.da,shape=shape})
			
		end]]
		
		--p.pos=p.circ[1]
		
	end,
	_update=function()
		if p.st==1 then --normal
			p.color=10
			p.move()
			p.action()
		end
		
		if p.st==2 then --got hit, waiting before reappear
			if p.t.p>=60 then
				p.chstate(3)
			end
		end
		
		if p.st==3 then --ghost state
			p.color=6
			p.move()
			p.action()
		end
		
		
		
		
		
		p.t.p+=1
	end,
	_draw=function()
		if p.st==1 or p.st==3 then
			line(p.pos.shape[1].x,p.pos.shape[1].y, p.pos.shape[2].x,p.pos.shape[2].y, p.color)
			line(p.pos.shape[2].x,p.pos.shape[2].y, p.pos.shape[3].x,p.pos.shape[3].y, p.color)
			line(p.pos.shape[3].x,p.pos.shape[3].y, p.pos.shape[1].x,p.pos.shape[1].y, p.color)
		end
		
		phit._draw()
	end,
	get_shape=function()
		
	end,
	chstate=function(s)
		p.st=s
		p.t.p=0
		
		if p.st==1 then p.canbehit=true end
	end,
	move=function()
		
		
		p.dir=0
		
		if btnl then --left
			p.dir=1
			if p.st==3 then p.chstate(1) end 
		end 
		if btnr then --right
			p.dir=-1
			if p.st==3 then p.chstate(1) end 
		end 

		
		p.ang+=p.speed*p.dir
		
		p.pos.x = cos(p.ang)*rail.rad+64;
		p.pos.y = sin(p.ang)*rail.rad+64;

		local newangle = atan2(64-p.pos.x, 64-p.pos.y)
		
		p1.x,p1.y=get_line(p.pos.x,p.pos.y,7,newangle-.437)
		p2.x,p2.y=get_line(p.pos.x,p.pos.y,7,newangle-.562)

		p.pos.shape={
			{x=p.pos.x,y=p.pos.y},
			{x=p1.x,y=p1.y},
			{x=p2.x,y=p2.y},
			{x=p.pos.x,y=p.pos.y},
		}
	end,

	action=function()
		
		
		if btnxp then -- x button
			if p.st==3 then p.chstate(1) end
			
			ghosts.create(p.pos.x,p.pos.y,p.ang)
			warp.create(p.pos.x,p.pos.y,p.ang+.5)
			
			p.ang=abs(p.ang+.5)
		end
		
		
		if btnz then -- z button
			if p.st==3 then p.chstate(1) end
			
			if p.t.z>=7 then
				bullets.create(p.pos.x,p.pos.y,p.ang)
				p.t.z=0
			end
		else
			p.t.z=7
		end
		
		p.t.z+=1
	end,
	
	collision=function()
		
	end,
	
	hit=function()
		p.chstate(2)
		p.canbehit=false
		phit.create(p.pos.x,p.pos.y)
		p.lives-=1
		p.ang=.75
		
	end
}



phit={
	all={},
	create=function(x,y)
		for n=0,36 do
			local obj={
				pos={x=x,y=y},
				color=10,
				ang=rnd(),
				size=rnd()
			}
			
			if obj.size>.5 then obj.size=1 else obj.size=0 end
			obj.dx,obj.dy=dir_calc(obj.ang, flr(rnd(5))+2)

			add(phit.all,obj)
		end
	end,
	_draw=function()
		foreach(phit.all,function(o)
			circfill(o.pos.x,o.pos.y, o.size, 10)
			o.pos.x+=o.dx
			o.pos.y+=o.dy
				
			if offscreen(o.pos.x,o.pos.y) then del(phit.all, o) end
		end)
	end
	
}



--
-- #meter
--
meter={t=0,
	_update=function()
		if #ghosts.all>0 and meter.t>3 then
			meter.decrease()
			meter.t=0
		end
		
		if p.power.current<=0 then ghosts.all={} end
		meter.t+=1
	end,
	_draw=function()
		local p=1-((p.power.current/p.power.max))
		local w=flr(127*p)
		
		rectfill(127,127,127,w, 7)
	end,
	gain=function()
		p.power.current+=1
		if p.power.current>p.power.max then p.power.current=p.power.max end
	end,
	decrease=function()
		if p.power.current>0 then p.power.current-=1 end
	end
}

--
-- #bullets
--
bullets={
	all={},
	create=function(x,y,ang,c)
		c=c or 7
		local obj={
			pos={x=x,y=y},
			hitbox={x=-1,y=-1,w=2,h=2},
			color=c,
			ang=ang
		}
		--local newangle = atan2(64-obj.pos.x, 64-obj.pos.y)
		--local newangle =p.pos.dir
		obj.dx,obj.dy=dir_calc(obj.ang+.5, 3)
		obj.dir=newangle
		add(bullets.all, obj)
	end,
	_update=function()
		
		
		foreach(bullets.all, function(b)
			b.pos.x+=b.dx
			b.pos.y+=b.dy
			
				
			if collide(b,drain) then bullets.remove(b) end
		end)
	end,
	_draw=function()
		foreach(bullets.all, function(b)
			circ(b.pos.x,b.pos.y,1,b.color)
		end)
		
		--debug_hitbox(drain)
		
	end,
	remove=function(obj) del(bullets.all,obj) end
}





--
-- #enemy
--

function square(x,y,mult)
	local mult=mult or -1
	
	local obj={
		pos={x=x,y=y},
		color=8,
		dist=1,
		dir=0, --
		rot=0, --initial rotation
		len=0, --initial size
		lenmax=0,
		t=0,
		hp=2,
		grow=0,
		dx=0,
		dy=0,
		mult=mult,
		hitbox=6,
		st=1,
		update=function() end,
		draw=function() end,
		kill=function() end,
	}
	
	obj.dist=distance(obj.pos.x,obj.pos.y, rail.pos.x,rail.pos.y)
	
	if obj.dist<=10 then
		obj.lenmax=1
	elseif obj.dist<=20 then
		obj.lenmax=3
	elseif obj.dist<=30 then
		obj.lenmax=4
	else
		obj.lenmax=5
	end
	
	obj.get_shape=function(self)
		s1x,s1y=get_line(self.pos.x,self.pos.y, self.len, self.rot)
		s2x,s2y=get_line(self.pos.x,self.pos.y, self.len, self.rot+.25)
		s3x,s3y=get_line(self.pos.x,self.pos.y, self.len, self.rot+.5)
		s4x,s4y=get_line(self.pos.x,self.pos.y, self.len, self.rot+.75)
		
		local shape={
			{x=s1x,y=s1y},
			{x=s2x,y=s2y},
			{x=s3x,y=s3y},
			{x=s4x,y=s4y}
		}
		
		return shape
	end
	
	obj.shape=obj.get_shape(obj)
	
	obj.draw=function(e)
		line(e.shape[1].x,e.shape[1].y, e.shape[2].x,e.shape[2].y, e.color)	
		line(e.shape[2].x,e.shape[2].y, e.shape[3].x,e.shape[3].y, e.color)	
		line(e.shape[3].x,e.shape[3].y, e.shape[4].x,e.shape[4].y, e.color)	
		line(e.shape[4].x,e.shape[4].y, e.shape[1].x,e.shape[1].y, e.color)			
	end
	
	obj.kill=function()
		gems.create(obj.pos.x,obj.pos.y, obj.dir)
	end
	
	
	obj.update=function(e)
		if e.st==1 then
			if e.grow>2 and e.len<e.lenmax then 
				e.len+=1 
				e.grow=0
			end
			e.grow+=1

			e.rot+=.0125 --makes it spin

			if e.t>90 then 
				--e.color=10 
				e.rot+=.0325 --increase rotation speed
				e.dir+=.0075 --move around center point speed .0035

				if e.dist<=10 then
					e.len=1
				elseif e.dist<=20 then
					e.len=3
				elseif e.dist<=30 then
					e.len=4
				else
					e.len=5
				end

				--e.hitbox=e.len+1

				if flr(e.dist)<=1 then
					enemy.attack(e)
					e.color=9
					e.hp=99
					e.st=2 
				else
					if flr(abs(e.dist))<=0 then e.mult=1 end
					--if flr(abs(e.dist))>55 then e.mult=-1 end

					e.dist+=.15*e.mult --change distance from center (spiral) .0625

					e.pos.x,e.pos.y=pt_on_circle(e.dir,flr(e.dist))
					e.pos.x+=rail.pos.x
					e.pos.y+=rail.pos.y
				end


			end


			 --square
		end

		if e.st==2 then
			e.pos.x+=e.dx
			e.pos.y+=e.dy

			e.dist=distance(e.pos.x,e.pos.y, rail.pos.x,rail.pos.y)

			if e.dist<=10 then
				e.len=1
			elseif e.dist<=20 then
				e.len=3
			elseif e.dist<=30 then
				e.len=4
			else
				e.len=6
			end 
		end

		e.hitbox=e.len+1
		e.shape=enemy.get_points(e)

		if offscreen(e.pos.x,e.pos.y) then enemy.remove(e) end
		
	end
	
	
	return obj
end

function circle()
	local obj={
		pos={x=0,y=0},
		color=11,
		dist=0,
		ang=1, --
		len=0, --initial size
		t=0,
		hp=5,
		grow=0,
		dx=0,
		dy=0,
		dir=1,
		hitbox=1,
		speed=.0085,
		st=1,
		update=function() end,
		draw=function() end,
		kill=function() end,
		pause=random(4,8)*30
	}
	
	obj.chstate=function(st)
		obj.lastst=obj.st
		obj.st=st
		obj.t=0
	end
	
	obj.kill=function()
		gems.create(obj.pos.x,obj.pos.y, obj.dir)
		enemy.create.circle(rnd(),0)
	end
	
	obj.draw=function(e)
		local cx,cy=get_line(e.pos.x,e.pos.y, e.len, e.ang)
		
		circ(e.pos.x,e.pos.y, e.len, e.color)
		line(e.pos.x,e.pos.y, cx,cy, e.color)
	end
	
	obj.update=function(e)
		debug(abs(flr(e.dist))..":"..e.t.."/"..e.pause.." "..e.st)
		local dist=abs(flr(e.dist))
		
		
		if dist<=10 then
			e.speed=.0085
			e.len=1
		elseif dist<=20 then
			e.speed=.0065
			e.len=2
		elseif dist<=30 then
			e.speed=.0045
			e.len=3
		else
			e.speed=.0045
			e.len=4
		end
		
		
		if e.t>=e.pause then
			e.chstate(2)
		end
		
		if dist>40 then
			e.chstate(3)
		end
		
		
		-- spiral out
		if e.st==1 then e.dir=1 end
		if e.st==4 then e.dir=-1 end
		
		-- patrol
		if e.st==3 then
			e.dir=0
			e.dist=40
		end
		
		-- pause and shoot
		if e.st==2 then
			e.speed=0
			e.dir=0
			
			if e.t==30 then
				shots.create(e.pos.x,e.pos.y,e.ang)
			end
			
			if e.t>=60 then
				e.chstate(e.lastst)
			end
		end
		
		e.ang+=e.speed --move around center point speed .0035
		e.hitbox=e.len+1
		e.dist+=.0825*e.dir --change distance from center (spiral) .0625

		e.pos.x,e.pos.y=pt_on_circle(e.ang,flr(e.dist))
		e.pos.x+=rail.pos.x
		e.pos.y+=rail.pos.y
		

		
		e.t+=1
	end
	
	
	return obj
end


enemy={
	all={},
	create={
		threesome=function(dir, ring)
			enemy.add_square(dir,ring)	
			enemy.add_square(dir-.06,ring)	
			enemy.add_square(dir+.06,ring)	
		end,
		square=function(dir,dist,mult)
			local mult=mult or -1
			local ex,ey=pt_on_circle(dir,dist)
			local obj=square(ex+rail.pos.x,ey+rail.pos.y, mult)
			obj.dir=dir
			obj.dist=dist
			add(enemy.all,obj)
		end,

		circle=function(dir,dist)
			local obj=circle()
			local ex,ey=pt_on_circle(dir,dist)
			obj.dir=dir
			obj.dist=dist
			add(enemy.all,obj)
		end,
	},
	insert=function(dir,dist)
		local ex,ey=pt_on_circle(dir,dist)
		add(enemy.all,enemy.clone(ex+rail.pos.x,ey+rail.pos.y, dir, dist))
	end,
	
	clone=function(x,y,dir,dist, func)
		local dir=dir or 0
		--local color=color or 8
		
		local obj=square()
		
		obj.pos={x=x,y=y}
		obj.dir=dir
		obj.dist=0
		--obj.color=color
		
		--if rnd()<.5 then obj.mo=-1 else obj.mo=1 end
		
		return obj
	end,
	get_points=function(obj)
		--s1x,s1y=get_line(obj.pos.x,obj.pos.y,obj.len,obj.dir)
		--s2x,s2y=get_line(s1x,s1y,obj.len,obj.dir+.25)
		--s3x,s3y=get_line(s2x,s2y,obj.len,obj.dir+.5)
		--s4x,s4y=get_line(s3x,s3y,obj.len,obj.dir+.75)
		
		s1x,s1y=get_line(obj.pos.x,obj.pos.y,obj.len,obj.rot)
		s2x,s2y=get_line(obj.pos.x,obj.pos.y,obj.len,obj.rot+.25)
		s3x,s3y=get_line(obj.pos.x,obj.pos.y,obj.len,obj.rot+.5)
		s4x,s4y=get_line(obj.pos.x,obj.pos.y,obj.len,obj.rot+.75)
		
		local shape={
			{x=s1x,y=s1y},
			{x=s2x,y=s2y},
			{x=s3x,y=s3y},
			{x=s4x,y=s4y}
		}
		
		return shape
	end,
	_update=function()
		foreach(enemy.all, function(e)
			e.update(e)
				
				
			-- bullet collision
			foreach(bullets.all, function(b)
				if in_circle(b.pos.x,b.pos.y, e.pos.x,e.pos.y, e.hitbox) then
					e.hp-=1
					if e.hp<=0 then
						e.kill()
						enemy.remove(e)
					end
							
					bullets.remove(b)
				end
			end)
				
			-- collision with player
			if p.canbehit then
				if in_circle(p.pos.x,p.pos.y, e.pos.x,e.pos.y, e.hitbox) then
					p.hit(p.pos.x,p.pos.y)	
				end
			end
			--[[
			if #ghosts.all>0 then
				if intersect(ghosts.all[1].pos,p.pos, e.shape[1],e.shape[2]) then
					enemy.remove(e)
				end
			end
			]]
			
				if offscreen(e.pos.x,e.pos.y) then enemy.remove(e) end
				
			e.t+=1
		end)
		
	end,
	_draw=function()
		
		foreach(enemy.all, function(e)
			e.draw(e)
		end)
	end,
	remove=function(o)
		del(enemy.all,o)
	end,
	add=function(o)
		add(enemy.all,o)
	end,
	attack=function(e)
		local newangle = atan2(p.pos.x-e.pos.x, p.pos.y-e.pos.y)
		
		e.dx,e.dy=dir_calc(newangle+rnd(.03), 2)
	end
}


--
-- #shots
--
shots={
	all={},
	create=function(x,y,ang)
		c=c or 7
		local obj={
			pos={x=x,y=y},
			hitbox={x=-1,y=-1,w=2,h=2},
			color=14,
			ang=ang,
			dist=0,
			size=1
		}

		obj.dx,obj.dy=dir_calc(obj.ang, 1)
		obj.dir=newangle
		add(shots.all, obj)
	end,
	_update=function()
		
		
		foreach(shots.all, function(b)
			b.pos.x+=b.dx
			b.pos.y+=b.dy
				
			b.dist=flr(abs(distance(b.pos.x,b.pos.y, rail.pos.x,rail.pos.y)))
				
			if b.dist>25 then b.size=2 end
				
			if offscreen(b.pos.x,b.pos.y) then shots.remove(b) end
		end)
	end,
	_draw=function()
		foreach(shots.all, function(b)
			circfill(b.pos.x,b.pos.y,b.size,b.color)
		end)
		
		--debug_hitbox(drain)
		
	end,
	remove=function(obj) del(shots.all,obj) end
}




--
-- #gems
--
gems={
	all={},
	create=function(x,y,dir)
		for n=0,8 do
		local obj={
			pos={x=x,y=y},
			hitbox={x=-1,y=-1,w=2,h=2},
			dir=dir,
			c=14,
			t=0
		}
		
		obj.dir+=rnd(1)
		obj.dx,obj.dy=dir_calc(obj.dir, 4)
		
		add(gems.all, obj)
		end
	end,
	_update=function()
		foreach(gems.all, function(g)
				
			-- check to see if gem point is at radius of rail
			local check=(g.pos.x-rail.pos.x)^2 + (g.pos.y-rail.pos.y)^2
			if check<rail.rad^2 then
				g.pos.x+=g.dx
				g.pos.y+=g.dy
			end
				
			--pt={x=g.pos.x,y=g.pos.y}
				
			--alpha = ((p2.y - p3.y)*(pt.x - p3.x) + (p3.x - p2.x)*(pt.y - p3.y)) / ((p2.y - p3.y)*(p1.x - p3.x) + (p3.x - p2.x)*(p1.y - p3.y))
			--beta = ((p3.y - p1.y)*(pt.x - p3.x) + (p1.x - p3.x)*(pt.y - p3.y)) / ((p2.y - p3.y)*(p1.x - p3.x) + (p3.x - p2.x)*(p1.y - p3.y))
			--gamma = 1.0 - alpha - beta
				
			--if alpha>0 and beta>0 and gamma>0 then
				
			-- player collect
			if in_circle(g.pos.x,g.pos.y, p.pos.x,p.pos.y,6) then
				gems.remove(g)
				meter.gain()
			end

			if g.t>100 then gems.remove(g) end	--decay to remove
			g.t+=1
		end)
	end,
	_draw=function()
		foreach(gems.all, function(g)
			circfill(g.pos.x,g.pos.y,1,random(13,15))
		end)
	end,
	remove=function(o)
		del(gems.all,o)
	end
}


--
-- #title screen
--
titlescreen={
	_init=function()
		cart.update=titlescreen._update
		cart.draw=titlescreen._draw
		
	end,
	
	_update=function()
		
		if btnzp or btnxp then
			game._init()	
		end
	end,
	
	_draw=function()
		center_text("my game\n\npress "..char.btnz.." to start",40,7)
		
	end
}


--
-- #stars
--
stars={
	colors={1,12,6},
	all={},
	_init=function()
		for n=0,48 do
			stars.create()
		end
		
	end,
	create=function()
		local obj={
			x=64,
			y=64,
			dir=rnd(1),
			t=0,
			s=rnd(3)+1
		}
		
		local r=random(1,#stars.colors)
		obj.c=stars.colors[r]
		
		obj.dx,obj.dy=dir_calc(obj.dir, obj.s)
		add(stars.all,obj)
	end,
	_update=function()

	end,
	_draw=function()
		foreach(stars.all, function(s)
			--s.dx,s.dy=dir_calc(s.dir, s.s)	
				
			pset(s.x,s.y,s.c)
			s.x+=s.dx
			s.y+=s.dy
				
			--s.s+=.3
				
			if offscreen(s.x,s.y) then 
				s.x=rail.pos.x 
				s.y=rail.pos.y 
				--s.s=.5
			end
		end)
	end
}


--
-- #game
--





game={
	t=0,
	_init=function()
		
		--threesome(rnd(),40)
		--enemy.create.threesome(1,40)
		--enemy.create.threesome(1,30)
		--enemy.create.threesome(1,20)
		--enemy.create.threesome(.75,40)
		
		enemy.create.circle(.25,10)
		enemy.create.square(1,5,1)
		enemy.create.square(.25,40,-1)
		--enemy.create.square(.5,40)
		--enemy.create.square(.75,40)
		
		stars._init()
		cart.update=game._update
		cart.draw=game._draw
	end,
	_update=function()
		if game.t>100 then
			enemy.create.square(rnd(),5,1)
			game.t=9
		end
		
		
		
		--meter._update()
		enemy._update()
		gems._update()
		stars._update()
		ghosts._update()
		p._update()
		bullets._update()
		shots._update()
		
		game.t+=1
	end,
	_draw=function()
		circ(64,64,rail.rad,1)
		--[[
		
		
		local ldir=0
		for n=0,15 do
			draw_line(64,64,rail.rad,ldir,1)
			ldir+=.0625
		end]]

		
		--debug_line(flr((stat(0)/1024)*100))
		--debug_line(#warp.all)

		
		
		stars._draw()
		warp._draw()
		bullets._draw()
		ghosts._draw()
		gems._draw()
		enemy._draw()
		p._draw()
		shots._draw()
		
		--meter._draw()
		
	end
	
}





--
-- #gameover
--
gameover={
	wait=30,
	_init=function()
		gameover.t=0
		cart.update=gameover._update
		cart.draw=gameover._draw
	end,
	
	_update=function()
		if gameover.t>=gameover.wait and btnzp then _init() end
		gameover.t+=1
	end,
	
	_draw=function()
		center_text("game over",10,8)
		center_text("final score\n"..score_text(p.score),30,7)
		
		if gameover.t>=gameover.wait then
			center_text("press "..char.btnz.." to continue",60,6)
		end
	end
}



--
-- #loop
--
--cartdata("savedata") --load savedata

function _init()
	p._init()
	game._init()
end

function _update()
	btnl=btn(0)
	btnr=btn(1)
	btnlp=btn(0)
	btnrp=btn(1)
	btnu=btn(2)
	btnd=btn(3)
	btnz=btn(4)
	btnx=btn(5)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	cart.update()
end

function _draw()
	cls()
	cart.draw()
	
	
	debug_out()
end





--
-- #utility
--

-- debug tools
-- debug tools
debugtext=""
function debug(str) debugtext=str end
function debug_line(str) debugtext=debugtext.."\n"..str end
function debug_out() print(debugtext, 10,3, 1) print(debugtext, 10,2, 11) debugtext="" end
function debug_hitbox(obj,c) 
	local color=c or 11
	rect(obj.pos.x+obj.hitbox.x,obj.pos.y+obj.hitbox.y, obj.pos.x+obj.hitbox.x+obj.hitbox.w,obj.pos.y+obj.hitbox.y+obj.hitbox.h, color)
end


-- get dx/dy calculations for movement
function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

function pt_on_circle(angle,rad)
	local dx=cos(angle)*rad
	local dy=sin(angle)*rad
	
	return dx,dy
end


function draw_line(x,y,dist,dir,color)
	fx = cos(dir)*dist+x
	fy = sin(dir)*dist+y

	line(x,y,fx,fy,color)
	
	return fx,fy
end

function get_line(x,y,dist,dir)
	fx = flr(cos(dir)*dist+x)
	fy = flr(sin(dir)*dist+y)
	
	return fx,fy
end

function pythag (a, b)
  return sqrt(a^2+b^2)
end

function distance(ox,oy, px,py)
  local a = ox-px
  local b = oy-py
  return pythag(a,b)
end


function angle_lerp(angle1, angle2, t)
	angle1=angle1%1
	angle2=angle2%1

	if abs(angle1-angle2)>0.5 then
	  if angle1>angle2 then
	   angle2+=1
	  else
	   angle1+=1
	  end
	end

	return ((1-t)*angle1+t*angle2)%1
end

-- print out score text from large number
function score_text(val)
   local s = ""
   local v = abs(val)
   while (v!=0) do
     s = shl(v % 0x0.000a, 16)..s
     v /= 10
   end
   if (val<=0)  s = "0"..s
   return s 
end

-- center string on screen, assumes full viewport
function center_text(s,y,c) print(s,64-(#s*2),y,c) end

-- returns true if number is even
function is_even(n) 
	if (n%2==0) then return true else return false end
end


-- checks to see if value is in a table
function in_table(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end

-- animate sprites
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

-- returns true if x/y is out of screen bounds
function offscreen(x,y)
	if (x<screen.x or x>screen.w or y<screen.y or y>screen.h) then 
		return true
	else
		return false
	end
end



				
function collide(obj, other, custom)
	local bhitbox=custom or obj.hitbox

    if
        other.pos.x+other.hitbox.x+other.hitbox.w > obj.pos.x+bhitbox.x and 
        other.pos.y+other.hitbox.y+other.hitbox.h > obj.pos.y+bhitbox.y and
        other.pos.x+other.hitbox.x < obj.pos.x+bhitbox.x+bhitbox.w and
        other.pos.y+other.hitbox.y < obj.pos.y+bhitbox.y+bhitbox.h 
    then
        return true
    end
end
				
-- in_circle(objx,objx, circx,circy,circrad)
function in_circle(ox,oy,cx,cy,cr)
	local dx = abs(ox-cx)
	local dy = abs(oy-cy)
	local r = cr

	local k = r/sqrt(2)
	if dx <= k and dy <= k then return true end
end		
				
function on_circle(objpos, circ)
	local check=(objpos.x-circ.x)^2 + (objpos.y-circ.y)^2
	if check<rail.rad^2 then
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


-- a,b,c
function ccw(l1s,l1e,l2s)
    return (l2s.y-l1s.y) * (l1e.x-l1s.x) > (l1e.y-l1s.y) * (l2s.x-l1s.x)
end

-- Return true if line segments AB and CD intersect
-- a,b, c,d
-- l1s.x,l1s.y; l1e.x,l1e.y; l2s.x,l2s.y; l2e.x,l2e.y
function intersect(l1s,l1e, l2s,l2e) 
    return ccw(l1s,l2s,l2e) != ccw(l1e,l2s,l2e) and ccw(l1s,l1e,l2s) != ccw(l1s,l1e,l2e)
end


				
				
				
				
function PointWithinShape(shape, tx, ty)
	if #shape == 0 then 
		return false
	elseif #shape == 1 then 
		return shape[1].x == tx and shape[1].y == ty
	elseif #shape == 2 then 
		return PointWithinLine(shape, tx, ty)
	else 
		return CrossingsMultiplyTest(shape, tx, ty)
	end
end
 
function BoundingBox(box, tx, ty)
	return	(box[2].x >= tx and box[2].y >= ty)
		and (box[1].x <= tx and box[1].y <= ty)
		or  (box[1].x >= tx and box[2].y >= ty)
		and (box[2].x <= tx and box[1].y <= ty)
end
 
function colinear(line, x, y, e)
	e = e or 0.1
	m = (line[2].y - line[1].y) / (line[2].x - line[1].x)
	local function f(x) return line[1].y + m*(x - line[1].x) end
	return math.abs(y - f(x)) <= e
end
 
function PointWithinLine(line, tx, ty, e)
	e = e or 0.66
	if BoundingBox(line, tx, ty) then
		return colinear(line, tx, ty, e)
	else
		return false
	end
end
 
-------------------------------------------------------------------------
-- The following function is based off code from
-- [ http://erich.realtimerendering.com/ptinpoly/ ]
--
--[[
 ======= Crossings Multiply algorithm ===================================
 * This version is usually somewhat faster than the original published in
 * Graphics Gems IV; by turning the division for testing the X axis crossing
 * into a tricky multiplication test this part of the test became faster,
 * which had the additional effect of making the test for "both to left or
 * both to right" a bit slower for triangles than simply computing the
 * intersection each time.  The main increase is in triangle testing speed,
 * which was about 15% faster; all other polygon complexities were pretty much
 * the same as before.  On machines where division is very expensive (not the
 * case on the HP 9000 series on which I tested) this test should be much
 * faster overall than the old code.  Your mileage may (in fact, will) vary,
 * depending on the machine and the test data, but in general I believe this
 * code is both shorter and faster.  This test was inspired by unpublished
 * Graphics Gems submitted by Joseph Samosky and Mark Haigh-Hutchinson.
 * Related work by Samosky is in:
 *
 * Samosky, Joseph, "SectionView: A system for interactively specifying and
 * visualizing sections through three-dimensional medical image data",
 * M.S. Thesis, Department of Electrical Engineering and Computer Science,
 * Massachusetts Institute of Technology, 1993.
 *
 --]]
 
--[[ Shoot a test ray along +X axis.  The strategy is to compare vertex Y values
 * to the testing point's Y and quickly discard edges which are entirely to one
 * side of the test ray.  Note that CONVEX and WINDING code can be added as
 * for the CrossingsTest() code; it is left out here for clarity.
 *
 * Input 2D polygon _pgon_ with _numverts_ number of vertices and test point
 * _point_, returns 1 if inside, 0 if outside.
 --]]
function CrossingsMultiplyTest(pgon, tx, ty)
	local i, yflag0, yflag1, inside_flag
	local vtx0, vtx1
 
	local numverts = #pgon
 
	vtx0 = pgon[numverts]
	vtx1 = pgon[1]
 
	-- get test bit for above/below X axis
	yflag0 = ( vtx0.y >= ty )
	inside_flag = false
 
	for i=2,numverts+1 do
		yflag1 = ( vtx1.y >= ty )
 
		--[[ Check if endpoints straddle (are on opposite sides) of X axis
		 * (i.e. the Y's differ); if so, +X ray could intersect this edge.
		 * The old test also checked whether the endpoints are both to the
		 * right or to the left of the test point.  However, given the faster
		 * intersection point computation used below, this test was found to
		 * be a break-even proposition for most polygons and a loser for
		 * triangles (where 50% or more of the edges which survive this test
		 * will cross quadrants and so have to have the X intersection computed
		 * anyway).  I credit Joseph Samosky with inspiring me to try dropping
		 * the "both left or both right" part of my code.
		 --]]
		if ( yflag0 ~= yflag1 ) then
			--[[ Check intersection of pgon segment with +X ray.
			 * Note if >= point's X; if so, the ray hits it.
			 * The division operation is avoided for the ">=" test by checking
			 * the sign of the first vertex wrto the test point; idea inspired
			 * by Joseph Samosky's and Mark Haigh-Hutchinson's different
			 * polygon inclusion tests.
			 --]]
			if ( ((vtx1.y - ty) * (vtx0.x - vtx1.x) >= (vtx1.x - tx) * (vtx0.y - vtx1.y)) == yflag1 ) then
				inside_flag =  not inside_flag
			end
		end
 
		-- Move to the next pair of vertices, retaining info as possible.
		yflag0  = yflag1
		vtx0    = vtx1
		vtx1    = pgon[i]
	end
 
	return  inside_flag
end
 
function GetIntersect( points )
	local g1 = points[1].x
	local h1 = points[1].y
 
	local g2 = points[2].x
	local h2 = points[2].y
 
	local i1 = points[3].x
	local j1 = points[3].y
 
	local i2 = points[4].x
	local j2 = points[4].y
 
	local xk = 0
	local yk = 0
 
	if checkIntersect({x=g1, y=h1}, {x=g2, y=h2}, {x=i1, y=j1}, {x=i2, y=j2}) then
		local a = h2-h1
		local b = (g2-g1)
		local v = ((h2-h1)*g1) - ((g2-g1)*h1)
 
		local d = i2-i1
		local c = (j2-j1)
		local w = ((j2-j1)*i1) - ((i2-i1)*j1)
 
		xk = (1/((a*d)-(b*c))) * ((d*v)-(b*w))
		yk = (-1/((a*d)-(b*c))) * ((a*w)-(c*v))
	end
	return xk, yk
end



__gfx__
00000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

