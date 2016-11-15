pico-8 cartridge // http://www.pico-8.com
version 7
__lua__
--[[
	RGB
	Copyright 2016, Brian Vaughn
	@morningtoast
]]

function framet(s,d,fps)
	if not fps then fps=30 end
	if not d then d=0 end
	
	local ft=s*fps+flr((d/100)*fps)
	return ft
end

function log(s)
	print(s,1,1,10)
end


-->>========= globals, config
screen={x=0,y=0,w=128,h=116,mid=60}
ticker=0
version="0.0.1"

debug={}
debug.n=framet(4,5)

--[[ base cart ]]
cart={}


--[[ game manager ]]
game={}
game.highscore=0
game.reset=function()
	game.score=0
	game.stage=0
end

game.init=function()
	game.stage+=1
	
	game.lastkillcolor="black"

	board.init()
	player.init()
	bullets.init()
	shots.init()
	enemy.init(game.stage)
	explode.init()
	
	cart.update=game.update
	cart.draw=game.draw
end

game.update=function() 
	board.update()
	bullets.update()
	shots.update()
	player.update()
	enemy.update()
	explode.update()
end


game.draw=function() 
	board.draw()
	bullets.draw()
	shots.draw()
	player.draw()
	enemy.draw()
	hud.draw()
	explode.draw()
	
	
end


-----stars bg
stars={}

stars.bright=12
stars.dark=1
stars.init=function()
	stars.all={}
	for i=0,32 do
		s = {}
		s.x = rnd(128)
		s.y = rnd(100)+10
		s.c = i/32
		s.col = stars.dark
		if s.c>0.75 then s.col=stars.bright end
		add(stars.all,s)
	end	
end

stars.draw=function()
	for s in all(stars.all) do
		--%n is where stars will stop on y axis
		pset(s.x,(s.y+ticker*s.c)%screen.h,s.col)
	end
end



-----player
player={}
player.create=function()
	player.lives=3
	player.bomb=0
	player.speed=2.5
	player.shield=0
	player.pos={x=0,y=0}
	player.hitbox={x=4,y=4,w=2,h=2}
	player.spr=1
	player.hflip=false
	player.vflip=false
	player.shotspeed=6
end
player.init=function()
	player.bar=#board.stage.bars
	player.heal=0
	player.hflip=false
	player.vflip=false
	player.shotclock=player.shotspeed
	currentbar=board.getbar(player.bar)
	player.setcolor(currentbar.color)
	
	player.pos={x=0,y=currentbar.pos-3}
end

player.setcolor=function(color)
	player.color=color	
	player.light,player.dark=getcolors(player.color)
end

player.update=function()
	if board.stage.horz then
		
	
--horz handling	
		--if(player.color=="red") then player.spr=1 end
		--if(player.color=="green") then player.spr=2 end
		--if(player.color=="blue") then player.spr=3 end
		
		--moving
		if btn(0) then 
			player.pos.x-=player.speed 
		elseif btn(1) then 
			player.pos.x+=player.speed
		end
		
		leftmax=screen.w-7
	
		if (player.pos.x <= screen.x) then player.pos.x=screen.x end
		if (player.pos.x >= leftmax) then player.pos.x=leftmax end
	else 
--vert handling
		
		
	end
	
	--jump
	if btnp(2) then
		player.jump(-1) --up
	elseif (btnp(3)) then 
		player.jump(1) --down
	end
	
	-- fire
	if btn(4) then 
		if player.shotclock<=0 then
			bullets.create()
			sfx(1)
			player.shotclock=player.shotspeed
		end
	end
	
	if btnp(5) and btnp(4) then endlevel.init() end
	
	player.shotclock-=1
	player.heal-=1
	
	if player.lives<=0 then gameover.init() end
end

player.draw=function()
	if board.stage.horz then
		if not overmid(player.pos.y) then player.vflip=true else player.vflip=false end
	else
		if not overmid(player.pos.x) then player.hflip=true else player.hflip=false end
	end
	
	pal(9,player.light)
	pal(4,player.dark)
	spr(player.spr, player.pos.x, player.pos.y, 1,1, player.hflip, player.vflip)
end


player.jump=function(d)
	player.bar+=d
	
	if player.bar<1 then player.bar=1 end
	if player.bar>#board.stage.bars then player.bar=#board.stage.bars end
	
	thisbar=board.getbar(player.bar)
	
	if board.stage.horz then
		player.pos.y=thisbar.pos-3
	else 
		player.pos.x=thisbar.pos
	end	
	
	player.setcolor(thisbar.color)
	
	
end


-----bullets, player only
bullets={}

bullets.init=function()
	bullets.all={}	
end

bullets.create=function()
	local obj={}
	obj.pos={x=player.pos.x,y=player.pos.y}
	obj.hitbox={x=0,y=0,w=2,h=2}
	obj.color=player.color
	obj.spr=21
	obj.speed=player.shotspeed
	obj.alive=true
	obj.dir=1
	obj.vflip=false
	obj.hflip=false
	
	if board.stage.horz then
		obj.pos.x+=3
		if overmid(obj.pos.y) then 
			obj.speed=0-obj.speed
		else 
			obj.speed=abs(obj.speed) 
			obj.pos.y+=2
		end
	end

	bullets.add(obj)
end


bullets.add=function(obj)
	add(bullets.all, obj)
	
end


bullets.getsprite=function(color)
	if (color=="red") then return(21) end
	if (color=="green") then return(23) end
	if (color=="blue") then return(22) end
	if (color=="white") then return(20) end --power bullet
end

bullets.update=function()
	foreach(bullets.all, function(obj) 
		if obj.alive then
			if board.stage.horz then
				obj.pos.y+=obj.speed
			else
				obj.pos.x+=obj.speed
			end
			
			--kill when off screen
			if offscreen(obj.pos.x,obj.pos.y) then del(bullets.all,obj) end
		end 
	end)
end

bullets.draw=function()
	foreach(bullets.all, function(obj) 
		if obj.alive then
			local light=getcolors(obj.color)
			pal(9,light)
			spr(obj.spr,obj.pos.x,obj.pos.y)
		end 
	end)
end


-----hud ui
hud={}
hud.y=120
hud.draw=function()
	print("s"..game.stage,120,hud.y,6)
	print(game.score,0,hud.y,6)
	
	--spr(5,50,hud.y) --bomb
	local hudx=85
	for n=1,player.lives do
		spr(17, hudx, hud.y) --lives
		hudx+=8
	end
end


-----stages, configuration datastore only

--horz: true=horizontalbar,false=vertical
--distances between enemies is +8, so for 3x3 block is 10/10,18/10,26/10|10/18,18/18,26/18

stages={}
stages.all={}
stages.build=function(x,y,list)
	local result={}
	local spacing=9 --width of each sprite
	
	x-=spacing
	
	foreach(list, function(cfg)
		
		newx=x+spacing
		if cfg.color~="x" then
		
		
			 add(result, {
				color=cfg.color,
				style=cfg.style,
				delay=cfg.delay,
				offset=cfg.offset,
				y=y,
				x=newx
			 })
		end
		
		
		 
		x=newx
	end)
	
	return result
end

stages.add=function(cfg)
	add(stages.all, cfg)
end



-----board
board={}
board.stage={}
board.init=function()
	board.stage=stages.all[game.stage]
	board.timer=ticker
	board.walls=0
	bonus.init()
end

board.update=function()

end

board.draw=function()
	--loop to draw each bar
	
	foreach(board.stage.bars, function(bar)
		local light=getcolors(bar.color)
		
		if board.stage.horz then
			line(screen.x, bar.pos, screen.w, bar.pos, light) --horz
		else
			line(screen.y, bar.pos, screen.h, bar.pos, light) --vert
		end
	end)
end


board.getbar=function(barid)
	return board.stage.bars[barid]
end


bonus={
	init=function()
		bonus.perfect=true
		bonus.nokill=true
		bonus.quick=true
	end
}



-----enemy actors
enemy={}


enemy.init=function(stagenum)
	enemy.all={}
	enemy.timer=0
	
	foreach(board.stage.enemy, function(list)
		foreach(list, function(cfg)
			local badguy={}
			local enemyattr=enemy.getstyle(cfg.style)
			
			if not cfg.dist then cfg.dist=0 end
			if not cfg.speed then cfg.speed=0 end
			if not cfg.offset then cfg.offset=0 else cfg.offset=0-cfg.offset end
			if not cfg.delay then cfg.delay=enemyattr.delay end
	
			badguy.color=cfg.color
			badguy.spr=enemyattr.spr
			badguy.startpos={x=cfg.x,y=cfg.y}
			badguy.hitbox={x=0,y=0,w=8,h=8}
			badguy.pos={x=cfg.x,y=cfg.y}
			badguy.dist=cfg.dist
			badguy.speed=cfg.speed
			badguy.alive=true
			badguy.offset=cfg.offset --handicap shot clock
			badguy.cycle=badguy.offset --shot clock
			badguy.delay=cfg.delay --time between firing
			badguy.light,badguy.dark=getcolors(badguy.color)
			badguy.shot=enemyattr.shot
			
			if badguy.color=="white" then board.walls+=1 end
			
			
			
			add(enemy.all, badguy)
		end)
	end)

	enemy.count=#enemy.all-board.walls
end

enemy.update=function()
	enemy.timer+=1
	foreach(enemy.all, function(badguy) 
		
		--shot ticker
		badguy.cycle += 1
		
		if badguy.cycle>=badguy.delay then 
			badguy.shot(badguy.pos.x,badguy.pos.y)
			badguy.cycle=0
		
		end
		
		
		--bullet hit detect
		foreach(bullets.all, function(bullet) 
			if collide(badguy,bullet) then
				--bullet.alive=false
				--badguy.alive=false
				
				
				
				if badguy.color~="white" then
					explode.now(badguy.pos.x, badguy.pos.y, badguy.light)
					sfx(2)
				
					if game.lastkillcolor==badguy.color and bullet.color==badguy.color then game.score+=50 end
					game.lastkillcolor=badguy.color
				
					if bullet.color==badguy.color then
						game.score+=25
					else
						game.score+=10
						bonus.perfect=false
					end
					
					--bullet.alive=false
					del(enemy.all,badguy)
					del(bullets.all, bullet)
					
					enemy.count-=1
					if enemy.count<=0 then 
						endlevel.init()
					end
				else 
					del(bullets.all, bullet)
					sfx(0)
				end
				
				

				
			end
		end)		
	end)
end

enemy.draw=function()
	foreach(enemy.all, function(obj)
		if obj.alive then
			pal(9,obj.light)
			pal(4,obj.dark)
			spr(obj.spr, obj.pos.x, obj.pos.y)
		end
	end)
end


enemy.getstyle=function(s)
	local cfg={}
	
	--shot: 1=cross,2=straight,3=target
	
	--vertical straight shot
	if s=="b" then 
		cfg.spr=39
		cfg.delay=30 --frames to wait between calling the shot generator
		cfg.shot=function() end
	end
	
	
	--vertical straight shot
	if s=="s" then 
		cfg.spr=37
		cfg.delay=30 --frames to wait between calling the shot generator
		cfg.shot=shots.straight
	end
	


	--cross
	if s=="x" then
		cfg.spr=40
		cfg.delay=50
		cfg.shot=shots.cross
	end 
	
	-- 3-wide spread
	if s=="sp3" then 
		cfg.spr=53
		cfg.delay=40
		cfg.shot=shots.spread3
	end
	
	-- double 3-wide spread
	if s=="sp3d" then 
		cfg.spr=53
		cfg.delay=40
		cfg.shot=shots.spread3d
	end
	
	-- 5-wide spread
	if s=="sp5" then 
		cfg.spr=53
		cfg.delay=55
		cfg.shot=shots.spread5
	end
	
	-- double 5-wide spread
	if s=="sp5d" then 
		cfg.spr=53
		cfg.delay=55
		cfg.shot=shots.spread5d
	end
	
	-- double 5-wide spread
	if s=="fan" then 
		cfg.spr=53
		cfg.delay=65
		cfg.shot=shots.fan
	end
	
	-- double 5-wide spread
	if s=="split" then 
		cfg.spr=54
		cfg.delay=45
		cfg.shot=shots.split
	end
	
	return cfg
end


-----shots, enemy only
shots={}
shots.init=function()
	shots.all={}	
end



shots.create=function(x,y,angle)
	local obj={}
	obj.pos={x=x+2,y=y+2}
	obj.hitbox={x=0,y=0,w=4,h=4}
	obj.spr=36
	obj.speed=2
	obj.alive=true
	
	obj.dx=cos(angle)*obj.speed
	obj.dy=sin(angle)*obj.speed
	
	return obj
end


shots.update=function()
	foreach(shots.all, function(obj) 
		obj.pos.x+=obj.dx
		obj.pos.y+=obj.dy 
		
		if collide(obj,player) and obj.alive and player.heal<=0 then
			player.lives-=1
			player.heal=15
			explode.now(player.pos.x, player.pos.y, 10)
			del(shots.all,obj)
			bonus.nokill=false
			sfx(3)
		end
		
		if offscreen(obj.pos.x,obj.pos.y) then del(shots.all,obj) end
	end)
end

shots.draw=function()
	foreach(shots.all, function(obj) 
		if obj.alive then
			spr(obj.spr,obj.pos.x,obj.pos.y)
		end 
	end)
end

shots.add=function(obj)
	add(shots.all, obj)
end


--[[ shot patterns ]]
shots.straight=function(x,y)
	if board.stage.horz then
		if overmid(player.pos.y) then 
			shots.add(shots.create(x,y,.75))
		else 
			shots.add(shots.create(x,y,.25))
		end
	end
end


shots.double=function(x,y)
	if board.stage.horz then
		shots.add(shots.create(x,y,.75))
		shots.add(shots.create(x,y,.25))
	end
end

shots.split=function(x,y)
	if board.stage.horz then
		shots.add(shots.create(x,y,.74))
		shots.add(shots.create(x,y,.76))
	end
end

shots.cross=function(x,y)
	shots.add(shots.create(x,y,.151))
	shots.add(shots.create(x,y,.312))
	shots.add(shots.create(x,y,.687))
	shots.add(shots.create(x,y,.812))
end

shots.spread3=function(x,y)
	shots.add(shots.create(x,y,.75))
	shots.add(shots.create(x,y,.81))
	shots.add(shots.create(x,y,.69))
end

shots.spread3d=function(x,y)
	shots.add(shots.create(x,y,.75))
	shots.add(shots.create(x,y,.625))
	shots.add(shots.create(x,y,.875))
	shots.add(shots.create(x,y,.25))
	shots.add(shots.create(x,y,.375))
	shots.add(shots.create(x,y,.125))
end

shots.spread5=function(x,y)
	shots.add(shots.create(x,y,.75))
	shots.add(shots.create(x,y,.875))
	shots.add(shots.create(x,y,.625))
	shots.add(shots.create(x,y,.685))
	shots.add(shots.create(x,y,.81))
end

shots.spread5d=function(x,y)
	shots.add(shots.create(x,y,.75))
	shots.add(shots.create(x,y,.875))
	shots.add(shots.create(x,y,.625))
	shots.add(shots.create(x,y,.685))
	shots.add(shots.create(x,y,.81))
	
	shots.add(shots.create(x,y,0-.75))
	shots.add(shots.create(x,y,0-.875))
	shots.add(shots.create(x,y,0-.625))
	shots.add(shots.create(x,y,0-.685))
	shots.add(shots.create(x,y,0-.81))
end

shots.fan=function(x,y)
	for n=1,10 do
		shots.add(shots.create(x,y,0-.05*n))
	end
end




explode={}

explode.init=function()
	explode.all={}
end
explode.now=function(x,y,color)
	local ang=0
	
	if not color then color=10 end
	
	for n=1,8 do
		add(explode.all, explode.create(x,y,ang,color))
		ang+=.125
	end
end
explode.create=function(x,y,angle,color)
	local obj={}
	obj.pos={x=x+3,y=y+3}
	obj.speed=3
	obj.size=6
	obj.color=color
	
	obj.dx=cos(angle)*obj.speed
	obj.dy=sin(angle)*obj.speed
	
	return obj
end


explode.update=function()
	foreach(explode.all, function(obj) 
		obj.pos.x+=obj.dx
		obj.pos.y+=obj.dy
		obj.size-=1
		
		if obj.size<1 then obj.size=0 end
		if offscreen(obj.pos.x,obj.pos.y) then del(explode.all,obj) end
	end)

end

explode.draw=function()
	foreach(explode.all, function(obj)
		circfill(obj.pos.x, obj.pos.y, obj.size, obj.color)
	end)

end




--[[ LEVEL BUILDER ASDF ]]

-- minimum upper bar: 4
-- maximum lower bar: 114

-- minimum row left: 10
-- maximum row right: 110

-- max per row: 12

-- use color="x" to add a space between items


--stage1
stages.add({
	horz=true,
	boss=false,
	timelimit=30,
	bars={
		{color="red",pos=102},
		{color="blue",pos=108},
		{color="green",pos=114}
	},
	enemy={
		stages.build(15,30,{
			{color="x",style="s"},
			{color="red",style="s",delay=45},
			{color="red",style="s",delay=45},
			{color="red",style="s",delay=45},
			{color="red",style="s",delay=45},
			{color="x",style="s"},
			{color="blue",style="s",delay=45},
			{color="blue",style="s",delay=45},
			{color="blue",style="s",delay=45},
			{color="blue",style="s",delay=45},
		}),
		stages.build(15,40,{
			{color="x",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="x",style="s"},
			{color="blue",style="s"},
			{color="blue",style="s"},
			{color="blue",style="s"},
			{color="blue",style="s"},
		}),
	}
})




--stage2
stages.add({
	horz=true,
	boss=false,
	timelimit=30,
	bars={
		{color="red",pos=102},
		{color="blue",pos=108},
		{color="green",pos=114}
	},
	enemy={
		stages.build(15,20,{
			{color="x",style="s"},
			{color="x",style="s",delay=45},
			{color="x",style="s",delay=45},
			{color="x",style="s",delay=45},
			{color="x",style="s",delay=45},
			{color="green",style="split"},
		}),
		stages.build(15,30,{
			{color="x",style="s"},
			{color="x",style="s",delay=45},
			{color="red",style="s",delay=45},
			{color="red",style="s",delay=45},
			{color="white",style="b",delay=45},
			{color="x",style="s"},
			{color="white",style="b",delay=45},
			{color="blue",style="s",delay=45},
			{color="blue",style="s",delay=45},
			{color="x",style="s",delay=45},
		}),
		stages.build(15,40,{
			{color="x",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="x",style="s"},
			{color="x",style="s"},
			{color="x",style="s"},
			{color="blue",style="s"},
			{color="blue",style="s"},
			{color="blue",style="s"},
		}),
	}
})





--stage3
stages.add({
	horz=true,
	boss=false,
	timelimit=30,
	bars={
		{color="green",pos=4},
		{color="red",pos=108},
		{color="blue",pos=114}
	},
	enemy={
		stages.build(15,35,{
			{color="x",style="s"},
			{color="green",style="sp3"},
			{color="x",style="s"},
			{color="x",style="s"},
			{color="x",style="s"},
			{color="green",style="sp3"},
			{color="x",style="s"},
			{color="x",style="s"},
			{color="x",style="b"},
			{color="green",style="sp3"},
		}),
		stages.build(15,45,{
			{color="x",style="s"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
		}),
		stages.build(15,55,{
			{color="x",style="s"},
			{color="x",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="white",style="b"},
			{color="red",style="s"},
			{color="red",style="s"},
			{color="red",style="s"},
		}),


	}
})


--stage4
stages.add({
	horz=true,
	boss=false,
	timelimit=30,
	bars={
		{color="red",pos=4},
		{color="blue",pos=114}
	},
	enemy={
		stages.build(15,40,{
			{color="red",style="s"},
			{color="blue",style="sp3"},
			{color="x",style="s"},
			{color="red",style="s"},
			{color="white",style="b"},
			{color="red",style="s"},
			{color="x",style="s"},
			{color="blue",style="sp3"},
			{color="red",style="s"},
		}),
		stages.build(15,50,{
			{color="x",style="s"},
			{color="x",style="sp3"},
			{color="x",style="s"},
			{color="white",style="b"},
			{color="blue",style="sp3"},
			{color="white",style="b"},
		}),


	}
})


--stage5
stages.add({
	horz=true,
	boss=false,
	timelimit=30,
	bars={
		{color="red",pos=4},
		{color="blue",pos=10},
		{color="green",pos=16},
		{color="red",pos=102},
		{color="blue",pos=108},
		{color="green",pos=114},
	},
	enemy={
		stages.build(20,35,{
			{color="white",style="b"},
			{color="white",style="b"},
		}),
		stages.build(20,45,{
			{color="blue",style="s"},
			{color="blue",style="s"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="green",style="sp5d"},
			{color="white",style="b"},
			{color="white",style="b"},
			{color="red",style="s"},
			{color="red",style="s"},
		}),
		stages.build(20,55,{
			{color="x",style="s"},
			{color="x",style="s"},
			{color="x",style="b"},
			{color="x",style="b"},
			{color="white",style="b"},
			{color="x",style="b"},
			{color="x",style="b"},
			{color="white",style="b"},
			{color="white",style="b"},
		}),
		stages.build(20,65,{
			{color="x",style="s"},
			{color="x",style="s"},
			{color="x",style="b"},
			{color="x",style="b"},
			{color="x",style="b"},
			{color="x",style="b"},
			{color="x",style="b"},
		}),


	}
})









--[[ main menu ]]
mainmenu={}
mainmenu.update=function()
	if btnp(4) or btnp(5) then game.init() end
end

mainmenu.draw=function()
	if game.highscore>0 then
		print("high score "..game.highscore,30,85,6)
	end
	
	spr(64,35,30,8,3)
	rect(0,0,127,127,7)
	print("press <action> to start",20,70,7)
	
	print(version,55,110,5)
end

mainmenu.init=function()
	cart.update=mainmenu.update
	cart.draw=mainmenu.draw
end



--[[ end level ]]
endlevel={}
endlevel.init=function()
	shots.init()
	local stagetime=round((ticker-board.timer)/30)

	bonus.total=0
	bonus.nokillpoints=100
	bonus.perfectpoints=500
	
	bonus.quickpoints=0
	if stagetime<60 then bonus.quickpoints=25 end
	if stagetime<30 then bonus.quickpoints=75 end
	if stagetime<20 then bonus.quickpoints=100 end

	if bonus.perfect then bonus.total+=bonus.perfectpoints else bonus.perfectpoints=0 end
	if bonus.nokill then bonus.total+=bonus.nokillpoints else bonus.nokillpoints=0 end
	if bonus.quick then bonus.total+=bonus.quickpoints else bonus.quickpoints=0 end

	game.score+=bonus.total
	
	
	cart.update=endlevel.update
	cart.draw=endlevel.draw
end

endlevel.update=function()
	enemy.all={}
	if btnp(5) then 
		if game.stage>=5 then 
			thankyou.init() 
		else	
			game.init() 
		end
		
	end
	game.update()
end

endlevel.draw=function()
	game.draw()
	
	print("stage "..game.stage.." complete",30,30,10)
	print("accuracy bonus "..bonus.perfectpoints,20,45,7)
	print("speed bonus "..bonus.quickpoints,30,55,7)
	print("no death bonus "..bonus.nokillpoints,25,65,7)
	print("press <x> to continue",20,85,6)
	
end



--[[ game over ]]
gameover={}
gameover.init=function()
	cart.update=gameover.update
	cart.draw=gameover.draw
	
	explode.now(player.pos.x, player.pos.y, 10)
end

gameover.update=function()
	if btnp(5) then _init() end
	
	explode.update();
end

gameover.draw=function()
	print("final score "..game.score,25,50,7)
	
	if game.score>=game.highscore and game.score>0 then
		print("new high score!",25,60,10)
		game.highscore=game.score
	end
	
	explode.draw();
	
end



--[[ game over ]]
thankyou={}
thankyou.init=function()
	cart.update=thankyou.update
	cart.draw=thankyou.draw
end

thankyou.update=function()
	enemy.all={}
	if btnp(5) then _init() end
end

thankyou.draw=function()
	print("thank you for playing",20,30,10)
	print("more levels coming soon",18,40,7)

	print("final score "..game.score,25,55,7)
	
	if game.score>=game.highscore and game.score>0 then
		print("new high score!",25,65,10)
		game.highscore=game.score
	end
end





--[[ loop ]]

--------init
function _init()
	cls()
	stars.init()
	game.reset()
	--board.init()
	player.create()
	mainmenu.init()
end


--------update
function _update()
	ticker+=1
	cart.update()
end


--------draw
function _draw()
	cls()
	
	stars.draw()
	cart.draw()
	
end





--[[ utility ]]

function homing_update(target_x,target_y,prox,bullet)
	if not bullet.angle then bullet.angle=0 end
	
	local newangle = atan2(target_x-bullet.pos.x, target_y-bullet.pos.y)
	
	bullet.angle = homing_lerp(bullet.angle, newangle, prox)
	bullet.pos.x += bullet.speed * cos(bullet.angle)
	bullet.pos.y += bullet.speed * sin(bullet.angle)
end

function homing_lerp(angle1, angle2, t)
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


function merge(t1,t2)
	for key,val in pairs(t2) do
		t1[alivekey]=val
	end	
	
	return t1
end




function offscreen(x,y)
	--screen={x=2,y=3,w=128,h=118,mid=60}
	if (x<screen.x or x>screen.w or y<screen.y or y>screen.h) then 
		return true
	else
		return false
	end
end


function overmid(v)
	if(v>screen.mid) then 
		return true
	else
		return false
	end	
end

function getcolors(c)
	local b=0
	local d=0

	if (c=="red") then
		b=8
		d=2
	elseif (c=="blue") then
		b=12
		d=1
	elseif (c=="green") then
		b=11
		d=3
	elseif (c=="white") then
		b=6
		d=5
	end
	
	return b,d
end

function random(min,max)
	n=round(rnd(max-min))+min
	return n
end

function randomxy()
	rx=random(screen.x,screen.w)
	ry=random(screen.y,screen.h)
	return rx,ry
end


--anim(object, start frame, number of frames, speed (in frames per second), [flip])
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

--collision check with other object, not wall/boundaries
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

function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end









__gfx__
0000000000000000112233440000000000000000088888000ccccc000bbbbb000aaaaa000aaaaa000aaaaa000aaaaa0000000000000000000000000000000000
000000000004600011223344000000000000000088787880cc7c7cc0bb7b7bb0aaaaaaa0aa1a1aa0aa1a1aa0aa111aa000000000000000000000000000000000
000000000004600055667788000000000000000088878880ccc7ccc0bbb7bbb0aa1a1aa0aaa1aaa0a11111a0a1aaa1a000000000000000000000000000000000
000000000049960055667788000000000000000088777880cc777cc0bb777bb0a11a11a0aa111aa0a11111a0a1a1a1a000000000000000000000000000000000
0000000000499600ccbbaa99000000000000000088777880cc777cc0bb777bb0aa1a1aa0aa111aa0aa111aa0a1aaa1a000000000000000000000000000000000
0000000004555660ccbbaa99000000000000000088777880cc777cc0bb777bb0aaaaaaa0aa111aa0aaa1aaa0aa111aa000000000000000000000000000000000
0000000004444560ddeeff000000000000000000288888201ccccc103bbbbb309aaaaa909aaaaa909aaaaa909aaaaa9000000000000000000000000000000000
0000000000000000ddeeff0000000000000000000222220001111100033333000999990009999900099999000999990000000000000000000000000000000000
00000000007000000000000000000000077000009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000777000000000000000000007aa700009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000777000000000000000000007aa700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777770000000000000000000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000ee000009900999904444400099999904009040400000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ea7e00009999999904000099999999990099900000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000e7ae00009994499090400909994994994099999000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000ee000009940049090099009999999990994499900000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000940049990099009999999999994499000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000994499990900409994994990999990400000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999999999000040999999990009990000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009999009900444440099999904040900400000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000099000090000009000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000040009999990000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000444040900444400000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000009940940099004000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009049900040099004000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000009040444000444400000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000040000009999990000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000990090000009000000000000000000000000000000000000000000000000000000000000000000000000
000000ccccccccccccccccc08888888888888888888bbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000
000000cccccccccccccccccc8888888888888888888bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000
000000cc77777777777777cc8877777777777777788bb77777777777777bb0000000000000000000000000000000000000000000000000000000000000000000
00000ccc77777777777777c8887777777777777778bbb77777777777777bbb000000000000000000000000000000000000000000000000000000000000000000
00000cc777777777777777c8877777777777777788bb777777777777777bbb000000000000000000000000000000000000000000000000000000000000000000
0000ccc7777777777777778887777777777777778bbb777777777777777bb0000000000000000000000000000000000000000000000000000000000000000000
0000cc77777cccccc7777c8877777888888888888bb77777bbbbbb7777bbb0000000000000000000000000000000000000000000000000000000000000000000
0000cc7777ccccccc7777c8877778888888888888bb7777bbbbbbb7777bb00000000000000000000000000000000000000000000000000000000000000000000
000ccc7777777777777778887777888777777778bbb7777777777777bbbb00000000000000000000000000000000000000000000000000000000000000000000
000cc777777777777777c8877777887777777788bb77777777777777bb0000000000000000000000000000000000000000000000000000000000000000000000
00ccc77777777777777c8887777888888777778bbb7777bbbbbb7777bbb000000000000000000000000000000000000000000000000000000000000000000000
00cc777777777777777c8877777888888777788bb77777bbbbbb7777bbb000000000000000000000000000000000000000000000000000000000000000000000
00cc777777777777777c8877778888888777788bb7777bbbbbbb7777bb0000000000000000000000000000000000000000000000000000000000000000000000
0cc77777ccccc7777778877777777777777778bb7777777777777777bb0000000000000000000000000000000000000000000000000000000000000000000000
0cc77777cccccc7777c8877777777777777788bb777777777777777bbb0000000000000000000000000000000000000000000000000000000000000000000000
ccc7777cc00cc777778887777777777777778bbb7777777777777bbbb00000000000000000000000000000000000000000000000000000000000000000000000
ccccccccc00ccccccc8888888888888888888bbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000
ccccccccc0cccccccc8888888888888888888bbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0001000031770317703177031770317702e7002e7002e7002e7002e7002e7002e7002e7002e7002e7002e7002f7002f7001810000000000000000000000000000000000000000000000000000000000000000000
00010000195701857018570175701657015570135701257011570105700e5700d5700b5700a57008570075700557004570025700157001570015700a500046000950009500095000950008500085000000000000
000100001e770117701e77011770117701b77011770117701977011770117701177017770107700f7700f7700e770147700e7700d7700c770107700b7700a7700a7700a770097700877008770077700677006770
000100000367004670046700567006670076700867008670096700a6700c6700e6700e67011670126701467016670186701a6701d6701f670216702467026670286702b6702e6703167034670376703a6703d670
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

