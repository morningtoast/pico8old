pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--mass360
--brian vaughn, 2016

--[[
	design and programmed by brian vaughn
	@morningtoast
	http://www.morningtoast.com

	music by brian follick
	@gnarcade_vgm
]]


version=1.3
t=0
debug=false

cart={}
cart.update=function() end
cart.draw=function() end

drain={x=64,y=64,rad=2}

--level=1
--stage=1
origin={x=64,y=64}
rail={rad=55,pos={x=64,y=64},col=7}
musicon=true
autofire=true



--[[ player ]]
player={t=0}

player.init=function()
	player.canfire=true
	player.healtimer=45
	player.hurt=false
	player.bullets={}
    player.pos={x=0,y=0}
    player.angle=.30
    player.btimer=0
    player.brate=4
    player.bspeed=3
	
end


player.shootbullet=function(x,y,angle,speed,size)
    local obj={}

    obj.pos={x=x,y=y}
    obj.hitbox={x=0,y=0,w=0,h=0}
    obj.speed=speed
    obj.angle=angle
	obj.size=size


    add(player.bullets, obj)
end

player.hit=function()
	player.flash=true
	player.hurt=true
	player.canfire=false
	
	sfx(1)
	
	hud.clock.s-=20 --penalty seconds for getting hit
end

player.update=function()
	player.col=7
    
    --movement
    if btn(1) or btn(2) then 
		player.angle+=-.008
	elseif btn(3) or btn(0) then
		player.angle+=.008
	end
	
	player.pos.x = cos(player.angle) * rail.rad + rail.pos.x;
	player.pos.y = sin(player.angle) * rail.rad + rail.pos.x;
	
	--shot fire
	if player.brate==player.btimer  then
		if player.canfire and (btn(4) or autofire) then
			player.shootbullet(player.pos.x, player.pos.y, player.angle, player.bspeed, 1)
		end
		
		player.btimer=0
	end

    player.btimer+=1
    
    
    --player bullets
    foreach(player.bullets, function(obj) 
        local newangle = atan2(origin.x-obj.pos.x, origin.y-obj.pos.y)
		obj.pos.x += 3 * cos(newangle)
		obj.pos.y += 3 * sin(newangle)
		
		if incircle(obj.pos.x, obj.pos.y, drain.x, drain.y, drain.rad) then
			del(player.bullets, obj)
		end

    end)
	
	--player damage delay
	if player.hurt then
		
	
		if player.healtimer<=0 then
			
			player.canfire=true
			player.hurt=false
			player.healtimer=45
		end
		
		player.healtimer-=1
	end
	
	debug=player.canfire
	
	player.t+=1
end

player.draw=function()
    --player circle
	
	if player.hurt then 
		rail.col=10 
		player.col=10
		
		if player.flash then
			player.flash=false
			rectfill(0,0,127,127,8)
		end
	else 
		if hud.clock.m<1 then 
			rail.col=8
			player.col=8
		else
			rail.col=7 
			player.col=7
		end
	end
	
	circ(64,64,rail.rad,rail.col) --rail
	
	if not player.hurt then
   		circfill(player.pos.x,player.pos.y,3,player.col)
		circfill(player.pos.x,player.pos.y,1,6)
	else
		circfill(player.pos.x,player.pos.y,3,player.col)
	end
	
	
	
	
	--bullets
	foreach(player.bullets, function(obj)
        circfill(obj.pos.x, obj.pos.y, obj.size, 7)
    end)
end





--[[ enemy ]]
enemy={all={},bullets={},core={},hitflash=0,coreflash=0,corecolor=9,timer=0,spawn=0,canfire=false}
enemy.init=function()
    pwg.bullets.all={}
	
    --bullet sequences
    pwg.pattern.new("spread",{shots=2,size=2,spread=.125})
	pwg.pattern.new("fan",{shots=7,size=2,spread=.0625})
    pwg.pattern.new("omni",{shots=9,size=3,spread=.125})
	pwg.pattern.new("burst",{shots=3,interval=6,size=2})
	pwg.pattern.new("laser",{shots=3,interval=5,size=3})
	
	pwg.sequence.new("spread", 30) --sequencename, timebetween cycles
	pwg.sequence.add("spread", "spread", 1, 0) --sequencename, patternname, bulletspeed, postwait
	
	pwg.sequence.new("burst", 30)
	pwg.sequence.add("burst", "burst", 2, 0)
	
	pwg.sequence.new("omni", 60)
	pwg.sequence.add("omni", "omni", 1, 0)
	
	pwg.sequence.new("laser", 120)
	pwg.sequence.add("laser", "laser", 2, 0)
	
	pwg.sequence.new("fan", 120)
	pwg.sequence.add("fan", "fan", 1, 0)
	
	pwg.sequence.new("omnilaser", 120)
	pwg.sequence.add("omnilaser", "omni", 3, 0)
	pwg.sequence.add("omnilaser", "laser", 2, 30)
end

enemy.randcoord=function()
    local sx=random(40,90)
	local sy=random(40,90)
    
    return sx,sy
end

enemy.populate=function(stage)
	enemy.all={}
	pwg.all={}


    --blobs
    for n=1,stage.blob do
		sx, sy=enemy.randcoord()
		local sw=random(8,12)
		
		add(enemy.all, {pos={x=sx,y=sy}, rad=sw, col=15,bcol=15, hp=stage.hp, hitbox={x=0,y=0,w=sw,h=sw}})
	end
	
	--bursts
    for n=1,stage.burst do
		sx, sy=enemy.randcoord()
		local sw=random(4,8)
		local gun=pwg.gen.create("burst", sx, sy, rnd(1), {cycle=random(30,50)})

		add(enemy.all, {pos={x=sx,y=sy}, rad=sw, col=2,bcol=8, gun=gun, hp=stage.hp+3, hitbox={x=0,y=0,w=sw,h=sw}})
	end
	
	--spread
    for n=1,stage.spread do
		sx, sy=enemy.randcoord()
		local sw=random(4,6)
		local gun=pwg.gen.create("spread", sx, sy, rnd(1), {cycle=random(30,50),color=8})

		add(enemy.all, {pos={x=sx,y=sy}, rad=sw, col=4,bcol=9, gun=gun, hp=stage.hp+4, hitbox={x=0,y=0,w=sw,h=sw}})
	end
	
	--omni
    for n=1,stage.omni do
		sx, sy=enemy.randcoord()
		local sw=random(4,6)
		local gun=pwg.gen.create("omni", sx, sy, rnd(1), {cycle=random(30,50),color=12})

		add(enemy.all, {pos={x=sx,y=sy}, rad=sw, col=4,bcol=9, gun=gun, hp=stage.hp+4, hitbox={x=0,y=0,w=sw,h=sw}})
	end
	
	--core
    for n=1,stage.core do
		local sx=64
		local sy=64
		
		while sx>=59 and sx<=69 do sx=random(52,75) end
		while sy>=59 and sy<=69 do sy=random(52,75) end
		
		
		--random(55,75)
		local sw=random(10,12)
		local tg=0
		
		if stage.coreshot then
			if stage.coreshot=="laser" or stage.coreshot=="fan" or stage.coreshot=="omnilaser" then tg=1 end
		    local gun=pwg.gen.create(stage.coreshot, sx, sy, rnd(1), {cycle=random(30,50),target=tg,color=11})
		end
		
		add(enemy.all, {pos={x=sx,y=sy}, rad=sw, col=15,bcol=15,hp=stage.hp, hitbox={x=0,y=0,w=sw,h=sw}})
		add(enemy.all, {pos={x=sx,y=sy}, core=true, rad=3, col=8,bcol=8, gun=gun, hp=stage.hp+7, hitbox={x=0,y=0,w=sw,h=sw}})
		
		enemy.core={pos={x=sx,y=sy}, core=true, rad=3, col=8}
	end
	
	enemy.timer=0
	enemy.canfire=false
end

enemy.killall=function()
	--local te=#enemy.all
	foreach(enemy.all, function(obj)
		make_explosion_ps(obj.pos.x,obj.pos.y)
	end)
	
	hud.clock.s+=(#enemy.all*2) --seconds to add to clock for each enemy on the board when core is killed
	
	pwg.all={}
	enemy.all={}
	pwg.bullets.all={}
	
	if levels.next() then
		levels.load()
	else
		if level<5 then
			act.display()
		else
			game.win()
		end
	end
	
	
	
end


enemy.addblob=function()
	sx, sy=enemy.randcoord()
	local sw=random(8,12)
	
	add(enemy.all, {pos={x=sx,y=sy}, rad=sw, col=15,bcol=15, hp=5, hitbox={x=0,y=0,w=sw,h=sw}})
end


function debug_hitbox(obj,c) 
	local color=c or 11
	rect(obj.pos.x+obj.hitbox.x,obj.pos.y+obj.hitbox.y, obj.pos.x+obj.hitbox.w,obj.pos.y+obj.hitbox.h, color)
end

enemy.update=function()
	
	--flashing core
	if enemy.coreflash==2 then
		if enemy.corecolor==8 then enemy.corecolor=10 else enemy.corecolor=8 end
		enemy.coreflash=0
	end
	enemy.coreflash+=1
	
	
	
	if enemy.spawn==150 then 
		enemy.addblob()
		enemy.spawn=0
	end
	
	enemy.hitflash=0
	debug=enemy.hitflash
	foreach(enemy.all, function(blob)
		foreach(player.bullets, function(bullet)
			
			if incircle(bullet.pos.x, bullet.pos.y, blob.pos.x, blob.pos.y, blob.rad+1) then
				del(player.bullets, bullet)
				
				if blob.core then
					enemy.hitflash=1
					sfx(0) 
				elseif blob.gun then 
					sfx(3)
				else
					sfx(4)
				end
				
				
				blob.hp-=1
				
				if blob.hp<=0 then
					make_explosion_ps(blob.pos.x,blob.pos.y)
					--del(pwg.all, box.gun)
					
					if blob.core then
						enemy.killall()
					else
						if blob.gun then 
							del(pwg.all, blob.gun) 
							hud.clock.s+=3
						end
						del(enemy.all, blob)
					end
				end
			end
		
		end)
	end)
	
	enemy.timer+=1
	enemy.spawn+=1
end


enemy.draw=function()
	foreach(enemy.all, function(obj)
		if obj.core then 
			obj.col=enemy.corecolor 
			debug=obj.pos.x..","..obj.pos.y 
		end
	
		
		circfill(obj.pos.x, obj.pos.y, obj.rad, obj.col)
		circ(obj.pos.x, obj.pos.y, obj.rad, obj.bcol)
		if obj.gun then 
			print("\134",obj.pos.x, obj.pos.y,obj.bcol)
		end
	end)

	circfill(enemy.core.pos.x, enemy.core.pos.y, enemy.core.rad, enemy.corecolor)
	--debug_hitbox(enemy.core,8)
	
	if enemy.hitflash>0 then
		rectfill(0,0,127,127,5)
	end
	
	 
	
end



--[[ level builder ]]
-- hp value applied to blobs. burst+3, spread+4, core+7
levels={all={},name="legs"}
levels.init=function()
	levels.all={}
    level=1
	stage=1
	
    --level1, legs
    add(levels.all, {stages={}})
    levels.addstage(1, {hp=4, blob=5, burst=2, spread=0, omni=0, core=1, coreshot=false})
    levels.addstage(1, {hp=4, blob=8, burst=3, spread=0, omni=0, core=1, coreshot=false})
    levels.addstage(1, {hp=4, blob=9, burst=4, spread=0, omni=0, core=1, coreshot=false})
    levels.addstage(1, {hp=4, blob=9, burst=5, spread=0, omni=0, core=1, coreshot=false})
    levels.addstage(1, {hp=5, blob=12, burst=4, spread=2, omni=0, core=1, coreshot=false})
    
    --level2, arms
    add(levels.all, {stages={}})
    levels.addstage(2, {hp=5, blob=12, burst=5, spread=1, omni=0, core=1, coreshot=false})
    levels.addstage(2, {hp=5, blob=12, burst=4, spread=2, omni=0, core=1, coreshot=false})
    levels.addstage(2, {hp=5, blob=14, burst=5, spread=2, omni=0, core=1, coreshot="omni"})
    levels.addstage(2, {hp=6, blob=14, burst=4, spread=3, omni=0, core=1, coreshot="omni"})
    levels.addstage(2, {hp=6, blob=15, burst=4, spread=4, omni=1, core=1, coreshot="omni"})
	
	--level3, chest
    add(levels.all, {stages={}})
    levels.addstage(3, {hp=7, blob=20, burst=5, spread=5, omni=1, core=1, coreshot="omni"})
    levels.addstage(3, {hp=7, blob=20, burst=4, spread=3, omni=1, core=1, coreshot="fan"})
    levels.addstage(3, {hp=7, blob=20, burst=5, spread=5, omni=1, core=1, coreshot="fan"})
    levels.addstage(3, {hp=8, blob=20, burst=4, spread=4, omni=1, core=1, coreshot="laser"})
    levels.addstage(3, {hp=8, blob=20, burst=4, spread=5, omni=1, core=1, coreshot="laser"})
	
	
	--level4, head
    add(levels.all, {stages={}})
    levels.addstage(4, {hp=10, blob=20, burst=5, spread=2, omni=1, core=1, coreshot="laser"})
    levels.addstage(4, {hp=10, blob=25, burst=6, spread=3, omni=1, core=1, coreshot="laser"})
    levels.addstage(4, {hp=10, blob=25, burst=6, spread=4, omni=1, core=1, coreshot="omnilaser"})
    levels.addstage(4, {hp=15, blob=30, burst=8, spread=4, omni=1, core=1, coreshot="omnilaser"})
    levels.addstage(4, {hp=20, blob=40, burst=8, spread=2, omni=2, core=1, coreshot="omnilaser"})
    
    
    
    return #levels.all
end

levels.addstage=function(levelid, settings) 
	add(levels.all[levelid].stages, settings) 
end

levels.next=function()
	local sc=#levels.all[level].stages
	
	if level==1 then levels.name="legs" end
	if level==2 then levels.name="arms" end
	if level==3 then levels.name="body" end
	if level>3 then levels.name="head" end
		
	
	if sc==stage then
		hud.status[level]=true
	
		level+=1
		stage=1
		
		return false
	else
		stage+=1
		
		return true
	end
end

levels.load=function()
	player.bullets={}
	enemy.populate(levels.all[level].stages[stage])
end


--[[ hud map ]]
hud={status={}}


hud.init=function()
	hud.clock={m=2,s=59,t=0,str="2:59"}
	hud.status[1]=false
	hud.status[2]=false
	hud.status[3]=false
	hud.status[4]=false
end

hud.update=function()
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
	
	
	
	if hud.clock.m<0 then
		game.over()
	end

	hud.clock.t+=1
end

hud.draw=function()
	print(hud.clock.str, 110,5,10)
	print(level.."-"..stage, 110,120,10)

	if hud.status[4] then c=11 else c=8 end
	if level==4 then c=10 end
	rect(5,5,11,10,c) --head

	if hud.status[3] then c=11 else c=8 end
	if level==3 then c=10 end
	rect(5,12,11,20, c) --body
	
	if hud.status[2] then c=11 else c=8 end
	if level==2 then c=10 end
	rect(1,12,3,18,c) --arms
	rect(13,12,15,18,c)
	
	if hud.status[1] then c=11 else c=8 end
	if level==1 then c=10 end
	rect(5,22,7,28,c)--legs
	rect(9,22,11,28,c)
end


--[[ game play ]]
game={t=0}
game.title=function()
	enemy.init()
	levels.init()
	levels.load()
	player.init()
	play_music(16)
    
	hud.init()
	
	cart.update=function()
		if btnp(5) or btnp(4) then
			act.display()
		end
	end
	
	cart.draw=function()
		spr(17, 30, 35, 9, 5)
		circ(64,64,rail.rad,10) --rail
		
		center_text("inspired by",82,6)
		center_text("one dad's fight",88,6)
		
		center_text("\151 to start",103,7)
		
		--print("  inspired by\none dad's fight\n\n   ",36,85,6)
		print("V"..version,110,120,5)
	end

end

game.play=function()
	play_music(16)
	levels.load()

	cart.update=function()
		player.update()
		enemy.update()
		hud.update()
		pwg.update()
		update_psystems()
		
		if enemy.timer>15 then enemy.canfire=true end
		
		game.t+=1
	end
	
	cart.draw=function()
		
		enemy.draw()
		player.draw()
		pwg.draw()
		hud.draw()
		
		for ps in all(particle_systems) do draw_ps(ps) end
	end

end

credits="CODE+ART\nBRIAN VAUGHN\n@MORNINGTOAST\n\nMUSIC\nBRIAN FOLLICK\n@GNARCADE_VGM"
game.over=function()
	game.t=0
	play_music(5)
	cart.update=function()
		if game.t>60 then
			if btnp(5) then	_init()	end
		end
		
		game.t+=1
	end
	
	cart.draw=function()
		local textcolor1=0
		local textcolor2=0
		
		if game.t>15 then 
			textcolor1=5
			textcolor2=2
		end
		
		if game.t>25 then 
			textcolor1=6
			textcolor2=8
		end
		
		print("i'm sorry, he's gone.\nyou did all you could.",5,10,textcolor1)
		
		print("it won.\nbut we didn't lose.\nthe memories will\nlive forever.\n\ntime is a luxury.",50,30,textcolor2)
		
				
		--print("a game by\nbrian vaughn\n@morningtoast",50,80,5)
		
		
		if game.t>60 then
			print(credits,5,80,5)
			
			print("\151",110,115,7)
		end
	end
end


game.win=function()
	local total=framestotime(game.t)
	game.t=0
	play_music(8)
	
	
	cart.update=function()
		if game.t>60 then
			if btnp(5) then	_init()	end
		end
		
		game.t+=1
	end
	
	cart.draw=function()
		local textcolor1=0
		local textcolor2=0
		local textcolor3=0
		
		if game.t>15 then 
			textcolor1=5
			textcolor2=1
			textcolor3=2
		end
		
		if game.t>25 then 
			textcolor1=6
			textcolor2=12
			textcolor3=14
		end
		
		
		print("i don't believe it.\nall scans are clean.\nyou did it.",5,5,textcolor1)
		
		print("no. he did it.\nbut we always were\na great team.",50,35,textcolor2)
		
		print("i love you, dad.\nlets go home.",50,60,textcolor3)
		
		--print("total time: "..total,50,85,10)
		
		--print("a game by\nbrian vaughn\n@morningtoast",50,98,5)
		
		if game.t>60 then
			print(credits,5,80,5)
			print("\151",110,115,7) 
		end
	end
end



--[[ story acts ]]
act={timer=0,delay=50}
act.update=function()
	if act.timer>=15 then 
		act.colora=5
		act.colorb=1
	end
	
	if act.timer>=25 then 
		act.colora=6
		act.colorb=12
	end
	
	if act.timer>=act.delay then 
		if btnp(5) then game.play() end
	end
	
	act.timer+=1
end
act.display=function()
	act.timer=0
	play_music(3)
	act.colora=0
	act.colorb=0
	act[level]()
end

act.continue=function()
	if act.timer>=act.delay then
		print("\151",110,115,7) 
	end
end


act[1]=function()
	cart.update=act.update
	cart.draw=function()
		print("it's spreading fast.\nthere's not much we can do.",5,10,act.colora)
		
		print("we have to.\ni'm his son.\ni have to try.",50,30,act.colorb)
		
		if autofire then
			print("we'll keep you shooting.\nyou must hit the flashing\ncore to stop it.",5,60,act.colora)
		else
			print("we'll do all we can to help.\nyou must shoot the flashing\ncore. use \142 to attack.",5,60,act.colora)
		end
		
		print("thank you.\ni'm coming dad.\nkeep fighting.",50,90,act.colorb)
		
		act.continue()
	end
end

act[2]=function()
	cart.update=act.update
	cart.draw=function()
		print("that helped. good job.\nbut its getting more aggressive.\nbe careful.",5,10,act.colora)
		
		print("what more can i do?",50,40,act.colorb)
		
		print("shoot the core fast to\nbuy you both more time.",5,60,act.colora)
		
		print("hang in there, pop.",50,85,act.colorb)
		
		act.continue()
	end
end

act[3]=function()
	cart.update=act.update
	cart.draw=function()
		print("his vitals are improving.\nkeep hitting it hard.\nbut expect more resistance.",5,10,act.colora)
		
		print("i've got to move\nfaster, hit harder.",50,40,act.colorb)
		
		print("it's aggressive but it's not\nsmart. find a safe spot and\nstudy its attack.",5,60,act.colora)
		
		print("time is a luxury.",50,90,act.colorb)
		act.continue()
	end
end

act[4]=function()
	cart.update=act.update
	cart.draw=function()
		print("it's only in his brain now.\nthe rest has been cleared.",5,10,act.colora)
		
		print("so close.\ngotta keep fighting.",50,30,act.colorb)
		
		print("this is it. good luck.",5,60,act.colora)
		
		print("lets end this, dad.\nmom is waiting.",50,80,act.colorb)
		act.continue()
	end
end





--[[ loops ]]

-- pause menu options
menuitem(1, "toggle music", function() 
	if musicon then musicon=false music(-1) else musicon=true end
end)
menuitem(2, "toggle auto-fire", function() 
	if autofire then autofire=false else autofire=true end	
end)


-- boot
function _init()
	game.title()
end

function _update()
	cart.update()
	t+=1
end


function _draw()
    cls()
	cart.draw()
end



--[[ utility ]]
function play_music(id)
	if musicon then music(id) end
end

function framestotime(frames)
	local secs=flr(frames/30)
	local min=0
	local sec=0
	local time=0
	
	if secs > 59 then
		min = flr(secs/60)
		sec = secs-(flr(secs/60)*60)

		if sec < 10 then sec = "0"..sec	end

		time = min..":"..sec
	else
		if secs < 10 then sec = "0"..secs end
		time = "0:"..sec;
	end

	return time
end

function center_text(s,y,c) print(s,64-(#s*2),y,c) end

function incircle(ox,oy,cx,cy,cr)
	local dx = abs(ox-cx)
	local dy = abs(oy-cy)
	local r = cr

	local k = r/sqrt(2)
	if dx <= k and dy <= k then return true end
end

function random(min,max)
	n=round(rnd(max-min))+min
	return n
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return flr(num * mult + 0.5) / mult
end




--[[ pwg ]]
pwg={pattern={},sequence={},all={},gen={},bullets={all={}}}
pwg.update=function()
	pwg.gen.update()
	pwg.bullets.update()

end

pwg.draw=function()
	pwg.bullets.draw()
end

--[[ pwg pattern sequence ]]
--pwg.pattern.new(patternname, settingsobj) --{shots=1,interval=5,size=2,spread=.25}
pwg.pattern.new=function(pname, psettings)
	pwg.pattern[pname]=psettings
end

pwg.pattern.get=function(pname)
	return pwg.pattern[pname]
end

--pwg.sequence.new(squencename, waitframes)
pwg.sequence.new=function(sname, wait)
	pwg.sequence[sname]={list={},wait=wait}	
end


--pwg.sequence.add(squencename, patternname, bulletspeed, waitframes)
pwg.sequence.add=function(sname, pname, bulletspeed, waitframes)
	add(pwg.sequence[sname].list, {p=pname, spd=bulletspeed, wait=waitframes})
end
	
	
--[[ pwg generators ]]	
	
--pwg.gen.create("burstspread", 10, 15, .5)
pwg.gen.create=function(seqid, x, y, angle, custom)
	local gen={}
	
	gen.state=0 --0=waiting, 1=firing
	gen.seqpattern=1
	gen.seqid=seqid
	gen.cycle=pwg.sequence[seqid].wait
    gen.sequence=pwg.sequence[seqid].list
	gen.pos={x=x,y=y}
    gen.timer=0
    gen.angle=angle
    gen.seqlength=#gen.sequence
	gen.fired=0
	gen.init=true
	gen.target=0

	
	if custom then
		for k,v in pairs(custom) do gen[k]=v end
	end
	

	add(pwg.all, gen)
	
	
	
	return gen
end

--[[
	pwg.pattern.new("burst",{shots=3,interval=6,size=2})
	pwg.pattern.new("spread",{shots=3,size=2,spread=.025})

	pwg.sequence.new("burstspread")
	pwg.sequence.add("burstspread", "burst", 2, 30)
	pwg.sequence.add("burstspread", "spread", 2, 10)

	pwg.gen.create("burstspread", 25, 60, 0)
]]


pwg.gen.update=function()

	foreach(pwg.all, function(gen)

		local slot=gen.sequence[gen.seqpattern] --gets active record in sequence
		local pattern=pwg.pattern[slot.p] --gets active pattern settings
		
		if gen.seqpattern==1 then 
			if gen.init then
				slot.wait=-1
			else 
				slot.wait=gen.cycle 
			end
			
		end
		
		if gen.state==0 then
            if gen.timer>slot.wait then
                gen.state=1 
                gen.timer=pattern.interval
				gen.fired=pattern.shots
            end
        end
		
		--debug=pattern.shots
		
		if gen.state==1 then
			if gen.timer==pattern.interval and gen.fired>0 then
			
				if enemy.canfire then
					if gen.target>0 then
						gen.angle = atan2(player.pos.x-gen.pos.x, player.pos.y-gen.pos.y)
					end
				
					pwg.trigger(gen.pos.x, gen.pos.y, gen.angle, slot.spd, pattern, gen.color)
				end
		
				if pattern.spread then
					gen.fired=0
				else 
					gen.fired-=1
				end
				
				gen.timer=0
			end
			
			if gen.fired<=0 then 
            	--go to next pattern
				
            	--gen.next() 
				gen.seqpattern+=1
				gen.state=0
				gen.timer=0
				
				if gen.seqpattern>gen.seqlength then 
					gen.seqpattern=1 
					gen.init=false
				end
            end
		end
		
		--debug=gen.cycle
       
        gen.timer+=1
    end)
	
end



--[[ pwg fire shots ]]
pwg.trigger=function(x,y,angle,speed,pattern,color)

    if pattern.spread then
        pwg.spreadshot(x,y,angle,speed,pattern.shots,pattern.spread,pattern.size,color)   
    else
		pwg.singleshot(x,y,angle,speed,pattern.size,color)		
    end
end


--[[ factory for bullet types ]]
pwg.singleshot=function(x,y,angle,speed,size,color)
    add(pwg.bullets.all, pwg.bullets.create(x,y,angle,speed,size,color))
end

pwg.spreadshot=function(x,y,angle,speed,count,dist,size,color)
    if count%2!=0 then count-=1 end
    
    local perside=count/2
    local list={}
    
    for n=1,perside do add(list, angle-dist*n) end
    add(list,angle)
    for n=1,perside do add(list, angle+dist*n) end
    
    foreach(list, function(sdir)
        add(pwg.bullets.all, pwg.bullets.create(x,y,sdir,speed,size,color))
    end)
end





--[[ pwg bullet creation ]]

pwg.bullets.create=function(x,y,angle,speed,size,color)
	if not color then color=14 end

    local obj={}

    obj.pos={x=x,y=y}
    obj.speed=speed
    obj.angle=angle
	obj.size=size
	obj.color=color
    
    obj.tx=cos(obj.angle)*obj.speed
	obj.ty=sin(obj.angle)*obj.speed
	
	local hbsize=obj.size-1
	
	obj.hitbox={x=obj.pos.x-hbsize,y=obj.pos.y-hbsize,w=size,h=size}

    return obj
end



pwg.bullets.update=function()
    foreach(pwg.bullets.all, function(obj) 
        obj.pos.x+=obj.tx
        obj.pos.y+=obj.ty
		
		if incircle(obj.pos.x, obj.pos.y, player.pos.x, player.pos.y, 4) and player.hurt~=true then
			player.hit()
		end
    
		if obj.pos.x>130 or obj.pos.x<0 then del(pwg.bullets.all, obj) end
		if obj.pos.y>130 or obj.pos.y<0 then del(pwg.bullets.all, obj) end
    end)
end

pwg.bullets.draw=function()
	foreach(pwg.bullets.all, function(obj)
		
        circfill(obj.pos.x, obj.pos.y, obj.size, obj.color)
    end)
end


--[[ particle system library ----------------------------------- ]]


function make_explosion_ps(ex,ey)
	local ps = make_psystem(0.1,0.5, 9,14,1,3)
	sfx(2)
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



function draw_ps_fillcirc(ps, params)
	for p in all(ps.particles) do
		c = flr(p.phase*count(params.colors))+1
		r = (1-p.phase)*p.startsize+p.phase*p.endsize
		circfill(p.x,p.y,r,params.colors[c])
	end
end




__gfx__
000000008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
007007008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000008c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777777700007777777777000077777777000000007777777700000077777777000000000000000000000000000000000000000000000000000000
00000000777777777770007777777777000077777777000000777777777770007777777777700000000000000000000000000000000000000000000000000000
00000000777777777770007777777777000077777777000007777777777770077777777777700000000000000000000000000000000000000000000000000000
00000000007777777770077777777770000077777777700007777770077770077777700777700000000000000000000000000000000000000000000000000000
00000000007777777777077777777770000777777777700077777770000000777777700000000000000000000000000000000000000000000000000000000000
00000000007777777777077777777770000777707777700077777777700000777777777000000000000000000000000000000000000000000000000000000000
00000000007777077777777707777770000777707777770007777777777000077777777770000000000000000000000000000000000000000000000000000000
00000000007777077777777707777770000777707777770007777777777700077777777777000000000000000000000000000000000000000000000000000000
00000000007777007777777707777770007777707777770000777777777770007777777777700000000000000000000000000000000000000000000000000000
00000000007777007777777007777770007777777777770000077777777770000777777777700000000000000000000000000000000000000000000000000000
00000000007777000777777007777770007777777777777000000777777770000007777777700000000000000000000000000000000000000000000000000000
00000000007777000777777007777770007777000777777000000007777770000000077777700000000000000000000000000000000000000000000000000000
00000000007777000777770007777770077777000777777007777007777770077770077777700000000000000000000000000000000000000000000000000000
00000000777777700077770077777777777777707777777707777777777770077777777777700000000000000000000000000000000000000000000000000000
00000000777777700077770077777777777777707777777707777777777700077777777777000000000000000000000000000000000000000000000000000000
00000000777777700007700077777777777777707777777700777777770000007777777700000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000008888888000000008888888000000888888000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888888888880000888888888800008888888880000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888888888888008888888888800088888888888000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888880088888088888800000800888880088888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888800088888088888800000000888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000088888088888000000008888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000088880088888000000008888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000088888800888888888888008888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000088888880888888888888808888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000088888888888888888888808888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000088888888888008888888888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888800088888088888000888880888880008888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888880088888088888000888880888880088888800000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888888888888008888888888800088888888888000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000888888888880008888888888000008888888880000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000008888888000000088888880000000888888000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000100003807035070310702f0702b070280702607024070210701e0703a0003a0003a0003a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000207702277022770227701f7701c7701a77019770197701977018770177701477012770147701577014770107700e7700d7700b7700a7700a7700a7700a77008770067700577005770047700477003770
000100001067010670106700f6700f6700f6700e6700d6700c6700b6700a670096700867007670076700667005670046700367003670036700367003670036700367003670036700367003670036700467004670
00010000171701717016170161701417012170101700e1700b1700817006170051700317002170000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011400000277102771187031870300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010b00002633026322263121c3002233022315243302432224312283021f3301f3221f3122e3022233022322223120030024300243021f3301f3221f3122b302223302232222312003022433024322243122d300
010b0000273302732226330263222233022315243302432224312283022b3302b3222b3122e3022733027322273120030024300243022633026322263122b30224330243222431200302213301f3221d3122d300
010b0000263302632224330243222233022315243302432224312283021f3301f3221f3122e3022233022322223120030024300243021f3301f3221f3122b302223302232222312003022433024322243122d300
010b0000263302632224330243222233022315243302432224312283021f3301f3221f3122e3022233022322223120030024300243021f3301f3221f3122b302223302232222312003021d3301d3221d3122d300
010e00002635026342263321d3502134222335243502434224332243121f3301f3221f3122e3022235022342223322232222312243021b3501d3421f3322131222350223321d3501d03227350273322435024032
010e00002635026342263321d3502134222335243502434224332243121f3301f3221f3122e3022235022342223322232222312243021f3501f3421f3321f3122235022330223222201224350243302432224012
010e00002635026342263321d3502134222335243502434224332243121f3301f3221f3122e302223502234222332223222231224302183001830218302183022135021342213322132221012210322105221062
01110000267502675026740267402673226732267222672226712267122b7002b7002b7502b7502b7422b72227750277502774027740277322773227722277222771227712003000030024750247502474024720
01110000217502175021740217402173221732217222172221712217122b7002b7002775027750277422772226750267502674026740267322673226722267222671226712207000030029750297502974029720
010e00101a3401b3401d3401b3401d3401f3401d3401f340213401f34021340223402b340263411a3411a3451a3001a300003001a300003000030000300003000030000300003000030000300003000030000300
011100000775507745077450773507755077450774507735077550774507745077350775507745077450773509755097450974509735097550974509745097350a7550a7450a7450a7350a7550a7450a7450a735
011100000f7550f7450f7450f7350f7550f7450f7450f7350f7550f7450f7450f7350f7550f7450f7450f7350e7550e7450e7450e7350e7550e7450e7450e7350e7550e7450e7450e7350e7550e7450e7450e735
010b00000f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f725
010b00000e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e725
010b0000137601372513760137251376013725137601372513760137251376013725157601572516760167251376013725137601372513760137250e7600e7251676016725157601572513760137250e7600e725
010b00001176011725117601172511760117251176011725117601172511760117251376013725157601572511760117251176011725137601372515760157251676016725157601572518760187251676016725
010b00000f7600f7250f7600f7250f7600f7250f7600f7250f7600f7250f7600f725117601172513760137250f7600f7250f7600f725117601172513760137251676016725157601572513760137251176011725
010b00000e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250e7600e7250f7600f72511760117251376013725157601572516760167251876018725167601672515760157250c7600c7250e7600e725
010e00000f3600f2000f3650f3650f360073050f3650f3650f360073050f3650f3650a3650c2650e3650f3650c360073050c3650c3650c360073050c3650c3650c360073050c3650c3650f3650e2650c36505365
010e0000073600f200073650736507360073050736507365073600730507365073650736007305073650736503360033400332003310053600534005320053100a3600a3400a3200a31009360093400932009310
010e0000033600f200033650336503360073050336503365033600730503365033650a3650c2650e3650f36505360053500534005330053200531005312053120c300073050c3050c3050f305052000c3050a305
010e00000736007305073650736507360073050736507365073600730507365073650736007305073650736507360073050736507365073600730507365073650736007305073650736507360073050736507365
010e00000a3600a6050a3650a3650a360073050a3650a3650a360073050a3650a3650a360073050a3650a36500360073050036500365003600730500365003650036007305003650036500360073050036500365
010e00002b0702b0602b0502b0422b0322600024000260002700026000260702d0002b0702d0702e0703007030032300122e070290002d0702b000260702e0702e0322e0122d070000002b0702d0002607026000
010e0000270702706027050270422703226000240002600027000260002607027070290702b0702d0703307033032330122e0002e000300703003230012260002e0722e0322e0102d0702d0322d0122907029032
010e00001d4201d4201d4201d4121d4121d4121d4121f4021f4001f4001f4001f4021f4021f4021f4021f4021a4201a4201a4201a4121a4121a4121a4122e4042e4042e4042d404004042b4042d4040540426404
010e00001f4201f4201f4201f4121f4121f4121f4121f4021f4001f4001f4001f4021f4021f4021f4021f402224202242022420224122241222412224122e4042e4042e4042d404004042b4042d4042640426404
010e00001d4201d4201d4201d4121d4121d4121d4121f4021f4001f4001f4001f4021f4021f4021f4021f4021a4201a4201a4201a4121a4121a4121a4122e4041f4301f4201f4101d4301d4201d4101b4301b420
010e000022070220451d070220551d4001d07024055260551f0001f0002207522005290752900024075260751f070210752207526075260051f05022055260001d0001f0752107527075220752d0021d07529002
010e00001f0701f03522070210551d4001d050180551a0551f0001b0501d0751f055240552900024075260752b07029075270752607529070270702607524070270702607524075220751f075210702207524050
010e000022070220351d050220551d4001d05024055260551f0001f00022075220052905529000240552605527050270322702227012270121f00022005260001d0001f0052100527005220052d0021d00529002
010e00001336007361073000736007340073350736007340073300732207315073050732507305073150730507325073050731507305073250730507315073050732507305073150730507325073050731507305
010e00000336003361073000336003340033350336003340033300332203315073050332507305033150730503325073050331507305033250730503315073050332507305033150730503325073050331507305
010e00000536005361073000536005340053350536005340053300532205315073050532507305053150730505325073050531507305053250730505315073050532505315053350532505345053550536505375
01100000373262b3161f3002b306003000030000300003000030000300373062b306373062b306393262d326393062d3060030000300003000030000300003000030000300003000030000300003000030000300
010e000013773137033e6253e62532653047033e625137730c703137733e6053e625326530c7033e6253e62513773137033e6251377332653117033e625137730c703137733e6053e62532653326033e6253e625
010e000013773137033e6253e62532653047033e625137730c703137733e6053e625326530c7033e6253e62513773137033e6251377332653117033e625137730c703137733e6053e62532653326333265332633
010e000013773137033e6253e60532653047033e6251377313703217531d75318753326530c7033e6253e60513773137033e6251377332653117033e6251376313703137733e6053e62532653326033e6253e605
010e000013773137033e6253e60532653047033e625137731370318753217531d753326530c7033e6251377332653137031377313703326531370313773137033265313703137733e60532653137733264332663
010e000013773137033e6253e60532653047033e625137731370313703137731d703326530c7033e625137731f6401d6301f6201c610106101061010600106003260318600326531377332653326333265332633
010e000013773137033e6253e60532653047033e6251370313773137033e6253e605326530c7033e625056051377313703326531d600326233265310600326533260332653137731370332653326333265332633
010e000013773137033e6253e6051f7733e6253e625137731370313773137731d7033e62513773137031370313773137033e6253e6051f7733e6253e625137733260332653137731370332653326333265332633
010e0000326533265313773326533260332603326431370332603137033263332603326030c703326233e605326033260332613326033260313703326131370332603137033260332603326030c703326033e605
010e000013773137033e6253e60532653047033e625137731370313703137731d703326530c7033e625137731f6401d6301f6201c61010610106101060010600326031860032603137032b0501d0510f05102051
010e0000326533260313773326533260313773326531370332603137033262332603326030c703326133e605326033260313703326033260313703326031370332603137033260332603326030c703326033e605
010d000013773137033e6253e62532653047033e6253e62513773137033e6253e625326530c7033e6253e62513773137033e6253e62532653047033e6253e62513773137033e6253e62532653047033e6253e625
010d00002633026322263122433026330273352b3302b3222b3122e3001f3301f33021330213302e3302e3222e3222e3122d300243022d3302d3222d3122b3022b3302b3222b312003022933029322293122d300
010d0000137601374213725007001376013742137250070013760137421372500700137601374213725007001376013742137250070013760137421372500700137601374213725007000e7600f7421172513730
010d0000187601874218725007001876018742187250070018760187421872500700187601874218725007001876018742187251870018760187421872500700187601874218725187001d7601b7421a72518730
010d0000117601174211725007001176011742117250070011760117421172500700117601174211725007001176011742117251870011760117421172500700117601174211725187000c7600e7420f72511730
010d0000167601674216725007001676016742167250070016760167421672500700167601674216725007000f7600f7420f725007000f7600f7420f725007000f7600f7420f7250070013760117420f72511730
010d000029230292222921227230292302b2352e2302e2222e2122e20022230222302123021230262302622226222262122d200242022423024222242122b202222302222222212002022123021222212122d200
010d00002b2402b2321f2252b2402b2301f2252b2402b2322b2222e200222401f2402124022240262402623226222262121f2401f2352122022222222321f230222402223222222002022124021232212222d200
010d00002b2402b2321f2252b2402b2321f2252b2402b2322b2222e200222401f2402124022240262402623226222262121f2301f2352123022222222121f2302e2402d2322b222292402d2302b2222924227230
__music__
01 0a184344
00 0a194344
00 0a1a4344
02 0d1b4344
02 4d5b4344
01 52111444
02 4a121544
02 4d5b4344
00 383d4344
01 39373e44
00 3a373f44
00 3b373e44
02 3c373f44
00 41424344
00 41424344
00 5f6e6265
00 1f326265
01 1f2d2164
00 202e2263
00 1f2d2164
00 202e2265
00 1f336265
00 1f2d2124
00 202e2223
00 1f2d2124
00 202e2225
00 1c2f266c
00 1d30276c
00 1e312844
00 1f2d2124
00 202e2223
00 1f2d2124
00 202e2225
00 1c2f2644
00 1d302744
00 1e352844
00 34290f44
00 34290e44
00 342a0f44
02 342b1044
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

