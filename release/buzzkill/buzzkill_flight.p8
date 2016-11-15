pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- buzzkill
-- b vaughn

-- programmed and designed by brian vaughn (@morningtoast)
-- summer 2016
-- http://www.morningtoast.com

version="1.2"
t=0
screen={x=0,y=0,w=127,h=127,ground=112}
char={btnz="\142",btnx="\151"}
cart={_update=function() end,_draw=function() end}
killcount=0
hexkills=0
highscore=0
musicon=true


endless=false
endlessunlocked=0 -- must be in for saving to cart
endlesshigh=0

debug=function(s,clear)
	if not debugtext then debugtext=false end
	if clear then debugtext=false end
	debugtext=s
end



--
-- player
--
player={t=0}

player.reset=function() -- properties that should reset upon dying
	player.canfire=true
    player.btimer=0
    player.brate=8 -- bullet fire rate
    player.bspeed=6 -- bullet speed
	player.srate=5 --smoke fire rate (uses btimer)
	player.smin=0 -- minimum power to blow smoke
	player.fullpower=0
	player.power=0 -- percent
end

player._init=function() -- properties that don't change or reset when new game
	player.reset()
	
	player.pos={x=16,y=104,dx=0,dy=0}
	player.hitbox={x=0,y=0,w=8,h=8}
	player.bullets={}
	player.spr=35
	player.lives=3
	player.state=1
	player.score=shr(0,16)
	player.accel=1.5
	player.interia=.3
	player.power=100

end

player._update=function()
	--movement
	player.pos.dx *= player.interia

	if btnleft then player.pos.dx -= player.accel end
	if btnright then player.pos.dx += player.accel end 

	player.pos.x+=player.pos.dx

	if player.pos.x<=screen.x then player.pos.x=0 end
	if player.pos.x>=screen.w-player.hitbox.w then player.pos.x=screen.w-player.hitbox.w end

	
	--shooting
	if player.state==1 then
		if btna then
			-- fire shot
			if player.btimer>=player.brate then
				sfx(12)
				player.shootbullet(player.pos.x, player.pos.y)
				player.btimer=0
			end
		elseif btnb then
			-- smoke
			if player.btimer>=player.srate and player.power>=player.smin then
				sfx(13)
				smoke.add(player.pos.x+4, player.pos.y)
				player.btimer=0
			end
		end
		
		
		if player.btimer>=player.srate+player.brate then player.btimer=0 end
		player.btimer+=1
		
		foreach(shots.all, function(shot)
			if collide(player,shot) then
				del(shots.all,shot)

				player.damage()
				player.reset()
				player.state=2
				player.t=0
				player.lives-=1
				player.canfire=false
					
				if player.lives<=0 then
					player.state=3
					player.t=0
				end
			end
		end)
		
		-- falling hive collision
		foreach(hives.all, function(hive)
			if hive.st==3 then
				if collide(player,hive) then
					--explode.create(player.pos.x,player.pos.y)
					player.damage()
					player.reset()
					player.state=2
					player.t=0
				end
			end
		end)
	end
	
	
    
	player.meter()
	
	
	
	
	--player bullets, keep moving no matter what state
	foreach(player.bullets, function(obj)
		obj.pos.y-=player.bspeed
		if offscreen(obj.pos.x, obj.pos.y) then del(player.bullets, obj) end
	end)

	-- post-damage invincible; can't shoot
	if player.state==2 then
		if player.t>=45 then --frames until active
			player.state=1
			player.t=0
			player.canfire=true
		end
	end

	-- game over state; wait for 8s to auto-restart or quick after 2s
	if player.state==3 then
		if player.t==50 then gameover._init() end
	end


	player.t+=1
end

player._draw=function()
	if player.state<3 then
		--bullets
		foreach(player.bullets, function(obj) spr(16, obj.pos.x,obj.pos.y, 1,1) end)
		
		-- movement
		if player.state==2 then
			if is_even(player.t) then --flash sprite when post-damage
				spr(player.spr, player.pos.x,player.pos.y, 1,1)
			end
		else 
			spr(player.spr, player.pos.x,player.pos.y, 1,1)
		end
	end
	
	
	-- power bar width
	local barmax=126
	local barwidth=flr(barmax*(player.power/100))
	local barcolor=7
	
	if player.fullpower>0 then barcolor=random(1,15) end -- rainbow for powerup

	-- power meter hud
	rectfill(1,122, 126,126, 8) --red
	rectfill(25,122, 95,126, 9) --yellow
	rectfill(75,122, 126,126, 3) --green
	rectfill(1,122, barwidth,126, barcolor) --power bar
	rect(0,122, 127,127, 7) --border
	

	--score
	print(getscoretext(player.score),1,115,7)
	
	-- lives
	local heartx=90
	for n=1,player.lives do
		print("\135",heartx,115,7)
		heartx+=8
	end
end

player.damage=function()
	sfx(16)
	local pg=.0725
	for n=1,6 do
		local px=player.pos.x+4
		local py=player.pos.y+4
		 --gravity, variance on burst and fall style

		px+=flr(rnd(10))
		py-=flr(rnd(8))

		fireworks_create(px,py,10,18,pg)
		fireworks_create(px,py,8,18,pg)	
		
		pg+=.01
		pg=max(.02,pg)
	end
end

-- create player bullet
player.shootbullet=function(x,y)
	add(player.bullets, {
		pos={x=x,y=y},
		hitbox={x=3,y=0,w=4,h=1}
	})	
end


-- power meter
player.meter=function()
	if player.fullpower<=0 then
		-- when no button, power up the bar
		if not btnb and not btna then
			player.power+=.75

			if player.power>=100 then player.power=100 end
		end

		-- reduce power when pushing a button
		if btnb and player.power>=player.smin then player.power-=2 end -- smoke
		if btna then player.power-=.25 end -- shoot

		if player.power<=1 then player.power=1 end
	else
		-- keep max when powerup applied
		player.power=100
		player.fullpower-=1
	end
	
	
	-- power reduction rate
	player.brate=10
	player.srate=45 --smoke output rate, higher=slower
	
	-- reduce attack rates based on power level
	if player.power>=20 then 
		player.brate=6
		player.srate=6
	end
	
	if player.power>=60 then 
		player.brate=4
		player.srate=2
	end
end







--
-- hives
--
hives={
	all={},
	_init=function()
		hives.all={}
		hives.seed()
	end,
	
	_update=function()
		foreach(hives.all, function(hive)

			-- normal state + spawning
			if hive.st==1 then
				if hive.s==hive.spawn then
					if #bees.all<level.current.beemax then
						bees.create(hive.pos.x+8,hive.pos.y+10)
					end
						
					hive.s=0
				end
				
				hive.s+=1
			end
				
			-- shaking, happens over half second; no spawning during shake state
			if hive.st==2 then
				if hive.t<15 then
					if not is_even(hive.t) then
						hive.pos.x-=2
					else
						hive.pos.x+=2
					end
				else
					hive.pos.x=hive.ox
					hive.st=1
					hive.s=0
					hive.t=0
				end
				
				hive.t+=1
			end
				
				
			-- falling to ground; explode when hits ground
			if hive.st==3 then
				if hive.pos.y+hive.hitbox.h<screen.ground then
					hive.pos.y+=3.5
				else
					fireworks_create(hive.pos.x+8,hive.pos.y,15,32)
					hive.st=4 -- state 4 is for _draw() animation only 
				end
			end

			-- bullet collision
			if hive.st<3 then
				foreach(player.bullets, function(bullet)
					if collide(hive,bullet) then
						del(player.bullets,bullet) 

						hive.st=2
						hive.hp-=1

						if hive.hp==0 then
							sfx(10)
							if not endless then player.score+=shr(hive.score,16) end
							hive.st=3
						end
					end	
				end)
			end
		end)
	end,
	
	_draw=function()
		foreach(hives.all, function(obj)
				
			if obj.st<4 then
				spr(obj.spr, obj.pos.x,obj.pos.y, obj.sprw,obj.sprh)
			else
				-- squish hive when it reaches the ground
				obj.hitbox.h-=3
				obj.pos.y+=3
				if obj.hitbox.h>0 then
					sspr(64,0,16,16, obj.pos.x,obj.pos.y, obj.hitbox.w,obj.hitbox.h)	
				end

				if obj.hitbox.h<=0 then del(hives.all,obj) end
			end
			
		end)
	end,


	-- hive placement per level config
	seed=function()
		foreach(level.current.hives, function(objx)
			add(hives.all, hives.create(objx))		
		end)
	end,


	-- hive object 
	create=function(x)
		return({
			spr=8,
			sprw=2, --block width
			sprh=2, --block height
			pos={x=x,y=0},
			ox=x, --original x pos, used for shake realignment
			hitbox={x=2,y=0,w=14,h=14},
			hp=38,
			s=0,--spawn timer
			spawn=random(120,180), --spawn interval
			t=0,
			st=1, --state; 1=normal, 2=shake, 3=falling	
			score=500
		})
	end
}


--
-- bomber bees
--
bees={
	all={},
	
	_init=function()
		bees.all={}
	end,
	
	_update=function()
		foreach(bees.all, function(mob)
			mob.damage=false
				
			-- bullet collide
			foreach(player.bullets, function(bullet)
				if collide(mob,bullet) then
					del(player.bullets,bullet) 
					bees.hit(mob)
				end	
			end)	

			-- normal side movement
			if mob.st==1 then
				mob.pos.x+=mob.dx
				mob.pos.y+=mob.dy
					
				-- bounces when hitting left edge
				if mob.pos.x<=screen.x then
					if rnd(1)<.5 then
						mob.dir=0+rnd(.06)
					else
						mob.dir=0-rnd(.06)
					end

					mob.dx,mob.dy=dir_calc(mob.dir,mob.speed)
					mob.flip=true
				end

				-- bounce when hit right edge
				if mob.pos.x>=screen.w-mob.hitbox.w+1 then
					if rnd(1)<.5 then
						mob.dir=.5+rnd(.06)
					else
						mob.dir=.5-rnd(.06)
					end

					mob.dx,mob.dy=dir_calc(mob.dir,mob.speed)
					mob.flip=false
				end

				-- bounce when too low
				if mob.pos.y>=64 then 
					if rnd(1)<.5 then
						mob.dir=.45
						mob.flip=false
					else
						mob.dir=.06
						mob.flip=true
					end

					mob.dx,mob.dy=dir_calc(mob.dir,mob.speed)
				end

				if offscreen(mob.pos.x,mob.pos.y) then del(bees.all, mob) end
					
				-- fire!
				if mob.t==mob.shoot then
					mob.st=2
					mob.t=0	
				end
			end
				
				
			-- shoot state, stop the bee, shoot burst then continue moving
			if mob.st==2 then
				if mob.t==10 or mob.t==20 or mob.t==30 then
					shots.snipe(mob.pos.x+16, mob.pos.y+7)
				end
				
				if mob.t>30 then 
					mob.st=1
					mob.t=0
				end
			end

			mob.t+=1
		end)
		
	end,
	
	_draw=function()
		foreach(bees.all, function(mob)
			if mob.ani==2 then pal(7,0)	mob.ani=0 end --wing flash
			
			if mob.damage then
				pal(10,7)
				pal(0,7)
				pal(8,7)
			end
			
			
			spr(22, mob.pos.x,mob.pos.y, 2,2, mob.flip)
			palreset()

			mob.ani+=1
		end)
		
	end,
	
	hit=function(obj)
		obj.hp-=1
		obj.damage=true
		
		if obj.hp<=0 then
			sfx(14)
			fireworks_create(obj.pos.x,obj.pos.y, 8, 24)
			powerup.chance(obj)
			del(bees.all, obj)
			if not endless then player.score+=shr(obj.score,16) end
			
			killcount+=1
		end
	end,
	
	create=function(x,y)
		local mob={
			pos={x=x,y=y},
			hitbox={x=0,y=0,w=16,h=8},
			hp=12,
			dir=.5,
			speed=.5,
			t=0,
			st=1,
			flip=false,
			ani=0,
			shoot=random(100,160),
			score=150,
			damage=false
		}

		if flr(rnd(2))==1 then 
			mob.dir=0 
			mob.flip=true
		end
		mob.dir+=rnd(.06)

		mob.dx=cos(mob.dir)*mob.speed
		mob.dy=sin(mob.dir)*mob.speed

		
		add(bees.all, mob)
	end,
	
}


--
-- hexes
--
hexes={
	all={},
	_init=function()
		hexes.all={}
		hexes.seed()
	end,
	
	_update=function()
		--local new={}
		foreach(hexes.all, function(obj)

			-- normal state, grow+spawn
			if obj.st==1 then
				
				-- expand
				if obj.g==obj.grow then
					if #hexes.all<level.current.hexmax then
						local maxside=6
							
						if (obj.pos.y==20) maxside=4 --limit side pool for row1 hexes

						
						local side=flr(rnd(maxside))+1 --pick a random side 
						local coord=hexes.sidecoord(obj.pos.x,obj.pos.y,side) --get x/y of side
							
						if coord.x>0 and coord.x<120 and coord.y>=16 and coord.y<61 then
							--only expand if the next hex is unoccupied
							--if there's no open slot then it just keeps going; a new hex is not guaranteed every time
							if not hexes.has_hex(coord.x, coord.y) then 
								add(hexes.all, hexes.create(coord.x, coord.y))
							end
						end
					end

					obj.g=0
				end
				
				-- spawn tiny bee
				if obj.s==obj.spawn then
					obj.st=3
					obj.s=0
				end
				
				obj.s+=1
			end
		
			--frozen
			if obj.st==2 then
				if obj.t==obj.thaw then --thaw, change back to normal
					obj.st=1
					obj.g=0
					obj.s=0
				else
					--bullet collision only happens when frozen
					foreach(player.bullets, function(bullet)
						if collide(bullet,obj) then
							sfx(9)
							fireworks_create(obj.pos.x,obj.pos.y, 10)
							del(player.bullets, bullet)
							del(hexes.all, obj)
							if not endless then player.score+=shr(obj.score,16) end
							
							hexkills+=1
						end
					end)
				end
					
				obj.t+=1
			end
			
			-- spawn
			if obj.st==3 then
				if #mobs.all<level.current.mobmax then
					if obj.s==15 then
						mobs.spawn(obj.pos.x, obj.pos.y)
					end
	
					if obj.s>=30 then
						obj.st=1 
						obj.s=0
					end
				else
					obj.st=1 
					obj.s=0
				end
					
				obj.s+=1
			end
				
			--when hex is flagged as a bomb
			if obj.st==4 then
				--bullet collision only happens when frozen
				foreach(player.bullets, function(bullet)
					if collide(bullet,obj) then
						hexes.bomb(obj)
						del(player.bullets, bullet)
					end
				end)
				
				-- back to normal after time limit
				if obj.t>=180 then
					obj.st=1
					obj.g=0
					obj.s=0
				end
				obj.t+=1
			end
			
			-- smoke collision check; only checking single pixel for color change
			if pget(obj.smokebox.x,obj.smokebox.y)==5 and obj.st<4 then
				obj.st=2
				obj.t=0
			end

			obj.g+=1
			if obj.g>obj.grow then obj.g=0 end
		end)
	end,
	
	_draw=function()
		foreach(hexes.all, function(obj)
			
			-- frozen state
			if obj.st==2 then 
				pal(9,12) 
				pal(10,7)
				pal(4,6)
			end
				
			--bomb state
			if obj.st==4 then
				local c=random(1,15)
				pal(4,c)	
				pal(10,8)
				pal(9,7)
			end
				
			--spawn state, open door
			if obj.st==3 then pal(4,0) end
	
			spr(obj.spr, obj.pos.x,obj.pos.y, obj.sprw,obj.sprh)
				
			palreset()
		end)
	end,
	
	--hex bomb explosion clears neighboring hexes
	bomb=function(obj)
		for side=1,6 do
			local check=hexes.sidecoord(obj.pos.x,obj.pos.y,side)
			local hashex=hexes.has_hex(check.x,check.y)
			if hashex then
				fireworks_create(hashex.pos.x,hashex.pos.y, 7)
				del(hexes.all, hashex)
			end
		end
		
		sfx(15)
		fireworks_create(obj.pos.x,obj.pos.y, 7)
		del(hexes.all, obj)
	end,

	-- add hexes to field based on level config
	seed=function()
		foreach(level.current.seeds, function(build)
			local rowx=1
			local rowy=build.row*10
			local xspace=6 -- x pixels between hexes
				
			if is_even(build.row) then 
				rowx=4 
				if build.qty>19 then build.qty=19 end
			end
				
			rowx+=build.offset*xspace
			
			for n=0,build.qty do
				if not hexes.has_hex(rowx, rowy) then
					add(hexes.all, hexes.create(rowx, rowy))
				end
				rowx+=xspace
			end
		end)
	end,
	
	--checks to see if x/y is occupied by a hex
	has_hex=function(x,y) 
		local empty=false
		
		foreach(hexes.all, function(hex)
			if hex.pos.x==x and hex.pos.y==y then
				empty=hex 
			end
		end)
		
		return empty
	end,

	-- returns x/y of neighboring hex based on x/y and side
	-- 1=right,2=se,3=sw,4=left,5=nw,6=ne
	sidecoord=function(nhx,nhy,side)
		if side==1 then
			nhx+=6
		elseif side==2 then
			nhx+=3
			nhy+=10
		elseif side==3 then
			nhx+=-3
			nhy+=10
		elseif side==4 then
			nhx+=-6
		elseif side==5 then
			nhx+=-3
			nhy+=-10
		elseif side==6 then
			nhx+=3
			nhy+=-10
		end
		
		return {x=nhx,y=nhy}
		
	end,

	-- hex object 
	create=function(x,y)
		local obj={
			spr=1,
			sprw=1,
			sprh=2,
			pos={x=x,y=y},
			hitbox={x=1,y=3,w=4,h=7},
			smokebox={x=x+4,y=y+11},
			
			thaw=80, -- frames before unfrozen
			t=0, --thaw timer
	
			s=0,--spawn timer
			spawn=random(level.current.spawn,level.current.spawn+50), --interval between spawns

			g=0,--expand timer
			grow=random(level.current.grow,level.current.grow+50), --interval between expand attempt
			
			st=1, --state; 1=normal, 2=frozen, 3=spawn
			score=50
		}
		
		return obj
		
	end
}



--
-- tiny bees
--
mobs={}

mobs._init=function()
	mobs.all={}
end

mobs._update=function()
	foreach(mobs.all, function(mob)
		
		-- bullet collision
		foreach(player.bullets, function(bullet)
			if collide(mob,bullet) then
				fireworks_create(mob.pos.x,mob.pos.y, 8)
				powerup.chance(mob) --powerup drop
						
				sfx(14)
				del(mobs.all,mob) 
				del(player.bullets,bullet) 
				if not endless then player.score+=shr(mob.score,16) end
				
				killcount+=1
			end	
		end)	
			
		mob.pos.x+=mob.dx
		mob.pos.y+=mob.dy
			
		-- changes bee speed when hit by smoke
		if pget(mob.pos.x, mob.pos.y+4)==5 then
			if mob.speed>1 then 
				mob.speed-=.5
				mob.shoot+=15
				mob.shoot=min(mob.shoot,120)
			end
		end

		
		-- edge reversing
		-- bounce to right
		if mob.pos.x<=screen.x then
			if rnd(1)<.5 then
				mob.dir=0+rnd(.06)
			else
				mob.dir=0-rnd(.06)
			end
				
			mob.dx,mob.dy=dir_calc(mob.dir,mob.speed)

			mob.flip=true
		end
			
		--bounce to left
		if mob.pos.x>=screen.w-mob.hitbox.w+1 then
			if rnd(1)<.5 then
				mob.dir=.5+rnd(.06)
			else
				mob.dir=.5-rnd(.06)
			end
				
			mob.dx,mob.dy=dir_calc(mob.dir,mob.speed)

			mob.flip=false
		end
			
		-- bounce bee up if it hits bottom threshold, don't want to get too close to player
		if mob.pos.y>=80 then 
			if rnd(1)<.5 then
				mob.dir=.45
				mob.flip=false
			else
				mob.dir=.06
				mob.flip=true
			end
				
			mob.dx,mob.dy=dir_calc(mob.dir,mob.speed)
		end
			
		if offscreen(mob.pos.x,mob.pos.y) then del(mobs.all, mob) end
			
			
			
		-- fire!
		if mob.t==mob.shoot then
			shots.create(mob.pos.x+7, mob.pos.y+7)
			mob.t=0	
		end
			
		mob.t+=1
	end)
	
end

mobs._draw=function()
	foreach(mobs.all, function(mob)
		if mob.ani==2 then pal(7,1) mob.ani=0 end --wing flash
		spr(2, mob.pos.x,mob.pos.y, 1,1, mob.flip)
		palreset()
			
		mob.ani+=1
	end)
end


mobs.spawn=function(x,y)
	local mob={
		pos={x=x,y=y},
		hitbox={x=1,y=3,w=6,h=5},
		hp=2,
		dir=.5,
		speed=rnd(1)+.6, --random speed
		t=0,
		flip=false,
		ani=0,
		shoot=flr(random(30,90)), --shot interval
		score=20
	}
	
	-- random start direction as it comes out of hex
	if flr(rnd(2))==1 then 
		mob.dir=0 
		mob.flip=true
	end
	
	-- random variance to direction so it's not always a straight line
	mob.dir+=rnd(.06)
	
	mob.dx,mob.dy=dir_calc(mob.dir,mob.speed)
	
	add(mobs.all, mob)
end



--
-- powerups
--

powerup={
	all={},
	chance=function(obj)
		if rnd(1)<.2 and #powerup.all<4 then --20% chance of a powerup drop, only when 4 or less in play
			powerup.drop(obj.pos.x, obj.pos.y)
		end
	end,
	drop=function(x,y)
		local putype=flr(rnd(3))+1 --random powerup type
		local pu={
			pos={x=x,y=y},
			hitbox={x=0,y=0,w=8,h=8},
			alive=90, --time before powerup disappears
			dy=1
		}
		
		-- each powerup should have an apply() method which is
		-- called upon collision with player
		
		-- full power meter for player
		if putype==1 then
			pu.spr=3
			pu.color=10
			pu.apply=function()
				player.fullpower=180 --length of powerup
			end
		end
		
		-- turn a hex into a bomb
		if putype==2 then
			pu.spr=5
			pu.color=14
			pu.apply=function()
				if #hexes.all>0 then
					local pickhex=random(1,#hexes.all)
					hexes.all[pickhex].st=4
					hexes.all[pickhex].t=0
				end
			end
		end
		
		-- freeze all hexes
		if putype==3 then
			pu.spr=4
			pu.color=11
			pu.apply=function()
				if #hexes.all>0 then
					foreach(hexes.all, function(hex) 
						hex.st=2 
						hex.t=0
					end)
				end
			end
		end

		add(powerup.all, pu)
	end,
	_update=function()
		foreach(powerup.all, function(pu)
			local dy=pu.pos.y+pu.dy 
			if dy<screen.ground-pu.hitbox.h then --powerup is falling
				pu.pos.y=dy
			else
				--powerup on the ground, start kill timer
				pu.alive-=1
				if pu.alive<=0 then del(powerup.all,pu) end
			end
				
			-- call apply() when player collision
			if collide(pu,player) then
				pu.apply()
				sfx(11)
				del(powerup.all,pu)
			end
		end)
	end,
	_draw=function()
		foreach(powerup.all, function(pu)
			local color=random(2,15)
			pal(10,color)
			spr(pu.spr, pu.pos.x,pu.pos.y, 1,1)
			palreset()
		end)
	end

}


	
--
-- boss level
--
boss={
	_init=function()
		level.current={seeds={}}
			
		shots.all={}
		fireworks={}
			
		wasp._init()
		mobs._init()
		hexes._init()
			
		play_music(53)

		cart._update=boss._update
		cart._draw=boss._draw			
	end,
	_update=function()
		player._update()
		mobs._update()
		shots._update()
		hexes._update()
		wasp._update()

		powerup._update()

		fireworks_update()
		smoke._update()
	end,
	_draw=function()
		map(0,0, 0,0, 16,16)
		
		hexes._draw()
		powerup._draw()

		player._draw()
		wasp._draw()
		mobs._draw()

		shots._draw()

		fireworks_draw()
		smoke._draw()
	end
		
}


--
-- wasp boss
--
wasp={
	_init=function()
		wasp.st=0 --state; 0=intro,1=moving/hex,2=big shot,
		wasp.pos={x=64,y=-40}
		wasp.hitbox={x=9,y=5,w=12,h=26}
		wasp.dir=-1
		wasp.hflip=false
		wasp.hpmax=200
		wasp.hp=wasp.hpmax
		wasp.t=0
		wasp.ani=0
		wasp.speed=1
		wasp.throw=random(30,90)
		wasp.throwt=0
		wasp.damage=false
		wasp.dead=false
	end,
	_update=function()
		wasp.gun={x=wasp.pos.x+16,y=wasp.pos.y+30}
			
		if wasp.hp<wasp.hpmax*.5 then wasp.speed=1.6 end
		if wasp.hp<wasp.hpmax*.25 then wasp.speed=2 end
			
		--entrance
		if wasp.st==0 then 
			if wasp.pos.y<3 then
				wasp.pos.y+=.5 
			else
				wasp.state(1)
			end
				
		--horz move+hex shot
		elseif wasp.st==1 then 
			local dx=wasp.pos.x+wasp.speed*wasp.dir
				
			if dx<=0 then wasp.dir=1 wasp.hflip=true end
			if dx>=screen.w-32 then wasp.dir=-1 wasp.hflip=false end
			
			wasp.pos.x=dx
				
			-- shoot hex gun
			if wasp.throwt>=wasp.throw then
				local row=random(2,5)
				local col=random(2,16)
				shots.hex(wasp.gun.x,wasp.gun.y, row,col)
					
				wasp.throwt=0
			end
				
			--switch state; stop and shoot bullets
			if wasp.t>=wasp.halt then
				wasp.state(2)	
			end
				
			
		-- wait and shoot	
		elseif wasp.st==2 then 
			if wasp.t==30 then
				sfx(17)
				shots.wasp(wasp.gun.x,wasp.gun.y)
			end
			
			if wasp.t>=60 then
				wasp.throw=random(80,90)
				wasp.state(1) 
			end
				
		--death change
		elseif wasp.st==3 then 
			if wasp.t==150 then -- this needs to match with timers in draw()
				wasp.st=4
				
				fireworks_create(wasp.pos.x+16,wasp.pos.y+16, 10, 24, .0275)
				for n=0,24 do
					wasp.spray()
				end
				fireworks_create(wasp.pos.x+16,wasp.pos.y+16, 0, 24, .0275)
				sfx(20)
				wasp.t=0
				wasp.dead=true
			end
		end
			
		-- collission
		if wasp.st<3 and wasp.st>0 then
			wasp.damage=false
			foreach(player.bullets, function(bullet)
				if collide(wasp,bullet) then
					sfx(18)
					wasp.hp-=1
					del(player.bullets, bullet)
					wasp.damage=true

					if wasp.hp==0 then wasp.death() end
				end
			end)
		end
			
			
		if wasp.dead and wasp.t>90 then gameover._init() end
			
				
		wasp.t+=1
		wasp.throwt+=1
	end,
	_draw=function()
		-- active state
		if wasp.st<3 then
			if wasp.ani==2 then pal(7,5) wasp.ani=0 end --wing flash
				
			if wasp.damage then
				pal(10,7)
				pal(8,7)
				pal(0,7)
				pal(9,7)
			end
				
			spr(10, wasp.pos.x,wasp.pos.y, 4,4, wasp.hflip)
			palreset()
			wasp.ani+=1
		end
			
		-- death state; change colors
		-- make sure numbers here match with update() state 3 timers
		if wasp.st==3 then
			local c=7
				
			if wasp.t>120 then c=8 pal(7,c)  end	
			if wasp.t>90 then pal(0,c)  end
			if wasp.t>75 then pal(10,c) end
			if wasp.t>60 then 
				pal(9,c) 
				
			end
			if rnd(1)<.5 then wasp.spray() sfx(9) end
				
			if wasp.t<150 then
				spr(10, wasp.pos.x,wasp.pos.y, 4,4, wasp.hflip)
			end
			palreset()
		end
			
		-- wasp health bar
		local barwidth=127*(wasp.hp/wasp.hpmax)
		rectfill(0,0, barwidth,1, 8)
	end,
	
	-- state change
	state=function(s)
		wasp.st=s
		wasp.t=0
			
		if wasp.st==1 then 
			wasp.halt=random(90,150) -- get a random halt timer after every stop+shoot
			wasp.throwt=0
		end
		
	end,
	
	spray=function()
		
		local rx=random(wasp.pos.x+12,wasp.pos.x+wasp.hitbox.w)
		local ry=random(wasp.pos.y,wasp.pos.y+wasp.hitbox.h)
		fireworks_create(rx,ry, 8, 18, rnd(1)+.0175)
	end,
		
	-- add hex to the board. called from shots.hex()
	hex=function(row,offset)
		level.current={spawn=45,grow=80,mobmax=8,hexmax=20,seeds={{offset=offset,qty=0,row=row}}}
		hexes.seed()
	end,
	
	-- death actions; kill all other mobs and switch state
	death=function()
		shots.all={}
		
		sfx(9)
		wasp.spray()
		
		foreach(hexes.all, function(hex)
			fireworks_create(hex.pos.x,hex.pos.y, 9)
			del(hexes.all,hex)
		end)

		foreach(mobs.all, function(mob)
			fireworks_create(mob.pos.x,mob.pos.y, 8)
			del(mobs.all,mob)
		end)

		wasp.state(3)
	end
	
}
	
	
	
	



--
-- shots - all shots. 
-- each shot type should have local draw/update functions
--
shots={all={}}

	
-- shot from wasp that leads to addition of hex to board
shots.hex=function(x,y, row,offset)
	local rowx=1
	local rowy=row*10
	local xspace=6 -- x pixels between hexes

	if is_even(row) then rowx=4 end

	rowx+=offset*xspace

		
	if not hexes.has_hex(rowx, rowy) and #hexes.all<12 then
		local target=atan2(rowx-x, rowy-y) -- angle towards hex x/y

		local obj={
			dest={
				pos={x=rowx-4,y=rowy-4}, -- making a temp hitbox at destination so shot will stop
				hitbox={x=0,y=0,w=8,h=14}
			},
			pos={x=x,y=y},
			hitbox={x=-3,y=-3,w=3,h=3},
			draw=function(obj)
				spr(18, obj.pos.x,obj.pos.y)
			end,
			update=function(obj)
				if collide(obj,obj.dest) then
					del(shots.all, obj)	
					wasp.hex(row,offset)
				end
			end
		}

		obj.dx=cos(target)*2
		obj.dy=sin(target)*2

		add(shots.all, obj)
	end
end
	
-- spread shot from wasp. centers on player with +2 spread
shots.wasp=function(x,y)
	local ang=.0425
	local pang=atan2(player.pos.x-x, player.pos.y-y)
	local list={pang}
	add(list,pang-ang)
	add(list,pang-ang*2)
	add(list,pang+ang)
	add(list,pang+ang*2)
		
	foreach(list, function(ang)
		local obj={
			pos={x=x,y=y},
			hitbox={x=-3,y=-3,w=3,h=3},
			draw=function(obj)
				circfill(obj.pos.x,obj.pos.y, 2.5, 7)
			end
		}
		obj.dx=cos(ang)*2
		obj.dy=sin(ang)*2

		add(shots.all, obj)
	end)

end
	
--tiny bee shot
shots.create=function(x,y)
	local obj={
		pos={x=x,y=y},
		hitbox={x=0,y=0,w=1,h=4},
		draw=function(obj)
			line(obj.pos.x,obj.pos.y, obj.pos.x,obj.pos.y+4, 7)
		end,
		update=function(obj)
			if pget(obj.pos.x,obj.pos.y)==5 then del(shots.all, obj) end --kill shot if it hits smoke
		end
	}
	
	local target=.75
	local speed=1.5
	
	obj.dx=cos(target)*speed
	obj.dy=sin(target)*speed
	
	add(shots.all, obj)
end

-- big bee shot, targeted toward player
shots.snipe=function(x,y)
	local obj={
		pos={x=x,y=y},
		hitbox={x=-3,y=-3,w=3,h=3},
		draw=function(obj)
			circfill(obj.pos.x,obj.pos.y, 3, 7)
		end
	}

	local target=atan2(player.pos.x-obj.pos.x+4, player.pos.y-obj.pos.y+4)
	local speed=1.5

	obj.dx=cos(target)*speed
	obj.dy=sin(target)*speed

	add(shots.all, obj)
end

shots._update=function()
	foreach(shots.all, function(shot)
		shot.pos.x+=shot.dx
		shot.pos.y+=shot.dy
			
		if offscreen(shot.pos.x,shot.pos.y) then del(shots.all, shot) end
			
		if shot.update then shot.update(shot) end
	end)
end

shots._draw=function()
	foreach(shots.all, function(shot)
		shot.draw(shot)
	end)
	
end


--
-- level builder
--
	
level={
	id=1,
	load=function()
		level.all={}
		--level definitions
		--grow is expand min interval+50
		--spawn is spawn min interval+50
		--qty is hexes+1 (qty=2 == 3 hexes)
		
		
		-- 1
		add(level.all, {
			hexmax=10,mobmax=4,beemax=0,grow=100,spawn=90,hives={},
			seeds={
				{offset=0,qty=20,row=2},
			}
		})

		--2
		add(level.all, {
			hexmax=20,mobmax=6,grow=100,spawn=60,
			seeds={
				{offset=0,qty=7,row=2},
				{offset=12,qty=7,row=2},
				{offset=5,qty=10,row=3},
			},
			hives={},
			beemax=0
		})

		--3
		add(level.all, {
			hexmax=30,mobmax=8,grow=100,spawn=50,
			seeds={
				{offset=0,qty=20,row=2},
				{offset=0,qty=20,row=3},
			},
			hives={60},
			beemax=1
		})

		--4
		add(level.all, {
			hexmax=26,mobmax=8,grow=100,spawn=45,
			seeds={
				{offset=0,qty=7,row=2},
				{offset=12,qty=7,row=2},

				{offset=1,qty=6,row=3},
				{offset=13,qty=6,row=3},
			},
			hives={24,90},beemax=2
		})
			
		--5
		add(level.all, {
			hexmax=24,mobmax=8,grow=75,spawn=90,
			seeds={
				{offset=6,qty=7,row=4},
				{offset=7,qty=5,row=2},
				{offset=0,qty=3,row=2},
				{offset=16,qty=3,row=2},
			},
			hives={24,90},beemax=3
		})
			
		--6
		add(level.all, {
			hexmax=45,mobmax=8,grow=110,spawn=50,
			seeds={
				{offset=0,qty=20,row=2},
				{offset=0,qty=20,row=3},
				{offset=0,qty=20,row=4},
			},
			hives={20,60,90},beemax=3
		})
			
		--7
		add(level.all, {
			hexmax=30,mobmax=8,grow=100,spawn=80,
			seeds={
				{offset=1,qty=0,row=2},{offset=1,qty=0,row=3},{offset=1,qty=0,row=4},
				{offset=1,qty=0,row=5},{offset=1,qty=0,row=6},
						
				{offset=4,qty=0,row=2},{offset=4,qty=0,row=3},
				{offset=4,qty=0,row=4},{offset=4,qty=0,row=5},
				{offset=4,qty=0,row=6},
						
				{offset=9,qty=1,row=2},{offset=9,qty=1,row=3},
				{offset=9,qty=1,row=4},{offset=9,qty=1,row=5},
				{offset=9,qty=1,row=6},
						
				{offset=15,qty=0,row=2},{offset=15,qty=0,row=3},
				{offset=15,qty=0,row=4},{offset=15,qty=0,row=5},
				{offset=15,qty=0,row=6},
						
				{offset=18,qty=0,row=2},{offset=18,qty=0,row=3},
				{offset=18,qty=0,row=4},{offset=18,qty=0,row=5},
				{offset=18,qty=0,row=6},
			},
			hives={18,83},beemax=2
		})
			
		--8
		add(level.all, {
			hexmax=32,mobmax=10,grow=95,spawn=70,
			seeds={
				{offset=0,qty=7,row=2},
				{offset=12,qty=7,row=2},
				{offset=5,qty=10,row=4},
				{offset=0,qty=7,row=5},
				{offset=12,qty=7,row=5},
			},
			hives={18,36,70,95},beemax=3
		})
			
		--9
		add(level.all, {
			hexmax=45,mobmax=8,grow=110,spawn=50,
			seeds={
				{offset=0,qty=20,row=2},
				{offset=0,qty=20,row=4},
				{offset=0,qty=20,row=6},
			},
			hives={24,68,90},beemax=3
		})
			
			
		--10
		add(level.all, {
			hexmax=60,mobmax=10,grow=130,spawn=70,
			seeds={
				{offset=0,qty=20,row=2},
				{offset=0,qty=20,row=3},
				{offset=0,qty=20,row=6},
				{offset=0,qty=20,row=5},
			},
			hives={20,60,90},beemax=4
		})
			
		
			
	end,
	random=function()
		player.score=shr(level.id,16)
		local settings={mobmax=6,hexmax=20,grow=100,spawn=60,hives={},beemax=0,seeds={}}
		local limit=mid(level.id,6,2)
		local offsetmax=12
		local hexmin=4
			
		if level.id>7 then
			local pos=random(16,90)
			settings.hives={pos}
			settings.beemax=1
		end
			
		if level.id>12 then
			settings.mobmax=8
			settings.hexmax=30
			settings.beemax=2
			offsetmax=10
		end
			
		if level.id>16 then
			settings.hexmax=40 
			settings.grow=80
			settings.spawn=30
			offsetmax=5
			hexmin=7
			settings.hives={34,85}
			settings.beemax=2
		end
		
		for n=2,limit do
			local offset=random(1,offsetmax)
			local hexes=random(hexmin,(19-offset))

			add(settings.seeds,{offset=offset,qty=hexes,row=n})
		end
			
		return settings
	end,
	set=function(v)
		level.id=v
			
		if endless then
			-- endless mode, get random level config
			level.current=level.random()
			return true
		else 
			-- challenge mode, just go in order of array
			if level.id>#level.all then
				return false
			else
				level.current=level.all[level.id]
				return true
			end
		end
	end,
	next=function()
		level.id+=1
		return level.set(level.id)
	end
}
	

	

--
-- game mode
--
game={t=0}

game._init=function(endlesson)
	-- clear things
	endless=endlesson
	if endlesson then
		level.set(1) 
	end
		
	--level.set(10)
		
	extralife=false
	fireworks={}
	powerup.all={}
	
	game.clear()
	play_music(22)	
	
    cart._update=game._update
    cart._draw=game._draw
end

game._update=function()
    player._update()
	smoke._update()
	powerup._update()
	fireworks_update()
		
	if game.t>=80 then -- adds wait before level start after showing text
		mobs._update()
		bees._update()
		shots._update()
		hives._update()
		hexes._update()
		
		if #hives.all<=0 and #mobs.all<=0 and #bees.all<=0 and #hexes.all<=0 then
			if endless then
				-- endless, just load another random
				if level.next() then game.clear() end
			else
				-- challenge mode
				if level.next() then
					game.clear()
				else
					boss._init()	
				end
			end
		end
	end
	
	-- give extra life after killing 200 bees
	if killcount==200 and not extralife then
		sfx(19)
		player.lives+=1
		extralife=true
	end
		
	game.t+=1
end

game._draw=function()
	map(0,0, 0,0, 16,16)
	local wait=90
	if level.id==1 then wait=150 end
		
	-- all levels >=2 get quick id text
	if game.t<wait then
		c=7
		
		if game.t>(wait-8) then c=6 end --fades out text
		if game.t>(wait-4) then c=5 end
		
		
		if level.id==1 then
			--
			--center_text("\142 or z to shoot\n\151 or x to blow smoke",75,c)
				center_text("\142 or z to shoot",60,c)
				center_text("\151 or x to blow smoke",68,c)
				center_text("clear screens to advance",85,c)
		else
			center_text("level "..level.id,60,c)	
		end
	end		
	
	if game.t>=81 then
		hives._draw()
		hexes._draw()
		
		mobs._draw()
		bees._draw()
	end
    
    
	powerup._draw()
	
	player._draw()
	fireworks_draw()
	shots._draw()
	smoke._draw()
	
	
	
end
	
game.clear=function()
	shots.all={}
	player.bullets={}
	smoke.all={}
	
    game.t=0
	
	
	mobs._init()
	bees._init()
	hives._init()
	hexes._init()
end	


--
-- title screen
--
titlescreen={
	_init=function()
		mobs._init()
			
		endless=false
			
		level.load()
		level.set(1)
			
		titlescreen.state(1)
		play_music(45)
			
		cart._update=titlescreen._update
		cart._draw=titlescreen._draw
	end,
	
	--state: 1=main menu, 2=directions, 3=unlock message
		
	_update=function()
			
		-- main menu
		if titlescreen.st==1 then
			if titlescreen.menu==3 then
				if btnu then titlescreen.menu=2 end
			elseif titlescreen.menu==2 then
				if btnu then titlescreen.menu=1 end 
				if btnd then titlescreen.menu=3 end
			elseif titlescreen.menu==1 then
				if btnd then titlescreen.menu=2 end
			end
				
			-- action
			if btnap then
				if titlescreen.menu==1 then
					game._init() -- start game
				elseif titlescreen.menu==3 then 
					titlescreen.state(2) -- go to directions
				elseif titlescreen.menu==2 and endlessunlocked<1 then
					titlescreen.state(3) -- go to endless locked message
				elseif titlescreen.menu==2 and endlessunlocked>0 then 
					game._init(true) -- start endless mode
				end
			end
				
			if btnbp then
				if musicon then musicon=false music(-1) else musicon=true play_music(45) end
			end
		end
			
		--directions
		if titlescreen.st==2 then
			if btnap then titlescreen.menu+=1 end
			if titlescreen.menu>5 then titlescreen.state(1) end
		end
			
		if titlescreen.st==3 then
			if btnap and titlescreen.t>30 then titlescreen.state(1) end
		end
			
			
			
		-- toss in a bee
		if titlescreen.t==180 then
			if #mobs.all<3 then mobs.spawn(0,75) end
			titlescreen.t=0
		end
			
		mobs._update()
			
		titlescreen.t+=1
	end,
	
	_draw=function()
		map(0,0, 0,0, 16,16)
		
		mobs._draw()
		
		-- title menu
		if titlescreen.st==1 then
			local textc=5
			map(16,0, 30,10, 9,7) --logo	
			
			if titlescreen.menu==1 then textc=7 else textc=5 end	
			center_text("\148 challenge mode",71,0)
			center_text("\148 challenge mode",70,textc)

			if titlescreen.menu==2 then textc=7 else textc=5 end
			center_text("\147 endless mode",81,0)	
			center_text("\147 endless mode",80,textc)

			if titlescreen.menu==3 then textc=7 else textc=5 end
			center_text("how to play",91,0)
			center_text("how to play",90,textc)
			
			if musicon then 
				mcolor=11
			else
				mcolor=5
			end
				
			print("\151\141",110,98,0)
			print("\151\141",110,97,mcolor)
				
			center_text("\148"..getscoretext(highscore).." \147"..getscoretext(endlesshigh),118,7)
		end
			
		-- how to play
		if titlescreen.st==2 then
				
			if titlescreen.menu==2 then
				print("how to play",10,15,10)
				
				print("press \142 or z to shoot\npress \151 or x to blow smoke",10,30,7)
				
				print("clear all bees, hives and\nhoneycombs to advance levels.",10,50,7)
	
				print("attacking reduces power.\n\npower regenerates when\nyou're not attacking.",10,70,7)
			end
				
			if titlescreen.menu==3 then
				print("how to play",10,15,10)
				
				print("destroy honeycombs when\nthey're frozen.",10,30,7)
				print("use smoke to freeze\nhoneycombs.",10,50,7)
					
				print("smoke will also slow down\nsmall bees and block their\nshots.",10,70,7)
			end
				
			if titlescreen.menu==4 then
				print("how to play",10,15,10)
					
				print("extra life awarded when you\nkill 200 bees.",10,30,7)
					
				print("collect power-ups to help.",10,50,7)
					
				spr(3, 10,60)
				print("unlimited power",22,61,7)
					
				spr(4, 10,70)
				print("freeze all honeycombs",22,71,7)
					
				spr(5, 10,80)
				print("honeycomb bomb",22,81,7)
			end
				
				
			if titlescreen.menu==5 then
				print("buzzkill v"..version,10,15,10)
				
				print("design, code & art by\nbrian vaughn\n@morningtoast",10,30,7)
					
				print("music by\n@robbyduguay and @guerragames",10,58,6)
					
				print("please also try\nbunyan's rage and mass360",10,78,12)
			end
				
			--print("you must freeze honeycombs\nwith smoke to destroy them.",10,65,7)
			
			center_text((titlescreen.menu-1).."/4",98,7)
			
				
			--print("attacking uses power.\npower regenerates when idle.",10,85,6)
		end
			
		--endless unlock
		if titlescreen.st==3 then
			center_text("complete challenge mode to",40,6)
			center_text("unlock endless mode",48,6)
		end
		
	end,
	state=function(s)
		titlescreen.st=s
		titlescreen.menu=1
		titlescreen.t=0
	end
}



--
-- game over
--
gameover={
	_init=function()
		gameover.t=0
		gameover.newhigh=false
		
		mobs._init()
		mobs.spawn(0,75)
		
		if endless then
			if player.score>endlesshigh then
				dset(2,player.score)
				endlesshigh=player.score
				gameover.newhigh=true
			end	
		else 
			if player.score>highscore then
				dset(0,player.score)
				highscore=player.score
				gameover.newhigh=true
			end
		end
			
		play_music(33)
			
		cart._update=gameover._update
		cart._draw=gameover._draw
	end,
	
	_update=function()
		if gameover.t>=45 and btnap then _init() end
		gameover.t+=1

		mobs._update()
	end,
	
	_draw=function()
		map(0,0, 0,0, 16,16)
				
		mobs._draw()
			
		if wasp.dead then
			center_text("\143 congratulations! \143",20,8)	
		else
			center_text("\150 game over \150",20,8)
		end
			
		center_text(killcount.." bees killed",35,6)
		center_text(hexkills.." honeycombs destroyed",44,6)
		
			
		center_text("final score",60,7)
		center_text(getscoretext(player.score),68,7)
			
		if gameover.newhigh then
			center_text("!! new high score !!",78,10)
		end
		
		if gameover.t>=45 then
			center_text("press "..char.btnz.." to continue",95,6)
		end
	end
}



--
-- loops
--
	
-- save pos: 0=highscore, 1=endlessunlock, 2=endlesshigh

cartdata("buzzkill1031")
function _init()
	--dset(0,0) dset(1,0) dset(2,0) -- clear memory
	--dset(1,1)
	highscore=dget(0)
	endlessunlocked=dget(1)
	endlesshigh=dget(2)
		
	player._init()
	titlescreen._init()
		
	killcount=0
	hexkills=0
end

function _update()
		debug(endlessunlocked)
	btnleft=btn(0)
	btnright=btn(1)
	btnd=btnp(3)
	btnu=btnp(2)
	btna=btn(4)
	btnb=btn(5)
	btnap=btnp(4)
	btnbp=btnp(5)
	
	cart._update()
	
	
	t+=1

end

function _draw()
	cls()
	
	-- make blue transparent
	palreset()
	
	cart._draw()
	
	
	
	--print(debugtext,100,0,7)
end




--
-- utility
--

function play_music(track)
	if musicon then music(track) end	
end
	

function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

function center_text(s,y,c) print(s,64-(#s*2),y,c) end

function is_even(n) 
	if (n%2==0) then return true else return false end
end

function draw_hitbox(obj)
	rect(obj.pos.x+obj.hitbox.x,obj.pos.y+obj.hitbox.y, obj.pos.x+obj.hitbox.w,obj.pos.y+obj.hitbox.h, 11)
end

function palreset()
	pal()
	palt(0, false)
	palt(13, true)
end



function in_table(tbl, element)
  for _, value in pairs(tbl) do
    if value == element then
      return true
    end
  end
  return false
end

function offscreen(x,y)
	if (x<screen.x-8 or x>screen.w or y<screen.y-8 or y>screen.h) then 
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
   if (val<=0)  s = "0"..s
   return s 
end 

		

--
--smoke class
smoke={all={},t=0}
smoke.make=function(x,y,init_size)
	local s={}
	s.x=x
	s.y=y
	s.width=init_size
	s.width_final=init_size+rnd(5)+1 --max size of possible smoke
	s.t=0
	s.max_t=30+rnd(10) -- time before fire dies
	s.dx=(rnd(.8)*.8) -- horz variance
	s.dy=-rnd(.05) --speed of flames
	s.ddy=-.02
	--s.ddy=-.06 -- speed of smoke/fire
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
		sp.col=5 -- smoke color
	end
	if rnd(1)<.5 then
		sp.x-=sp.dx
	else 
		sp.x+=sp.dx
	end
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
		if s.col<8 or s.col>10 then
			circfill(s.x-1,s.y-1,s.width,0)
		end
		
		circfill(s.x,s.y,s.width,s.col)
		
	end)
end


--
-- fireworks explosion class
function p_create(x,y,color,speed,direction,grav)  
  p={}
  p.x=x
  p.y=y
  p.color=color
  p.dx=cos(direction)*speed
  p.dy=sin(direction)*speed
  p.t=0
  p.grav=grav
  return p
end

function fireworks_create(x,y,color,amount,grav)
	local amount=amount or 26
	local grav=grav or .6
	
    particules={}
    for i=1,amount do
      add(particules,p_create(x,y,color,2,rnd(1),grav))
    end
    add(fireworks,particules)
end

function fireworks_draw()
  for particules in all(fireworks) do
    for p in all(particules) do
      pset(p.x,p.y,p.color)
    end
  end
end

function fireworks_update()
  for particules in all(fireworks) do
    for p in all(particules) do
		p.dy+=p.grav    -- gravity
		p.y+=p.dy
			
		if (p.y>=screen.ground) then
			p.y=screen.ground
			p.t+=1
			
			if p.t>=60 then del(particules,p) end
		else
			p.x+=p.dx   -- update position
		end
	
      
	 
		if (p.x>screen.w or p.x<screen.x) del(particules,p) -- and del it if under the horizon
    end
  end
end




__gfx__
00000000ddd9ddddddd77dd7daaaaaaddaaaaaaddaaaaaad0000000000000000dddd44dddddddddddddddddddddddddddddddddddddddddd0000000000000000
00000000dd9a9ddddddd7d77a000000aa000000aa000000a0000000000000000ddddd444dddddddddddd0dddddddddddddddddd0dddddddd0000000000000000
00000000d924a9ddd00a07dda007700aa070070aa000700a0000000000000000dd444f9f777fddddddddd0000dddddddddd0000ddddddddd0000000000000000
0000000092444a9d00aa0adda077770aa007700aa077770a0000000000000000d44f4944ffff7dddddddddddd00dddddd00ddddddddddddd0000000000000000
0000000092444a9d800a0a0da007700aa007700aa077700a000000000000000044929f9ff44fffddddddddddddd0dddd0ddddddddddd777d0000000000000000
0000000092444a9d0dddaa0aa077770aa070070aa077700a00000000000000004244f44ffffff7dd777ddddddd000000000dddddddd7777d0000000000000000
0000000092444a9dd0ddd00aa000000aa000000aa000000a000000000000000044294ffffffff7dd7777dddddd990000099ddddddd77777d0000000000000000
0000000092444a9ddddddddadaaaaaaddaaaaaaddaaaaaad0000000000000000d442f94f44fff7dd77777ddddd8aa000aa8dddddd777777d0000000000000000
ddd22ddd92444a9dd9dddddd000000000000000000000000ddddddddddddd777d4494fffffffffdd777777ddd888aaaaa888dddd777777dd0000000000000000
dd2822dd92444a9d94addddd000000000000000000000000d00d777dddd7777ddd429f4f2fff7dddd777777dd888aaaaa888dd770077dddd0000000000000000
dd2292ddd924a9dd98addddd000000000000000000000000ddd0d777dd7777dddd4492f200ff7dddddd77777708a0aa0aa8dd7007d0ddddd0000000000000000
dd2a22dddd9a9ddd94addddd00000000000000000000000000dd0ddaa777ddddddd444f200f7ddddddddd0077709099090070077ddd0dddd0000000000000000
ddd22dddddd9dddddadddddd000000000000000000000000dd00800aa000aadddddd499f2f7ddddddddd0dd070000990000077d000dddddd0000000000000000
ddd2dddddddddddddddddddd000000000000000000000000ddd0800aa000aa0dddddd42fffddddddddd0ddd000d000009999000ddd0ddddd0000000000000000
dddd2ddddddddddddddddddd000000000000000000000000dd0000a0000a000ddddddd44fddddddddd0ddd0d0ddd0009aaa00ddddd00dddd0000000000000000
ddd2dddddddddddddddddddd000000000000000000000000ddd0dda00aa000adddddddddddddddddddddd0ddd0dd999aaa000000ddd0dddd0000000000000000
b3bb3bbb3111313111111111d00000000000000000000000dddddd000aa00aad0000000000000000ddddd0ddd0dddaaaaaaddddd0ddd0ddd0000000000000000
333333331313111322222222dd00000d0000000000000000dddddddd0dd0d0dd0000000000000000dddd0dddd0ddd000000ddddd0ddd0ddd0000000000000000
444444443111311122222222ddd000dd0000000000000000ddddddd0dd0d0ddd0000000000000000dddd0ddddd0ddd000000dddd0ddd0ddd0000000000000000
444444421131113188888888dd00000d0000000000000000ddddddd0d0dd0ddd0000000000000000dddd0ddddd0ddd999999dddd0ddd0ddd0000000000000000
424444241111111188888888d0a0a0a00000000000000000ddddddd0dd0dd0dd0000000000000000dddddddddd0dddaaaaaaaddd0ddddddd0000000000000000
244424441111111199999999d09090900000000000000000dddddddddddddddd0000000000000000ddddddddd0ddd00000000ddd0ddddddd0000000000000000
424242421111111199999999d00000000000000000000000dddddddddddddddd0000000000000000ddddddddd0dd0000000000ddd0dddddd0000000000000000
2424242411111111aaaaaaaad0ddddd00000000000000000dddddddddddddddd0000000000000000dddddddddddd9999999999ddd0dddddd0000000000000000
2222422211111111bbbbbbbb00000000000000000000000000000000000000000000000000000000ddddddddddddaaaaaaaaaadddddddddd0000000000000000
24222242111111113b3b33b300000000000000000000000000000000000000000000000000000000ddddddddddddd00000000ddddddddddd0000000000000000
222222221111111133b33b3300000000000000000000000000000000000000000000000000000000ddddddddddddd00000000ddddddddddd0000000000000000
22122122111111113333333100000000000000000000000000000000000000000000000000000000ddddddddddddddaaaaaddddddddddddd0000000000000000
21222212111111113b3313b300000000000000000000000000000000000000000000000000000000dddddddddddddd00000ddddddddddddd0000000000000000
12221222111111113313333100000000000000000000000000000000000000000000000000000000ddddddddddddddd000dddddddddddddd0000000000000000
21212121111111113133313300000000000000000000000000000000000000000000000000000000dddddddddddddddd0ddddddddddddddd0000000000000000
11111111111111111313131300000000000000000000000000000000000000000000000000000000ddddddddddddddd0dddddddddddddddd0000000000000000
dddddddddddddddddddddddddddaaaaaaaadddddddddddaaaaaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddaaaaaaaaaaaddddddaaaaaaaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddaaaaaddddaaaaaaaaaaaaddddaaaaaaaaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddaaaaaaaaddddaaaaaaaaaaaaaaaaaaaaaaaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
ddddddddaaaaddddaaaaaaaaaaddaaaaaaaaaaaaaaaaaaaaaaaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
ddaaaaaaaaaaaaddaaaaaaaaaaadaaaaaaaaaaaaaaaaaaaaaaaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
daaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa888888aaaaa888888aaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaaaaaaaa888888aaaaaaaaaaaaaaaaa8888888aaaa88888888aaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aa8aaaaaaaaaaaaaaaaaaaaaaaaaaaaa8888888aaaa88888888aaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaaaaaaa88aaaaaaaaaa888aaaaaaaa8888aaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaa8888aaa888aaaaaaaa8888aaaaaaa88888aaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa8888888888aaaa8888aaa888aaaaaaaa8888aaaaaaa8888aaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa88888888888aaa8888aaa888aaaaaaa8888aaaaaaa8888aaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa88888888888aaa8888aaa888aaaaaaa8888aaaaaaa8888aaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa8888aaa8888aaa8888aaa888aaaaaa88888aaaaaa88888aaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa8888aaaa888a8a8888aaa888aaaaaa8888aaaaaaa8888aaaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa8888aaa8888a8a8888aaa888aaaaa8888aaaaaaa8888aaaaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa8888888888aa8a8888aaa888aaaaa8888aaaaaaa8888aaaaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa88888888888aaa8888aaa888aaaa8888aaaaaaa8888aaaaaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
a8a888888888888aa8888aaa888aaaa8888aa8aaaa8888aa8aaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa8888aaaa8888aa8888aaa88aaaaa888aaaaaaaa888aaaaaaadddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
aaa8888aaaa8888aaa888aaa88aaaa8888aaaaaaa8888aaa8aaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
daa888888888888aaa8888aa88aaaa888aaaaaaaa888aaaaaaaaaddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
daa88888888888aaaa88888888aaa88888888aaaa88888888aaaa88dddddddd888dddddd00000000000000000000000000000000000000000000000000000000
daa88888888888adaa88888888aaa88888888aaaaa8888888aaaa8888dddd8888888dddd00000000000000000000000000000000000000000000000000000000
ddaaaaaaaaaaaaddaaa8888888aaaaa888888aaaaa8888888aaaa8888dd888888888dddd00000000000000000000000000000000000000000000000000000000
ddaaaaddddddddddaaaa88888aaaaaaaaaaaaaaaaaaaaaaaaaaaa8888888888888888ddd00000000000000000000000000000000000000000000000000000000
ddaadddddddddddddaaaaaaaaaaaaaaaa888aaaaaaaa888aaaaa888888888888888888dd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddaaaaaaaaa888888888aaaa8888888aaaa8888888888888888888dd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddaaddddd88888888888888aaaa8888888888888888888888888dd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd88888888888888aaaa88aaa888888888aaaa8888888dd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd88888888888888aaaa88aaaa88888888aaaaa888888dd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaa888aaaa8aaaa88aaaa888888888aaaa888888dd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaa888aaaa8aaaa88aaaa888888888aaaa8888888d00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaa88aaaa88aaaa88aaaa888888888aaaa8888888d00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaa88aaaa88aaaa88aaaa888888888aaaa8888888d00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaa88aaaa888aaaa88aaaa888888888aaaa8888888d00000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaa88aaa88888aaa88aaaa888888888aaaa8888888800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaa8aaaa88888aaa88aaaaa88888888aaaaa888888800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaaaaaaa8888a8aa88aaaaa88888888aaaaa888888800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaaaaaaa88888aaa888aaaa888888888aaaa888888800000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaaaaaaa8888aaaa88aaaa888888888aaaa888888800000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaaaaaaa888aaaaa88aaaa888888888aaaa888888800000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaa8aaaa8888aaaa88aaaa888888888aaaa888888800000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaaa8aaaa8888aaaa88aaaa888888888aaaa888888800000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd8aaaa8aaaaaa888aaaa88aaaa888888888aaaa888888800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaaa88aaaa888aaa888aaaaa88aaa888aaaaa88aaa800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaaa88aaaa888888888aaaaaaaaaa888aaaaaaaaaa800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaa888aaaa8888888888aaaaaaaaaa888aaaaaaaa8800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaa8a8aaaa888dddd888aaaaaaaaaa888aaaaaaaa8800000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddd88aaaa8888aaaa88dddd888aaaa88888a888aaaa88888d00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddd88aa888aa888888ddddd888888888dd88888888888ddd00000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddddd888888888888ddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddd888ddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
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
3232323232323232323232323232323240414243444546000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2121212121212121212121212121212150515253545556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313160616263646566676800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313170717273747576777800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000083848586878800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000093949596979800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
31313131313131313131313131313131000000a3a4a5a6a7a800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3131313131313131313131313131313100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2222222222222222222222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2020202020202020202020202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c0020102451c0071c007102351c0071c007102251c007000001022510005000001021500000000001021013245000001320013235000001320013225000001320013225000001320013215000001320013215
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100003b6573a057396573665732650306502d6402964025640236401f6401b6401762014620116200e6200a6200962006620056200361002610016000162012600116000f6000c6000a600086000660004600
000500003e0603a06035050300502b04027030220301e0301a03016030120300c0300803003020010100b0000800005000030000100001000110000f0000e0000c0000a000090000700005000030000200001000
000200001533017330183401a3401c3401d3502036024370273702e37023300243002630027300293002b300187000f7000f700137001670010700197001b700107000f7001170014700177001a7000f7000c700
000200000e72011720157401b7401f740000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0003000025640206401d6401b64018640166401364011640106400e6400d6400c6400b6400a640096400864007640066400564004640036400264002640026400164001640016300163001620016100161001610
00030000221401f1401b14016140111400b1200712003120026000260002600026000a7000a7000a7000a7000b7000b7000b7000b7000b7000b7000c7000c7000c7000c7000c7000c7000c7000c7000c7000c700
000200001f6601c6601a66016660126600f6600d6600d6500e6501065012650126500f6500d6500c6500c6400c6400d6400e630106300e6200b62008610066100560004600016000160000000000000000000000
00020000302702f2702d2702b2702a2702727025270212701d2701a27016270112700d2700b27014670126700f6700d6700b6700a670096700867008640086400864008630086300763005630026300163002630
000200002657024570215701a5601d5601a560195601756015560125600f5600c560095600656003560015601c1001d100101001f100061000000000000000000000000000000000000000000000000000000000
000200000254002540015400154000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00040000263742637432374323743737437374373743937439374393743937428400284003f0003f0003f0003f0003f00032700357002b7002a0002a0002a0002a0002a0002a0002a0002e70023700374001e600
0002000037660366603466032650306502d6500464029640256400464020640046401b6400464004640156401064004640076300663005630056300463004630046300463004650056500a6500c6301263018620
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011e00200c505155351853517535135051553518535175350050015535185351a5350050515535185351a53500505155351c5351a53500505155351c5351a53500505155351a5351853500505155351a53518535
010f0020001630020000143002000f655002000020000163001630010000163002000f655001000010000163001630010000163002000f655002000010000163001630f65500163002000f655002000f60300163
013c002000000090750b0750c075090750c0750b0750b0050b0050c0750e075100750e0750c0750b0750000000000090750b0750c0750e0750c0751007510005000000e0751007511075100750c0751007510005
013c00200921409214092140921409214092140421404214022140221402214022140221402214042140421409214092140921409214092140921404214042140221402214022140221402214022140421404214
013c00200521405214052140521404214042140721407214092140921409214092140b2140b214072140721405214052140521405214042140421407214072140921409214092140921409214092140921409214
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
015000200706007060050600506003060030600506005060030600306005060050600206002060030600306007060070600506005060030600306005060050600306003060050600506007060070600706007060
01280020131251a1251f1251a12511125181251d125181250f125161251b125161250e125151251a125151250f125161251b1251612511125181251d125181250e125151251a125151251f1251a125131250e125
01280020227302273521730227301f7301f7301f7301f7352473024735227302273521730217351d7301d7351f7301f7352173022730217302173522730247302673026730267302673500000000000000000000
012800202773027735267302473524730247302473024735267302673524730267352273022730227302273524730247352273021735217302173021730217351f7301f7301f7301f7301f7301f7301f7301f735
015000200f0600f0600e0600e060070600706005060050600c0600c060060600606007060090600a0600e0650f0600f0600e0600e060070600706005060050600c0600a060090600206007060070600706007065
012800200f125161251b125161250e125151251a12515125131251a1251f1251a12511125181251d125181250f125161251b125161250e125151251a12515125131251a1251f1251a125131251a1251f1251a125
012800201a5201a525185201a525135101351013510135151b5201b5251a5201a525185201852515520155251652016525185201a52518520185251a5201b520155201552015520155251f5001f5001f5001f505
012800201f5201f5251d5201b525155101551015510155151d5201d5251b5201d5251a5101a5101a5101a5151b5201b5251a5201a52518520185201552015525165201652016520165251a5001a5001a5001a505
010d0000234222242221422204221f422204222142222422234222242221422204221f422244222342222422234222242221422204221f422204222142222422234222242221422204221f422244222342222422
010d00001733017300153000000000000000000000000000173300000000000000001333000000000000000017330000000000000000000000000000000000001733000000000000000000000000000000000000
010d00001723017200153000000013230000000000000000172300000000000000001323000000000000000017230000000000000000132300000000000000001723000000000000000013230000000000000000
010d0000294222842227422264222542226422274222842229422284222742226422254222a4222942228422294222842227422264222542226422274222842229422284222742226422254222a4222942228422
010d00001d230292000000000000000000000000000000001d230000000000000000192300000000000000001d2300000000000000000d2000000000000000001d23000000000000000019230000000000000000
010d00001d232292020000200002192320000200002000021d232000020000200002192320000200002000021d232000021d23200002192320000200002000021d2321d2021d2320000219232000021923200002
010d00000e5530e5030e5030e5030e5530e5030e5530d503155530e5030c5020c3020e5530c3020e5530c3020e5530c0020c6020c7020e5530c5020e5530e50315553135030e5530e5030e5530e5530e5530e553
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00200c133000000061500615176550000000615006150c133000000061500615176550000000615006150c133000000061500615176550000000615006150c13300000006150061517655000000061500615
0118002002070020700207002070040700407004070040700c0700c0700c0700c0700a0700a0700a0700a0700e0700e0700e0700e0700d0700d0700d0700d070100701007010070100700e0700e0700e0700e075
011800200000015540155401554015545115401154011540115451354013540135401354510540105401054010545115401154011540115451054010540105401054513540135401354013545095400954009545
0118002009070090700907009070070700707007070070700907009070090700907002070020700207002070030700307003070030700a0700a0700a0700a0700707007070070700707007070070700707007075
01180020000001054010540105401054511540115401154011545105401054010540105450e5400e5400e5400e545075400754007540075450e5400e5400e5400e54505540055400554005540055400554005545
__music__
01 08004243
00 08014300
00 03014300
00 02030500
00 02030500
00 03414300
00 08014500
00 03040500
00 03020500
00 03020500
02 08010706
01 0a4d0949
00 0a0d090c
00 0a4c0b4c
00 0a0d0e4e
02 0f4d0c09
01 10124316
00 11134316
00 10121416
00 11131516
00 12424316
02 13424316
01 19425b18
00 19175a18
00 19171a18
00 1b425c18
02 1a194318
01 1f1d5e60
00 1f1d5e20
00 1f1d4320
00 221d211e
00 231d211e
02 1c1d2444
01 25262744
00 292a2844
00 2526272b
02 292a282c
01 2d181e24
00 2d181e24
00 2d181e2e
00 2d181e2e
00 2d181e6e
02 2d181e6e
01 2f454305
00 30424305
01 2d2e3344
00 2d2f3344
00 30313345
02 30323345
00 31344344
00 36354344
00 31343905
02 36353a05
01 3c423b41
00 3c423b44
00 3c3d3b44
00 3c3d3b44
00 3e523b41
00 3e423b41
00 3e3f3b44
00 3e3f3b44
00 3e013b41
02 3e013b41
00 41424344

