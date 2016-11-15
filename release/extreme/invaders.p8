pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--invader overload
--brian vaughn, 2016
--@morningtoast

-- a tribute to space invaders extreme by taito

-- music by brian follick, @gnarcade_vgm

-- backgrounds by the pico-8 community tweetjams
-- http://www.lexaloffle.com/bbs/?tid=3726

--[[
   _____  ___   _____   ___  _______    ____ _   _________  __   ____  ___   ___ 
  /  _/ |/ / | / / _ | / _ \/ __/ _ \  / __ \ | / / __/ _ \/ /  / __ \/ _ | / _ \
 _/ //    /| |/ / __ |/ // / _// , _/ / /_/ / |/ / _// , _/ /__/ /_/ / __ |/ // /
/___/_/|_/ |___/_/ |_/____/___/_/|_|  \____/|___/___/_/|_/____/\____/_/ |_/____/ 
                                                                                 
]]


--
-- add your own background to the game
--
-- 1. copy the template object below and give it a new name
-- 2. add your code to the draw() method
-- 3. if you need to predefine variables for your background, use the load() method.
-- 4. then add the background name to the 'list' array
-- 5. customize the other level colors using the variable key below

-- other background colors:
-- color=solid full background
-- mfg=invader foreground
-- mbg=invader background
-- hfg=score foreground
-- pbg=player background (checker strip)

-- notes:
-- the background.t variable is the ticker and is already available
-- do not include srand() in your background code. instead, use load() to 
--   populate an array with random numers and then call them in your loop


background={t=0,
	list={"grid","balls","flurry","flight","ballspiral","circles","rainbow","spiral"}, --order of backgrounds in game

	--[[
	-- template for background, copy/paste and rename to use your own background
	example={
		color=0, --solid background color
		mfg=7, --invader color, foreground
		mbg=2, --invader background color
		hfg=1, --score text color
		pbg=8, --player background strip color
		
		load=function() --use for anything your draw code needs existing
			for n=1,500 do add(background.rand, rnd(9)) end
		end,
		draw=function() --draw loop
			for i=1,500 do
				p=9-i/50
				j=(p+sin(background.t)-background.t*9)%11+.1
				k=background.rand[i]-5+cos(background.t)
				if flr(p)==7 then p=14 end
				circfill(k/j*50+64,80/j-20,9/j,p)
			end
			background.t+=.01
		end
	},
	]]
	
	-- flurry balls, by kometbomb
	flurry={
		color=0,mfg=7,mbg=0,
		hfg=15,pbg=1,
		load=function()
			for n=1,256 do add(background.rand, rnd(128)) end
			for n=1,256 do add(background.rand2, rnd(128)) end
		end,
		draw=function()
			p={1,1,13,13,2,14,6}
			for i=1,256 do
				z=flr(i/40+1)
				circfill((background.rand[i]-time()*z*z)%140-8,background.rand2[i],z,p[z])
			end
		end
	},

	-- roaming ball field, by nusan
	balls={
		color=0,mfg=7,mbg=2,
		hfg=1,pbg=8,
		load=function()
			for n=1,500 do add(background.rand, rnd(9)) end
		end,
		draw=function()
			for i=1,500 do
				p=9-i/50
				j=(p+sin(background.t)-background.t*9)%11+.1
				k=background.rand[i]-5+cos(background.t)
				if flr(p)==7 then p=14 end
				circfill(k/j*50+64,80/j-20,9/j,p)
			end
			background.t+=.01
		end
	},

	-- rainbow clouds
	rainbow={
		color=2,mfg=1,mbg=7,
		hfg=2,pbg=2,
		draw=function()
			m=12
			background.t+=0.05
			for n=0,m*m do
			x=n%m y=n/m
			circfill(x*12,y*12,12+4*cos(background.t+y/5)+4*sin(background.t+x/7),8+(x+y)%8)
			end
		end
	},

	-- rainbow spiral, by guerragames
	spiral={
		color=1,mfg=7,mbg=5,
		hfg=6,pbg=0,
		draw=function()
			s=64
			background.t+=.0001
			x=s y=s
			for i=1,350 do
				j=i*background.t
				u=x
				v=y
				x=x+j*sin(j)
				y=y+j*cos(j)
				line(u,v,x,y,7+i/60)
			end
			
			
		end
	},

	-- circle snowflake, by benjamin soulé
	circles={
		color=2,mfg=7,mbg=1,
		hfg=15,pbg=0,
		draw=function()
			
			background.t+=0.01 
			for k=0,16 do 
				for n=1,9 do 
					h=k/16+background.t 
					circ(64+cos(h+background.t/3)*n*8,64+sin(h)*(n*n+cos(background.t)*16),n,11-n/3)
				end 
			end
		end
	},

	-- spiral of balls, by zep
	ballspiral={
		color=9,mfg=0,mbg=7,
		hfg=4,pbg=4,
		draw=function()
			x=64 y=64 r=1 a=0
			for i=0,150 do
			if is_even(i) then c=14 else c=7 end
			 circfill(x,y, r/2,6+i%3)
			 x+=cos(a)*r y+=sin(a)*r
			 r+=1/4 a+=background.t/5
			end
			background.t+=0.002
		end
	},

	-- horizon grid, by electricgryphon
	grid={
		color=0,mfg=7,mbg=2,
		hfg=13,pbg=2,
		draw=function()
			w=127
			n=15

			background.t+=.75
			for i=0,n do
				z=(i*n+background.t%n)
				y=w*n/z+32
				line(0,y,w,y,8)
				v=i+background.t%n/n-n/2
				line(v*9+64,40,v*60+64,w,8)
			end
		end
	},

	-- horizon landing lights
	flight={
		color=0,mfg=7,mbg=1,
		hfg=4,pbg=5,
		draw=function()
			make=function(y,color)
				for i=0,n do
					z=(i*n+background.t%n)/1500
					for j=-n,n do
						c=sin(background.t/300)
						pset((j*.7+c)/z+y,(-j*c/9+c/3+1)/z+y,color)
					end
				end
			end
			
			n=16
			background.t-=2
			make(5,8)
			make(40,9)
			make(70,10)
		
		end
	},
	matrix={
		color=0,mfg=7,mbg=3,
		hfg=11,pbg=3,
		draw=function()
			for j=3,99 do
				c=11
				x=j*593
				for y=1,x%c do
					n=j^y%7+1
					print(sub("5&y$%z?$*",n,n),x%126,(background.t+x)*j/8%256-y*6,c)
					c=3
				end
			end
			background.t+=.7
		end
	},



-- not a background, do not alter below
	rand={}, --for random seeding
	rand2={}, --for random seeding
	load=function()	
		local bgp=background.list[stage.id]
		stage.current.background=background[bgp]
	
		background.rand={}
		background.rand2={}
		background.t=0 
		
		if stage.current.background.load then stage.current.background.load() end
	end,
}




--
-- globals
--
version="1.5" --updated 9/24/2016
t=0
screen={x=0,y=0,w=128,h=128}
char={btnz="\142",btnx="\151"}
musicon=true
autofire=false
--
-- cart container
-- used in system loops
--
cart={update=function() end,draw=function() end}





--
-- #player
--
player={
	
	hitbox={x=0,y=4,w=8,h=4},
	dx=0,
	dy=0,
	speed=2,
	interia=.3,
	st=1,
	t={p=0,z=0},
	zrate=8,
	dir=0,
	power={},
	weapon=0,
	weapontime=0,
	weaponmax=150,
	weaponcolor=0,
	fevermax=190,
	
	reset=function()
		player.state(1)
		player.fever=false
	end,
	
	
	load=function()
		powerup.all={}
		
		player.pos={x=55,y=119}
		player.power={}
		player.fever=false
		player.fevertime=0
		player.lives=3
		player.weapon=0
		player.weapontime=0
		player.score=shr(0,16)
		player.reset()
	end,
	
	_update=function()
		if player.st==1 then --normal
			player.move()
			player.action()
			player.collision()
			
		elseif player.st==2 then --hit/damage
			player.move()
			player.action()
			
			--duration of state before switching back
			if player.t.p>=45 then
				player.state(1)	
			end
		elseif player.st==3 then  --when player is dead, delay before game over
			if player.t.p>=75 then gameover._init() end
			player.t.p+=1
		end
		
		--decay of power weapon
		if player.weapon>0 then
			player.weapontime+=1
			if player.weapontime>=player.weaponmax then player.changeweapon(0) end
		end
		
		--decay of fever mode
		if player.fever then
			player.fevertime+=1
			if player.fevertime>=player.fevermax then 
				player.fever=false 
				player.fevertime=0
			end
		end
		
		player.t.p+=1
		

		--laser beam hitbox, empty if not active
		if player.fire then
			player.special={
				pos={x=player.pos.x,y=0},
				hitbox={x=0,y=0,w=6,h=127}
			}
		else
			player.special={pos={x=0,y=0},hitbox={x=0,y=0,w=0,h=0}}
		end
		
		bullets._update()
		meters._update()
	end,
	_draw=function()
		-- lives hud
		-- coins collected
		print("x"..player.lives, 2,112, stage.current.background.pbg)
		 
		
		
		
		-- match bar hud
		local y=82
		for n=1,3 do
			local icon="\152"
			local color=stage.current.background.pbg
			
			if player.power[n] then
				icon="\128"
				color=player.power[n]
			end

			print(icon, 2,y, color)
			y+=10
		end
		
		
		bullets._draw()
		
		
		
		--draw player
		if player.st==1 then
			spr(1, player.pos.x,player.pos.y)
			explodew=0
		elseif player.st>1 then
			--draw rectangle explosion when hit
			rect(player.pos.x-explodew,player.pos.y-explodew, player.pos.x+explodew,player.pos.y+explodew, 7)
			explodew+=12
			
			--flash player when hit and not death blow
			if player.st==2 then
				if is_even(player.t.p) then spr(1, player.pos.x,player.pos.y) end --flash after hit
			end
		end
	end,
	
	state=function(s)
		player.st=s
		player.t.p=0
		
		if player.st==3 then --clear bullets/laser when player dies
			player.fire=false
			bullets.all={}
		end
	end,
	changeweapon=function(w)
		player.weapontime=0
		player.weapon=w
		player.weaponcolor=0
		
		--base weapon
		if player.weapon==0 then
			player.zrate=8
		end
		
		-- green, machine gun
		if player.weapon==2 then
			player.zrate=4
		end
		
		-- red, bomb shot
		if player.weapon==3 then
			player.zrate=10
		end
		
		player.t.z=player.zrate-2
	end,
	move=function()
		
		
		player.dx*=player.interia
		player.dir=0
		
		if btnl or touch.left() then player.dir=-1 end --left
		if btnr or touch.right() then player.dir=1 end --right
		
		
		
		
		player.dx+=player.speed*player.dir
		
		local check=flr(player.pos.x+player.dx)
		
	    if check<=screen.w-player.hitbox.w and check>0 then player.pos.x+=player.dx end
	end,

	action=function()
		player.fire=false
		
		if autofire then btnz=true end
		
		if btnz and player.st<3 then -- z button
			
			--bullet shot, limited by fire rate	
			if (player.weapon==0 or player.weapon==2 or player.weapon==3) and player.t.z>=player.zrate then
				sfx(61)
				bullets.create(player.pos.x+3, player.pos.y+4)
				player.t.z=0
			end
			
			--laser beam power-up
			if player.weapon==1 then
				sfx(59)
				mobs.collide(player.special)
				player.fire=true
				player.t.z=0
			end
		end
		
		player.t.z+=1
	end,
	
	collision=function()
		foreach(shots.all, function(shot)
			if collide(shot,player) then player.hit() end
		end)
	end,
	
	hit=function()
		player.lives-=1
		
		sfx(63)
		
		if player.lives<=0 then
			player.state(3)
		else
			player.state(2)
			shots.all={}
		end
		
	end
}


-- #touchscreen left/right
-- touch.left() - returns TRUE if touching left side of screen
-- touch.right() - returns TRUE if touching right side of screen
touch={
	button=0,
	press={x=0,y=0},
	
	left=function()
		if touch.button>0 and touch.press.x<60 then
			return true
		else
			return false
		end
	end,
	right=function()
		if touch.button>0 and touch.press.x>70 then
			return true
		else
			return false
		end
	end,
	update=function()
		touch.button=0
		touch.press.x,touch.press.y=mouse.pos()
		touch.button=mouse.button()
	end
	
}


--
-- #meter
--
meters={fever=127,weapon=127,
	_update=function()
		if player.fever then
			local p=1-((player.fevertime/player.fevermax))
			meters.fever=flr(127*p)
		end
		
		if player.weapon>0 then
			local g=1-((player.weapontime/player.weaponmax))
			meters.weapon=flr(127*g)
		end
	end,
	_draw=function()
		if player.weapontime>0 then
			rectfill(0,120,meters.weapon,127, player.weaponcolor)
		end
		
		if player.fever then
			rectfill(0,0,meters.fever,7, 10)
		end
	end
}



--
-- #bullets
--
bullets={
	all={},
	_update=function()
		
		--non-beam weapons
		foreach(bullets.all, function(obj)
			obj.pos.y+=obj.dy
			
			mobs.collide(obj)
			
			if offscreen(obj.pos.x, obj.pos.y) then bullets.remove(obj) end		
		end)
	end,
	
	_draw=function()
		
		--non-beam weapons
		foreach(bullets.all, function(obj)
			-- normal shot
			if obj.weapon==0 then
				rect(obj.pos.x,obj.pos.y, obj.pos.x,obj.pos.y-3, 7)
				rect(obj.pos.x+1,obj.pos.y, obj.pos.x+1,obj.pos.y-3, 0)
			end
			
			--machine gun
			if obj.weapon==2 then
				spr(6, obj.pos.x,obj.pos.y)
			end
				
			--bomb shot
			if obj.weapon==3 then
				rectfill(obj.pos.x-2,obj.pos.y-2, obj.pos.x+2,obj.pos.y+2, 8)
			end
		end)
		
		--laser beam
		if player.fire and player.weapon==1 then
			line(player.pos.x,0, player.pos.x,player.pos.y, 1)
			line(player.pos.x+1,0, player.pos.x+1,player.pos.y+6, 12)
			line(player.pos.x+2,0, player.pos.x+2,player.pos.y+6, 12)
			line(player.pos.x+3,0, player.pos.x+3,player.pos.y+6, 7)
			
			line(player.pos.x+4,0, player.pos.x+4,player.pos.y+6, 12)
			line(player.pos.x+5,0, player.pos.x+5,player.pos.y+6, 12)
			line(player.pos.x+6,0, player.pos.x+6,player.pos.y+6, 1)
		end
	end,
	
	create=function(x,y)
		local obj={
			pos={x=x,y=y},
			weapon=player.weapon,
			dy=-4
		}
		
		
		-- normal 
		if player.weapon==0 then
			obj.hitbox={x=0,y=-4,w=1,h=4}
			obj.dy=-6
		end
		
		-- machine gun
		if player.weapon==2 then
			obj.hitbox={x=0,y=0,w=4,h=4}
			obj.dy=-8
		end
	
		-- bomb shot
		if player.weapon==3 then
			obj.hitbox={x=-2,y=-2,w=2,h=2}
			obj.dy=-5
		end
		
		add(bullets.all, obj)
	end,
	
	remove=function(obj)
		del(bullets.all, obj)	
	end
}






--
-- #ufo ship
--
ufos={t=0,spawn=60,active=false,current={pos={x=0,y=0}},score=5000,
	_update=function()
		if ufos.active then
			if ufos.current.pos.x>=screen.w then 
				ufos.kill()
			end	
			ufos.current.pos.x+=1
			
			--check against player bullets
			foreach(bullets.all, function(bullet)
				if collide(ufos.current, bullet) then
					ufos.die()
					ufos.kill()
					bullets.remove(bullet)
				end
			end)
			
			--check against laser beam
			if player.fire then
				if collide(ufos.current, player.special) then
					ufos.die()
					ufos.kill()
				end
			end
				
			
		end
	
		if ufos.t>=ufos.spawn then ufos.create() end
		ufos.t+=1
	end,
	_draw=function()
		if ufos.active then
			pal(7,stage.current.background.mbg)
			spr(18, ufos.current.pos.x+1,ufos.current.pos.y)

			pal(7,stage.current.background.mfg)
			spr(18, ufos.current.pos.x,ufos.current.pos.y)
			pal()
		end
	end,
	reset=function()
		ufos.spawn=random(150,240)
		ufos.t=0
	end,
	die=function()
		scorepop.add(ufos.score)
		if not player.fever then
			powerup.drop(ufos.current.pos.x,ufos.current.pos.y, 1,4) --always drop yellow block
		end
	end,
	kill=function()
		ufos.active=false
		ufos.reset()
	end,
	create=function()
		if not player.fever then
			ufos.active=true
			ufos.current={
				pos={x=-10,y=1},
				hitbox={x=0,y=0,w=8,h=6},
			}	
		end
		
		ufos.reset()
	end
}


--
-- #stages > levels
--

-- set 'advance' to set starting coin quota
stage={id=1,
	_init=function()
		stage.advance=25
		stage.current={shots=3,rowmax=3,advance=stage.advance}
		background.load()
		stage.wave()
	end,
	_update=function()
		if stage.collected>=stage.current.advance then
			boss._init()
		elseif #mobs.all<=0 then
			stage.wave()
		end
	end,
	_draw=function()
		if boss.active then
			center_text("\135"..flr(boss.hp), 110, stage.current.background.pbg)
		else
			center_text(stage.collected.."/"..stage.current.advance, 110, stage.current.background.pbg)
		end
	end,
	next=function()
		stage.id+=1
		
		stage.collected=0
		stage.advance+=25
		stage.current.advance=min(200, stage.advance)
		
		if stage.id>#background.list then stage.id=1 end --loop back to first background
		
		background.load()
		stage.wave()
	end,
	wave=function()
		mobs.all={}
		
		stage.current.shots=min(8,flr(stage.current.shots+.5))
		stage.current.rowmax=min(8, stage.current.rowmax+1)
	
		local ry=10
		local rx=10
		local spr={3,2,34,35}

		for n=1,stage.current.rowmax do --number of rows
			local layerid=random(0,12) --pick layer, 0=blank row
			local r=random(1,#spr)
			
			
			if layerid>0 then
				local thisrow=stage.layers[layerid]
				local thismob=spr[r]
				
				foreach(thisrow, function(slot)
					if slot>0 then 
						add(mobs.all, mobs.create(thismob, rx, ry) )
					end
					
					rx+=10
				end)
			end
			
			rx=10
			ry+=10
		end
		
		mobs._init()
	
	end,
	boss=function()
		stage.current={shots=3,rowmax=3,background=background.matrix,advance=0}
	end

}
stage.layers={
	{1,1,1,1,1,1,1,1,1,1,1}, --1  ###########
	{2,2,2,2,2,2,2,2,2,2,2}, --2  ###########
	{1,1,1,1,0,0,0,1,1,1,1}, --3  ####   ####
	{1,0,1,0,1,0,1,0,1,0,1}, --4  # # # # # #
	{0,1,0,1,0,1,0,1,0,1,0}, --5   # # # # #
	{1,1,1,0,0,0,0,0,1,1,1}, --6  ###     ###
	{0,0,1,1,1,0,1,1,1,0,0}, --7    ### ###
	{0,0,1,1,1,1,1,1,1,0,0}, --8    #######
	{0,1,1,0,1,1,1,0,1,1,0}, --9   ## ### ##
	{0,0,0,1,1,1,1,1,0,0,0}, --10_   #####   
	{0,1,1,1,0,0,0,1,1,1,0}, --11_ ###   ### 
	{0,1,1,1,1,1,1,1,1,1,0}, --12_ #########
}


--
-- #boss
--

-- state; 1=intro, 2=play, 3=outro
boss={st=1,count=.5,style=1,t=0,active=false,
	clear=function()
		shots.all={}
		mobs.all={}
		mobs.explode.all={}
		powerup.all={}
		player.fever=false
		bullets.all={}
	end,
	_init=function()
		player.changeweapon(0)
		player.fever=false
		player.fevertime=0
		
		boss.active=true
		boss.st=1
		boss.count=min(boss.count+.5, 4) --number of big mobs, no more than 4
		if boss.style==1 then boss.style=2 else boss.style=1 end

		if musicon then music(44) end
		
		boss.clear()
		stage.boss()
		boss.transition._init()
		boss.king._init()
		boss.mobs._init()
		
		cart.update=boss._update
		cart.draw=boss._draw
	end,
	_update=function()
		
		-- play
		if boss.st>1 then
			player._update()
			boss.king._update()
			boss.mobs._update()
			scorepop._update()
			powerup._update()
			
			-- check for all bosses being dead
			if #boss.king.all<=0 then
				
				boss.clear()
				boss.st=3
			end
		end
	end,
	_draw=function()
		if boss.st==1 then
			boss.transition._draw() --full intro
		end
		
		-- boss play world is always visible after intro, even after boss death; outro fade sits on top
		if boss.st>1 then
			play._draw()
			boss.mobs._draw()
			boss.king._draw()

			if boss.st==3 then
				if boss.transition.st==1 then
					boss.transition._init() --reset vars
					boss.transition.st=2
				end
				
				boss.transition.fade()
			end
		end
	end
}


-- transition animations
-- states: 1=sliding, 2=yellow circle, 3=black circle, 3=outro circles
boss.transition={
	_init=function()
		boss.transition.all={}
		boss.transition.ycirc=0
		boss.transition.bcirc=0
		boss.transition.st=1
		
        local posy=0
        for n=0,8 do
           add(boss.transition.all, {x=-128,y=posy,dir=1})
           posy+=16
        end
        
        posy=8
        for n=0,8 do
           add(boss.transition.all, {x=128,y=posy,dir=-1})
           posy+=16
        end		
	end,
	_draw=function()
		if boss.transition.st>1 then
           boss.transition.fade() 
        end
		
		if boss.transition.st<3 then --only show strips for state 1 and 2
	        -- slide in strips
			foreach(boss.transition.all, function(s)
				if boss.transition.st<3 then
					pal(6,10)
					map(0,0, s.x,s.y, 16,1)
					pal()
					
					s.x+=4*s.dir
					if s.dir>0 and s.x>=1 then 
						boss.transition.st=2 --state 2 when done sliding
						s.x=0 
						s.dir=0 
					end
				end
				
				palt(0,false)
				center_text("boss battle", s.y, 0)
				palt()
			end)
		end
	end,
	fade=function()
		
		circfill(64,64, boss.transition.ycirc, 10)

		--yello circle grows
		if boss.transition.st==2 then
			
			boss.transition.ycirc+=4
			if boss.transition.ycirc>=100 then boss.transition.st=3 end --state 3 when yellow circle done growing
		end
		
		--black circle grows, last animation before boss level
		if boss.transition.st==3 then
			palt(0,false)
			circfill(64,64, boss.transition.bcirc, 0)
			palt()
		
			boss.transition.bcirc+=5
			if boss.transition.bcirc>=100 then
				boss.transition.st=1
				
				if boss.st==1 then
					boss.st=2 --end of incoming transition, load up boss level
				end
				
				if boss.st==3 then --end of outgoing transition, load up next stage
					stage.next() --doesnt trigger anything
					play._init() --start next stage
					
				end
			end
		end
	
	end
}

-- boss level mob patterns
boss.mobs={t=0,
	_init=function() 
		boss.mobs.all={} 
		boss.mobs.raindir=1
	end,
	_update=function()
		if boss.style==1 then
			boss.mobs.wander()
		else
			boss.mobs.rain()
		end
	end,
	_draw=function() 
		mobs._draw() 
	end,
	
	-- falling rows
	rain=function()
		
		-- generate falling mobs every 2s
		if boss.mobs.t>=65 then
			boss.mobs.raindir*=-1
			local bx=random(1,4)
			for n=1,5 do
				local thismob=mobs.create(2, bx, 1)
				thismob.score=1500
			
				add(mobs.all, thismob)
				bx+=26
			end

			boss.mobs.t=0
		end
		
		boss.mobs.t+=1
		
		
		
		foreach(mobs.all, function(mob)
			mob.pos.x+=1*boss.mobs.raindir
			mob.pos.y+=2
			
			if boss.mobs.raindir>0 then
				if mob.pos.x>screen.w then mob.pos.x=0 end
			end
				
			if boss.mobs.raindir<0 then
				if mob.pos.x<screen.x then mob.pos.x=127 end
			end
				
			if mob.pos.y>screen.h then del(mobs.all,mob) end 
		end)
	end,
	
	-- random mob rain
	wander=function()
		-- generate falling mobs
		if boss.mobs.t>=20 then
			local thismob=mobs.create(2, random(16,115), 0)
			thismob.score=1500
		
			add(mobs.all, thismob)
			boss.mobs.t=0
		end
		
		boss.mobs.t+=1

		foreach(mobs.all, function(mob)
		
			--movement
			if mob.pos.y>=105 then mob.dir=0 end
			
			if mob.dir==0 then
				mob.dy+=1
			else
				mob.dx+=2*mob.dir
			end
			
			if mob.dx>=screen.w or mob.dx<=screen.x then
				mob.dir=mob.dir*-1
			end
			
			-- select which direction to move after going down
			mob.t+=1
			if mob.t>=12 then
				if mob.dir==0 then
					if rnd()<.5 then mob.dir=1 else mob.dir=-1 end
					if mob.dx>115 then mob.dir=-1 end
					if mob.dx<16 then mob.dir=1 end
				else
					mob.dir=0
				end
				mob.t=0	
			end
			
			mob.pos.x=mob.dx
			mob.pos.y=mob.dy
			
			if mob.pos.y>screen.h then del(mobs.all,mob) end
		end)		
	end

}

-- #king boss level big bosses
boss.king={
	_init=function()
		boss.king.all={}
		for n=1,flr(boss.count) do
			local bx=20
			local by=10
			local bdir=1
			
			if n==2 then bx=105 by=24 bdir=-1 end
			if n==3 then bx=90 by=10 bdir=-1 end
			if n==4 then bx=40 by=24 bdir=1 end
			
			add(boss.king.all, boss.king.create(bx,by, bdir))
		end
	end,
	_update=function()
		boss.hp=0
		foreach(boss.king.all, function(obj)
			boss.hp+=obj.hp
			obj.st=1
		
			--moving side to side
			obj.pos.x+=obj.speed*obj.dir
			
			if obj.pos.x>=screen.w-16 or obj.pos.x<=screen.x then obj.dir*=-1 end
			
			-- bullet collision
			foreach (bullets.all, function(bullet)
				if collide(bullet,obj) then
					obj.damage(bullet)
					bullets.remove(bullet)
				end
			end)

			--laser collision
			if player.fire then
				if collide(obj, player.special) then
					obj.damage()
				end
			end
							
			
			--shoot timer
			if obj.t>=obj.shoot then
				shots.boss(obj.pos.x+8,obj.pos.y, .75, 2) --x,y, dir, speed
				obj.t=0
			end
			
			obj.t+=1
		end)
		
		shots._update()
	end,
	_draw=function()
		foreach(boss.king.all, function(obj)
			pal(7,stage.current.background.mbg)
			spr(4,obj.pos.x+1,obj.pos.y, 2,2)
			pal()
				
			pal(7,stage.current.background.mfg)
			
			-- flash red when hit by player shot
			if obj.st==2 then pal(7,8) end
			
			spr(4,obj.pos.x,obj.pos.y, 2,2)	
			pal()
		end)
	end,
	create=function(x,y,dir,hp)
		if not hp then hp=50 end --default hp of boss unless overwritten
	
		local obj={
			pos={x=x,y=y},
			hitbox={x=0,y=0,w=16,h=16},
			t=0,
			dir=dir,
			hp=hp,
			st=1,
			speed=1,
			score=25000,
			shoot=random(40,80)
		}
		
		--get hp levels for speed increase
		obj.hurt1=obj.hp-flr(obj.hp*.55)
		obj.hurt2=obj.hp-flr(obj.hp*.75)

		obj.damage=function(bullet)
			if not player.fire then
				if bullet.weapon~=3 then
					obj.hp-=1 --bullet/laser
				else
					obj.hp-=5 --bomb damage (red)
				end
			else
				obj.hp-=.5
			end

			--health check
			if obj.hp<=0 then
				scorepop.add(obj.score)
				mobs.explode.create(obj.pos.x,obj.pos.y)
				del(boss.king.all, obj)
				
				if #boss.king.all<=0 then 
					music(-1)
					sfx(48) 
				end
			end
			
			-- get faster when hurt more
			if obj.hp<obj.hurt1 then obj.speed=2 end
			if obj.hp<obj.hurt2 then obj.speed=2.5 end
			
			obj.st=2
		end

		return obj
	end
}


--
-- #mobs
--
mobs={all={},t=0,dir=1,move=20,
	_init=function()
		mobs.t=0
		mobs.dir=1
		mobs.move=25
		
		mobs.fast=flr(#mobs.all/2)
		mobs.faster=flr(mobs.fast/2)
		mobs.fastest=max(3,flr(mobs.faster/2))
	end,
	_update=function()
		local mobdx=0
		
		-- adjust mob speed
		if #mobs.all<mobs.fast then mobs.move=10 end
		if #mobs.all<mobs.faster then mobs.move=4 end
		if #mobs.all<mobs.fastest then mobs.move=1 end
		
		-- mob direction
		if mobs.t>=mobs.move then
			if mobs.is_bump() then 
				mobs.dir*=-1
			end
			
			mobdx=(2*mobs.dir)
			
			mobs.t=0
		end
		
		
		-- move and shoot
		foreach (mobs.all, function(mob)
			mob.pos.x+=mobdx
				
			if mob.shoot.t>=mob.shoot.l then
				if #shots.all<flr(stage.current.shots) then --only shoot when there is less than n shots in play
					shots.create(mob.pos.x+4,mob.pos.y+4, .75)
				end
				mob.shoot.t=0
			end
			
			mob.shoot.t+=1
				
		end)
		
		mobs.t+=1
		
		shots._update()
	end,
	_draw=function()
		shots._draw()
		
		foreach (mobs.all, function(mob)
			pal(7,stage.current.background.mbg)
			
			spr(mob.spr, mob.pos.x+1,mob.pos.y)
			pal()
				
			pal(7,stage.current.background.mfg)
			spr(mob.spr, mob.pos.x,mob.pos.y)	
			pal()
		end)
		
		
		mobs.explode._draw()
	end,
	is_bump=function() --returns true if at edge of screen
		local reverse=false
		foreach (mobs.all, function(mob)
			if mob.pos.x+2>=screen.w-9 or mob.pos.x-2<=screen.x+1 then reverse=true end
		end)
		
		return reverse
	end,
	create=function(id,x,y)
		local obj={
			shoot={t=0,l=random(45,150)},
			pos={x=x,y=y},
			hitbox={x=0,y=0,w=8,h=6},
			spr=id,
			score=1000,
			dx=x,
			dy=0,
			dir=0,
			t=0,
		}
		
		return obj
	end,
	collide=function(bullet)
		foreach (mobs.all, function(mob)
			if collide(bullet,mob) then
				mobs.die(mob)
				mobs.kill(mob)
				bullets.remove(bullet)
			end
			
			if collide(mob,player) and player.st==1 then
				mobs.kill(mob)
				player.hit()
			end
		end)
		
	end,
	die=function(mob)
		sfx(60)
		mobs.explode.create(mob.pos.x,mob.pos.y)
				
		powerup.chance(mob)

		if player.fever then --when in fever mode, always drop coins
			powerup.drop(mob.pos.x,mob.pos.y, 5,4)
		end
	end,
	kill=function(mob)
		scorepop.add(mob.score)
		del(mobs.all,mob)
	end,
	explode={
		all={},
		_draw=function()
			foreach(mobs.explode.all, function(exp)
				
				--when non-bomb weapon, just a circle
				if exp.w~=3 then
					circ(exp.pos.x,exp.pos.y, exp.r, stage.current.background.mfg)
					exp.r+=2

					if exp.r>=12 then del(mobs.explode.all, exp) end
				end
					
				--when bomb weapon, create explosion and chain reaction check for other invaders
				if exp.w==3 then
					local rc=random(7,10)
						
					circfill(exp.pos.x,exp.pos.y, exp.r, rc)
					
					foreach (mobs.all, function(mob)	
						if (in_circle(mob.pos.x,mob.pos.y, exp.pos.x,exp.pos.y, exp.r)) then
							sfx(5)
							mobs.die(mob)
							mobs.kill(mob)	
						end

					end)
						
					exp.r+=5

					if exp.r>=18 then del(mobs.explode.all, exp) end
				end
			end)
		end,
		create=function(x,y)
			local weapon=player.weapon --need this to retain origin of shot
			add(mobs.explode.all, {pos={x=x,y=y},r=1,w=weapon})
		end
	}
}	




--
-- invader shots
--
shots={
	all={},
	_update=function()
		foreach(shots.all, function(obj)
			--movement
			obj.pos.y+=obj.dy
			obj.pos.x+=obj.dx
			
			if offscreen(obj.pos.x, obj.pos.y) then shots.remove(obj) end		
		end)
	end,
	
	_draw=function()
		foreach(shots.all, function(obj)
			if not obj.boss then
				pal(7,stage.current.background.mfg)
				spr(16, obj.pos.x,obj.pos.y)
				pal()
			else
				rectfill(obj.pos.x,obj.pos.y, obj.pos.x+1,obj.pos.y+24, 7)
			end
		end)
	end,
	
	create=function(x,y,ang,speed)
		if not speed then speed=rnd(1)+1 end
	
		local obj={
			pos={x=x,y=y},
			hitbox={x=0,y=0,w=2,h=4},
			speed=speed
		}
		
		obj.dx,obj.dy=dir_calc(ang, obj.speed) --angle of shot, .25 is up
		
		add(shots.all, obj)
	end,
	boss=function(x,y,ang)
		local obj={
			pos={x=x,y=y},
			hitbox={x=0,y=0,w=2,h=24},
			speed=2,
			boss=true
		}
		
		obj.dx,obj.dy=dir_calc(ang, obj.speed) --angle of shot, .25 is up
		
		add(shots.all, obj)
	end,
	
	remove=function(obj)
		del(shots.all, obj)	
	end
}	





--
-- powerup
--
powerup={
	all={},
	colors={8,12,11,10},
	chance=function(obj)
		if rnd()<.30 and #powerup.all<7 then --30% chance of a powerup drop, only when less than n in play
			powerup.drop(obj.pos.x, obj.pos.y)
		end
	end,
	drop=function(x,y,qty,putype)
		if not qty then qty=1 end
		if not putype then putype=flr(rnd(3))+1 end --get power-up color
		
		
		for n=1,qty do
			local pu={
				type=putype,
				pos={x=x,y=y},
				hitbox={x=0,y=0,w=8,h=8},
				grav=0
			}
			
			pu.dx,pu.dy=dir_calc(.75,1)
			
			-- coin drop shoots out rather than just drop
			if qty>1 then
				pu.dx,pu.dy=dir_calc(rnd(),1)
				pu.grav=.4
			end
	
			-- each powerup should have an apply() method which is
			-- called upon collision with player
			
			-- blue laser
			if putype==1 then
				pu.color={12,1}
				pu.apply=function()
					player.changeweapon(1)
					player.weaponcolor=pu.color[1]
				end
			end
			
			-- green machine gun
			if putype==2 then
				pu.color={11,3}
				pu.apply=function()
					player.changeweapon(2)
					player.weaponcolor=pu.color[1]
				end
			end
			
			-- red bomb
			if putype==3 then
				pu.color={8,2}
				pu.apply=function()
					player.changeweapon(3)
					player.weaponcolor=pu.color[1]
				end
			end

			-- yellow coin
			if putype==4 then
				pu.color={10,9}
				
				if not player.fever then 
					pu.seed=true 
					pu.dx,pu.dy=dir_calc(.75,2)
				end
				
				pu.apply=function()
					if pu.seed then
						sfx(7)
						player.fever=true
						player.fevertime=0
					else
						sfx(6)
						stage.collected+=1
					end
				end
			end
	
			add(powerup.all, pu)			
		end

	end,
	remove=function(obj)
		del(powerup.all, obj)
	end,
	allmatch=function() --return true if 3 matching colors
		local last=99
		local match=1
		foreach(player.power, function(pow)
			if pow~=last then 
				last=pow 
			else
				match+=1
			end
		end)
		
		if match==3 then return true else return false end
	end,
	_update=function()
		foreach(powerup.all, function(pu)
			pu.dy+=pu.grav    -- gravity
			pu.pos.y+=pu.dy
			pu.pos.x+=pu.dx   -- update position
				
			-- call apply() when player collision
			if collide(pu,player) then
				sfx(6)
			
				--add to powerup stack only if not yellow
				if pu.type<4 then
					if #player.power>=3 then player.power={} end
						
					add(player.power,pu.color[1]) --add it to color stack
					if powerup.allmatch() then
						player.power={}
						pu.apply() 
					end
				end
			
				--when its yellow, just apply collision 
				if pu.type==4 then
					pu.apply()
				end

				powerup.remove(pu)
			end
				
			if offscreen(pu.pos.x, pu.pos.y) then powerup.remove(pu) end
		end)
	end,
	_draw=function()
		
		foreach(powerup.all, function(pu)
			pal(7,pu.color[1])
			pal(5,pu.color[2])
			spr(17, pu.pos.x,pu.pos.y)
			pal()
		end)
	end

}

--
-- #score
--
scorepop={all={},
	lastx=30,
	lasty=50,
	_update=function()
		foreach(scorepop.all, function(obj)
			if obj.t>=45 then del(scorepop.all,obj) end
			obj.t+=1
		end)
	end,
	_draw=function()
		foreach(scorepop.all, function(obj)
			print(obj.s,obj.x+1,obj.y,stage.current.background.mbg)
			print(obj.s,obj.x,obj.y,stage.current.background.hfg)
		end)
	end,
	add=function(str)
		if scorepop.lasty>=80 then 
			scorepop.lastx+=25 
			scorepop.lasty=50
		end
		
		if scorepop.lastx>=100 then
			scorepop.lastx=30
			scorepop.lasty=50
		end
		
		if player.fever then str*=2 end
		
		player.score+=shr(str,16)
		
		add(scorepop.all, {s=str,t=0,x=scorepop.lastx,y=scorepop.lasty})
		
		scorepop.lasty+=10
	end
	
}



--
-- #play game
--
play={
	_init=function() --only called once when starting a new game
		boss.active=false

		if musicon then music(0) end
		
		cart.update=play._update
		cart.draw=play._draw
	end,
	
	_update=function()
		stage._update()
		player._update()
		mobs._update()
		scorepop._update()
		powerup._update()
		ufos._update()
	end,
	
	_draw=function()
		rectfill(0,0,127,127,stage.current.background.color)
		stage.current.background.draw()
		
		meters._draw()
		
		-- strip background for top/bottom
		pal(6,stage.current.background.pbg)
		map(0,0, 0,120, 16,1)
		map(0,0, 0,0, 16,1)
		pal()
		
		scorepop._draw() --scoring 
		stage._draw()
		
		mobs._draw() --invaders
		ufos._draw() --ufo
		player._draw() --player
		powerup._draw() --falling powerups
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
		if btnzp then
			stage._init()
			play._init()	
		end
		
		if btnlp or btnrp or touch.left() or touch.right() then
			if autofire then autofire=false else autofire=true end
		end
		
		if btnxp then
			if musicon then musicon=false else musicon=true end
		end
	end,
	
	_draw=function()
		background.grid.draw()
		
		map(0,2, 20,20, 12,3) --logo
		
		local text1="press "..char.btnz.." or z to start"
		local text2="<  auto-fire  >"
		local text3="< manual fire >"
		local text4=text2
		
		if not autofire then text4=text3 end
		
		--center_text("press "..char.btnz.." or z to start",56,8)
		--center_text("press "..char.btnz.." or z to start",55,7)
		
		print(text1,24,60,0)
		print(text1,23,60,7)
		
		--center_text("\139 auto-fire on \145",72,8)
		--center_text("\139 auto-fire on \145",71,7)
		
		print(text4,35,75,0)
		print(text4,34,75,7)
		
		--center_text("music by @gnarcade_vgm",95,6)
		--center_text("backgrounds from",95,6)
		--center_text("the pico-8 community",103,6)
		
		center_text("high score "..score_text(highscore),100,10)
		
		print("V"..version,5,118,5)
		
		if musicon then 
			mcolor=11
		else
			mcolor=5
		end
		print("\151\141",110,118,0)
		print("\151\141",110,118,mcolor)
	end
}


--
-- #gameover
--
gameover={
	wait=30,
	_init=function()
		music(-1)
		sfx(62)
		gameover.t=0
		
		
		
		if player.score>highscore then
			dset(0,player.score)
			highscore=player.score
		end
		
		cart.update=gameover._update
		cart.draw=gameover._draw
	end,
	
	_update=function()
		if gameover.t>=gameover.wait and btnzp then _init() end
		gameover.t+=1
	end,
	
	_draw=function()
		rectfill(0,0,128,128,8)
		
		pal(7,0)
		map(0,5, 30,10, 9,2)
		pal()
		
		center_text("final score",35,10)
		center_text(score_text(player.score),43,10)
		
		local texty=76
		
		print("CODE+ART:",7,76,1)
		print("BRIAN VAUGHN",7,82,0)
		print("@MORNINGTOAST",7,88,0)
		
		
		print("MUSIC:",70,76,1)
		print("BRIAN FOLLICK",70,82,0)
		print("@GNARCADE_VGM",70,88,0)
		
		--center_text("CODE+ART:BRIAN VAUGHN",texty,1)
		--center_text("@MORNINGTOAST",texty+6,1)
		
		local texty=93
		--center_text("MUSIC:BRIAN FOLLICK",texty,1)
		--center_text("@GNARCADE_VGM",texty+6,1)
		
		local texty=100
		center_text("BACKGROUND ANIMATIONS:",texty,1)
		center_text("PICO-8 COMMUNITY",texty+6,0)
		
		
		center_text("WWW.MORNINGTOAST.COM",118,7)
		
		
		if gameover.t>=gameover.wait then
			center_text("press "..char.btnz.." or z to continue",58,7)
		end
	end
}



--
-- #loops
--

-- set vars on boot
-- player.load() --set vars, no methods

cartdata("invoverloadp8") --load savedata


function _init()
	mouse.init() -- for touch controls
	
	highscore=dget(0)
	if highscore<=0 then
		local scr=shr(25000,16)
		scr+=shr(25000,16)
		highscore=scr
	end
	
	player.load()
	player.zrate=8
	shots.all={}
	
	ufos.t=0
	ufos.active=false
	
	boss.count=.5
	
	stage.id=1
	stage.collected=0
	
	titlescreen._init()
end

function _update()
	btnl=btn(0)
	btnlp=btnp(0)
	btnr=btn(1)
	btnrp=btnp(1)
	btnz=btn(4)
	btnx=btn(5)
	btnzp=btnp(4)
	btnxp=btnp(5)
	
	touch.update()
	
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
debugtext=""
function debug(str) debugtext=str end
function debug_out() print(debugtext, 97,3, 1) print(debugtext, 96,2, 11) end
function debug_hugbox(obj,c) 
	local color=c or 11
	rect(obj.pos.x+obj.hitbox.x,obj.pos.y+obj.hitbox.y, obj.pos.x+obj.hitbox.w,obj.pos.y+obj.hitbox.h, color)
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
  button = function()
    return stat(34)
  end,
}


-- get dx/dy calculations for movement
function dir_calc(angle,speed)
	local dx=cos(angle)*speed
	local dy=sin(angle)*speed
	
	return dx,dy
end

function in_circle(ox,oy,cx,cy,cr)
	local dx = abs(ox-cx)
	local dy = abs(oy-cy)
	local r = cr

	local k = r/sqrt(2)
	if dx <= k and dy <= k then return true end
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


-- returns true if x/y is out of screen bounds
function offscreen(x,y)
	if (x<screen.x or x>screen.w or y<screen.y or y>screen.h) then 
		return true
	else
		return false
	end
end


-- returns true if hitbox collision 
function collide(obj, other, custom)
	local bhitbox=custom or obj.hitbox

    -- get the intersection of p and af
	  local l = max(obj.pos.x+obj.hitbox.x,               other.pos.x+other.hitbox.x)
	  local r = min(obj.pos.x+obj.hitbox.x+obj.hitbox.w,  other.pos.x+other.hitbox.x+other.hitbox.w)
	  local t = max(obj.pos.y+obj.hitbox.y,               other.pos.y+other.hitbox.y)
	  local b = min(obj.pos.y+obj.hitbox.y+obj.hitbox.h,  other.pos.y+other.hitbox.y+other.hitbox.h)

	  -- they overlapped if the area of intersection is greater than 0
	  if l < r and t < b then
		return true
	  end
					
	return false
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
000000000000000000777700707007070007770000777000a0a0a0a0000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000007777770077777700007770000777000a0b0b0a0000000000000000000000000000000000000000000000000000000000000000000000000
007007000000000077077077770770777777777777777777b0b0b0b0000000000000000000000000000000000000000000000000000000000000000000000000
000770000007000077777777777777777777777777777777b03030b0000000000000000000000000000000000000000000000000000000000000000000000000
00077000000700000770077007000070777700777700777730303030000000000000000000000000000000000000000000000000000000000000000000000000
00700700007670007000000707700770007700777700770030303030000000000000000000000000000000000000000000000000000000000000000000000000
00000000076667000000000000000000007777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000760606700000000000000000007777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777770000077770000000000007777777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000755570000700007000000000770007700770007700000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000757570000700007000000000770007700770007700000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000755570007777777700000000000007700770000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000777770000777777000000000000770000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070070000000000000770000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000077770000700700000000000000000000000000700000000000000000000000000000000000000000000000007000000000000000000000
00000000000000000707707070077007000000000000007770000077007700000000700000000000000000000000007000000000077000000000000000000000
00000000000000000777777077777777000000000000777700000770007700007000777770000000777770007000777077777770077700000000000000000000
00000000000000000007700007077070000000000007770000077770077770077707777777700077777777077000770777777000777770000000000000000000
00000000000000000070070007777770000000000777700777077070077770777707700000000700770077077007700770000000770077000000000000000000
00000000000000000700007000700700000000000777777770770070077777777707777777007077700077077077707777777007700777000000000000000000
00000000000000000000000007000070000000007770777007770770777777777077777700000077000777077777007777700007777700000000000000000000
00000000000000000000000000000000000000007700777077777770770700770077700000000077007770077770077700000007777700000000000000000000
06060606000000000000000000000000000000007707777077007707770007700077777777000777077770077700777007770077707770000000000000000000
60606060000000000000000000000000000000007777770770007707700007700777777700000777777700077000777777000777000770000000000000000000
06060606000000000000000000000000000000000770770700007707000077000777000000000077770000070007777700000770000077000000000000000000
60606060000000000000000000000000000000000000700000007000000077007000000000000000000000700007700000007700000007000000000000000000
06060606000000000000000000000000000000000000700000007000000770000000000000000000000000000000000000007000000000700000000000000000
60606060000000000000000000000000000000000000000000007000000700000000000000000000000000000000000000000000000000000000000000000000
06060606000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60606060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000888888088000880088000880008880008888800008888880088888800000000000000000000000000000000000000000000000000000000
00000000000000000008800088800880088000880088088008800880008800000088000880000000000000000000000000000000000000000000000000000000
00000000000000000008800088880880088000880880008808800088008800000088000880000000000000000000000000000000000000000000000000000000
00000000000000000008800088888880088808880880008808800088008888800088008880000000000000000000000000000000000000000000000000000000
00000000000000000008800088088880008888800888888808800088008800000088888000000000000000000000000000000000000000000000000000000000
00000000000000000008800088008880000888000880008808800880008800000088088800000000000000000000000000000000000000000000000000000000
00000000000000000888888088000880000080000880008808888800008888880088008880000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000aaa0a000000000000a000000000000000000000000000000000000aa0000000000000000000000000000000000000000000000000
0000000000000000000000aaa00aaa000000000aaa0000000000a0000000000000000000000aaa000000aaa00000000000000000000000000000000000000000
0000aaaaaaaa000aa0000aaaa0aaaaaaaaaaa0aaaaaa0000000aaa00000aaaaaaaa0000000aaaa000000aaaa0000000000000000000000000000000000000000
00aaaaaaaaaaa00aa000aaaa00aaaaaaaa0000aaaaaaaa0000aaa0000aaaaaaaaaaa00000aaaa000000aaaaaaa00000000000000000000000000000000000000
0aaaaaaa00aaa00aa00aaaa000aaa00000000aaaa0aaaa0000aaa000aaaaaaa00aaa0000aaaaa000000aaa0aaa00000000000000000000000000000000000000
b00aaaa000aaa0aaa00aaa000aaaa00000000aaa00aaaa000aaa000b00aaaa000aaa000aaaaaa00000aaaa00aaa0000000000000000000000000000000000000
000aba0000ab00aba0abab00ababababab00abab0baba000bab0000000aba0000ab000ab00aba00000abaa00aba0000000000000000000000000000000000000
00aba0000aba00bababaa00ababababa000abababab00000aba000000aba0000aba000ba0abababa00bab000bab0000000000000000000000000000000000000
00bb0000bbbb00bbbbbb000bbb00000000bbbbbbbbb0000bbbb000000bb0000bbbb00bbbbbbbbbb00bbbb00bbb00000000000000000000000000000000000000
0bbb000bbbb000bbbbb000bbb00bbbbbb0bbbb00bbb0000bbb000000bbb000bbbbbbbbbbbbbbb0000bbbbbbbbb00000000000000000000000000000000000000
0bbb00bbbb000bbbbb000bbbbbbbbbbb00bbb000bbbb00bbbb00000bbbb00bbbb00bbb0000bb00000bbbbbbb0000000000000000000000000000000000000000
0bbbbbbbb0000bbbb00bbbbbbbbbb0000bbb000000bb00bbbbbbbb0bbbbbbbbb000bb00000bb00000bbbbbb00000000000000000000000000000000000000000
00bbbbb000000bbbb000bbbbbb0000000bbb000000bb0bbbbbbbbb000bbbbb0000bbb00000bbb000bbbb00000000000000000000000000000000000000000000
0000b000000000bb00000bb0000000000b000000000b0bbbbbb00000000b0000000b00000bbb0000b00000000000000000000000000000000000000000000000
000000000000000000000b00000000000000000000000b000000000000000000000000000bb00000b00000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000b00000000000000000000000000000000000000000000000000000
00000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000077777777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000007700770070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3030303030303030303030303030303000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
404147434445464748494a4b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
505152535455565758595a5b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
606162636465666768696a6b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
707172737475767778797a7b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
25262728292a2b2c2d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
35363738393a3b3c3d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
010c0000027750270036701007000277500700027350273502775007003c705007000277500700367010070002775007000273500700027750070000700007000277500700007000070002775007000273502735
010c00000277502700027351e7010277500700027350c70502775007003c705007000277500700367010070002775007000273500700027750070000700007000277500700007000070002775007000273502735
010c00000277502700027351e7010277500700027350c70502775007003c705007000277500700367010070002775007000273500700027750070000700007000277500700027750070002775027350277502735
010c000002775027003261532601027753e6053e6050270502775356053260500700027753e605326153261502775356053261535605027753261500700007000277500700326153262132635007003261532615
010c000002775027003260532601027753e605326153261502775356053261500700027753e605326053260502775356053261535605027753e61500700007000277500700326153260102775007003261532605
00040000156701466012650106500e6400b6400964007630056200361008600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010400002d57535505355752d50529505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505005050050500505
00080000183311a3411c3511d3611f36121361243602b36030360243602b36030360243062b306303000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
010c00000e0050e005020350e035326250e005020350e0350e0050e005020350e035326250e005020350e0350e0050e005020350e035326250e005020350e0350e0050e005020350e035326250e005020350e035
01080000326453264526635266351a6251a6250e6150e61532605266051a6050e60532605266051a6050e6052b1002b1002b1022b1022b1022b1022b1022b1022b1022b102261002610026100001000010000100
010c00000e2350e230002000e2000e23004200022300e2350e23011200002000c230002000020000200002000e2350e230002000e2000e23004200022300e2350e23011200002301123000200102300020000200
010c00000e2350e230002000e2000e23004200022300e2350e23011200002000c23000200002000020000200072350723000200052300e23004200022300c2350e2301120000230112301020511205102300c200
010c00000e2350e230002000e2000e23004200022300e2350e23011200002000c23000200112300020000200326150720032615052003261504200326150c2053261532615326153261532625326253262532625
010c00000a2350a230046050e2000a2300420007230152351123011200002001023000200002000020000200072350723000200052300e23004200022300c2351123011200102301120015230102001323000200
010c00000e2350e230002000e2000e23004200022300e2350e23011200002000c230002000020000200002000d2350d230002000d2300d230042000d2300d2350d230112000d230102301523013230112300c230
010c00000e2350e230002000e2000e23004200022300e2350e23011200002000c230002000020000200002000723507230002000223007230042000223011235152301120011230102301020511205112300c200
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c000034421284211c421104210000700007000070000700007000070000700007000072133529335293052633526305263051c407244071a40728407000070000700007000070000700007000070000700007
010c00002633529300283352933500000000000000000000000000000000000000000000026320293202d325293201d3210d32125300000000000000000000000000000000000000000029335000002433500000
010c00000e0050e005020050e005326050e005020050e0050e0050e005020050e005326050e005020050e00529730297302973226730267312973129730297322d7302d7302d7322973029730297322873028732
010c00002d7002d7002d70229700297012d7012d7002d7023070030700307022d7002d7002d7022b7002b7022d7302d7302d73229730297312d7312d7302d7323073030730307322d7302d7302d7322b7302b732
011000002630526305263052630126305293050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010c00000e0050e005020350e035326250e005020350e0350e0050e005020350e035326250e005020350e03529730297302973226730267312973129730297322d7302d7302d7322973029730297322873028732
010c00000e0050e005020350e035326250e005020350e0350e0050e005020350e035326250e005020350e0352d7302d7302b7322b730297312973128730287322b7302b730297322973028730287322473024732
010c00000e0050e005020350e035326250e005020350e0350e0050e005020350e035326250e005020350e03530730307302e7322e7302d7312d7312b7302b7322e7302e7302d7322d7302b7302b7322870028732
010a0000026350e605026050e605326430e605026350e605026050e6050263502635326450e605026350e635026352d600026350260532643026350261502605026352b600296020263532643326030261502605
010a00000e2300e235022300223505230052350e2300e2350e2000e20509240092450c2300c23011240132401123011235052400524009240092300c2400c2301023010222102121021511240112350d2400d245
010a00000e2300e235022300223505230052350e2300e2350e2000e20509240092450c2300c230112401324015230152351524015240162401623015240152301323013225112321122510240102350d2400d245
010a00000e2300e235022300223505230052350e2300e2350e2000e20509240092450c2300c23011240132400d2400d2320d2220d215112401123211222112151524015232152221521510240102321022210215
010a0000026350e605026050e605326430e605026350e605026050e6050263502635326450e605026350e635326432d600026350260532643267431a7430e743026352b600326430260532623326333264332653
010c0000292502925029242292422923229232292222922229212292122900424000240001a0001a1001d20028250282502824228242282322823228222282222821228212262002620026200000000000000000
011000002625026250262422624226232262322622226222262122621226212262122621226200262002620000000000000000000000000000000000000000000000000000000000000000000000000000000000
010a000011230112350523005235092300923511230112350e2000e2050e2400e2451023010230182401824015230152350924009240022400223010240102301323013222132121321515240152351124011245
010a00002d0502d0502d0402d0402d0322d0322d0222d0222d0122d0122d0122d01232000320002e0002e0002b0002b0002b0002b0002b0022b00229050290402904029030290322902230050300303002230012
010a00002b0502b0502b0402b0402b0322b0322b0222b0222b0122b0122b0122b01232000320002e0002e0002b0002b0002b0002b0002b0022b00235050350403504035030350323502234050340303402234012
010a000029050290502904029040290322903229022290222901229012290122901232000320002e0002e0002b0002b0002b0002b0002b0022b00229030290322902229030290322902228050280302802228012
010a000028050280502804028040280322803228022280222801228012280122801232000320002e0002e0002b0002b0002b0002b0002b0022b00235050350403504035030350323502234050340303402234012
010a000026050260502604026040260322603226022260222601226012260122601232000320002e0002e0002b0002b0002b0002b000280502805028050280402903029030290322902230050300303002230012
010a000011230112350523005235092300923511230112350e2000e2050e2400e245102301023018240182400c2300c2350c2400c24010240102300c2400c2301a2301a225152321522513240132351024010245
010a000011230112350523005235092300923511230112350e2000e2050e2400e2451023010230182401824011230112350e2400e24010240102300c2400c2300e2300e22509232092250c2400c2350724007245
010c00002d1402d1402d1422d1322d1322d1322d1222d1222d1122d1122910424100241001a1001a1001d1002b1402b1402b1422b1322b1322b1322b1222b1222b1122b112261002610026100001000010000100
010c00002e7352d7352b735297352d7352b73529735287252b735297352873526735297352873526735247352672528725297252b72528725297252b7252d725297252b7252d7252e7252b7252d7252e72530725
010c0000261402614026142261322613226132261222612226112261122910424100241001a1001a1001d10024140241402414224132241322413224122241222411224112261002610026100001000010000100
010c0000261402614026142261322613226132261222612226112261122910424100241001a1001a1001d1002d1402d1402d1422d1322d1322d1322d1222d1222d1122d112261002610026100001000010000100
010c00002e7352d7352b735297352d7352b73529735287252b73529735287352673529735287352673524735326252870529705326252870529705326252d7053262532625326253262532625326253262532625
010c0000261402614026142261322613226132261222612226112261122611226112261121a1001a1001d1002b1002b1002b1022b1022b1022b1022b1022b1022b1022b102261002610026100001000010000100
010c00002e7352d7352b735297352d7352b73529735287252b735297352873526735297352873526735247352672528725297252b72528725297252b7252d725297252b7252d7252e7252b7252d7252e72530725
01050020042300d23517230242352e230362353c23001205042300d23517230242352e230362353c23013200042300d23517230242352e230362353c23007200042300d23517230242352e230362353c2300d205
00050000026000260003601056010c6110662108611096250f6200b6250c63010635016301263514630166301a6301a6451c6402064521640236452564027640086402b6452e6403064535640396453b6403f645
010a00000e3400e34102341023450e3050230102305023000e3400e3410234102345023010230102301023050e3400e3410234102345003000030000300003000e3400e341023410234500300003000030000300
01050000042300d23517230242302e230362353c23001205042300d23517230242352e230362353c23013200042300d23517230242352e230362353c23007200042300d23517230242352e230362353c2300d205
01010000323403234126341263411a3411a3410e3410e341323403234126341263411a3411a3410e3410e341323403234126341263411a3411a3410e3410e341323403234126341263411a3411a3410e3410e341
0105000024340243402433024330243222432224312243122134021330213222131229342293422933229332293222932229312293121f3421f3321f3221f3121834018330183201831028342283322832228312
010500002834028340283302833028322283222831228312263402633026322263122d3422d3422d3322d3322d3222d3222d3122d31224342243322432224312283402833028320283102b3422b3322b3222b312
010a1000326450e60502655026050265529302326450e605026050e605026450260532645326353264532635026352d600026350260532643026350261502605026352b600296020263532643326030261502605
010a000032050320503204032040320323203232022320223201232012320123201232000320002e0002e0002b0002b0002b0002b0002b0022b0022d0302d0322d0222d0302d0322d02234050340303402234012
010a000030050300503004030040300323003230022300223001230012300123001232000320002e0002e0002b0002b0002b0002b0002b0022b00239030390323902239030390323902237050370303702237012
010a00002d0502d0502d0402d0402d0322d0322d0222d0222d0122d0122d0122d01232000320002e0002e0002b0002b0002b0002b0002b0022b0022d0302d0322d0222d0302d0322d0222b0502b0302b0222b012
010a000029050290502904029040290322903229022290222901229012290122901232000320002e0002e0002b0002b0002b0002b0002d0402b04029040280402b0402904028042260422404028040290422b042
010200002824528245282452824528245282452824528245342002e600286002360025600216001d6001a600136000e6000b600076001d6001d600176000f6000960006600056000560005600056000560004600
0002000017130121300d130091300513001130137001470014700296002c600276001f60023600146000a600076000b60008600076000a6000760005600026000c60008600026000b60005600016000060000600
010100002e0232902324023200231c0230d02304003010030b0030300300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003
010a000026535295352b5352d53528535295352d5353053530530295312d53126531245311d531215311a53135500375003250039500305003350032500375003950032500375003950000500005000050000500
0104000035357303572b35727357233571d357123570a357063570635704357033570535707357093570d3571035714657296501d6402d640296301d6202d620033301d630076302063015620236200e6200e615
__music__
00 00544344
00 024b4344
00 000a4344
00 010b4344
00 000a4344
00 020c1314
00 010a0844
00 010b0844
00 010a0844
00 01080b44
00 010a0811
00 010b0812
00 010a0811
00 020c1614
00 000d2928
00 0b00292a
00 000d2928
00 0e002c2b
00 010a0844
00 010b0844
00 010a0844
00 020c1614
00 010a0811
00 010b0812
00 010a0811
00 020c1718
00 000d2928
00 0b00292a
00 000d2928
00 0e002c2b
00 000a2d09
00 010b4344
00 595a4344
00 595b4344
00 595a4344
00 191a4344
00 191b4344
00 191a4344
00 1d1c4344
00 4142433f
00 716f4344
00 72717044
00 716f4344
00 312f4344
00 32313044
00 35343644
01 191a216e
00 191b2244
00 191a2344
00 1d1c2544
00 19203744
00 19263844
00 19203944
02 1d273a44
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

