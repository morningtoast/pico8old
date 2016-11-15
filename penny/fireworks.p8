pico-8 cartridge // http://www.pico-8.com
version 8
__lua__


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

p1={
	st=0,
	t=0,
	x=-8,
	y=120,
	stop=flr(rnd(80))+30,
	active=false,
	wait=flr(rnd(90))+180,
	reset=function()
		p1.x=-8
		p1.r=true
		p1.stop=flr(rnd(80))+30
		p1.t=0
		p1.wait=flr(rnd(90))+180
		p1.st=0
	end,
	_update=function()
		p1.r=false
		
		if p1.st==0 then
			if p1.t>=p1.wait then p1.st=1 p1.t=0 end
		end
		
		if p1.st==1 then
			p1.r=true
			p1.x+=1	
			if p1.x==p1.stop then 
				p1.st=2 
				p1.t=0
			end
			
			if p1.x>130 then 
				p1.reset()
				p1.st=0
				p1.t=0 
			end
		end
		
		if p1.st==2 then
			if p1.t>90 then
				p1.st=1
				p1.t=0
			end
		end

		
		p1.t+=1
		
	end,
	_draw=function()
		--print(p1.x.."/"..p1.stop,30,30,10)
		if p1.r then
			anim(p1, 1, 8, 10)	
		else
			print("\135",p1.x,p1.y-8,14)
			spr(1,p1.x,p1.y)
		end
	end
}



-- fireworks
-- by saccharine

--[[
simple fireworks siimulation
check http://www.lexaloffle.com/bbs/?uid=12981
for updates
]]
t=0
pt=0
function p_create(x,y,color,speed,direction)  
  p={}
  p.x=x
  p.y=y
  p.color=color
  p.dx=cos(direction)*speed
  p.dy=sin(direction)*speed
  return p
end

function _init()
cy=10
  fireworks={}
  for i=1,5 do
    particules={}
    for i=1,200 do
      add(particules,p_create(0,127,0,100,.75))
    end
    add(fireworks,particules)
  end

	mouse.init()
end

function _draw()
	local tree=3
	local sky=12
	--local sky2=8
	--local sky3=14
	
	if t>30 then sky=9 end
	if t>60 then sky=14  tree=2 end
	if t>90 then sky=8 end
	if t>120 then sky=1  tree=2 end
	if t>150 then sky=0  tree=1 end
	
  	cls()
	palt(0,false)
	palt(13,true)

	pal(2,tree)
	rectfill(0,0,127,127,sky)
	
	circfill(70,cy,9,10)
	map(0,0, 0,96, 16,4)
	

	p1._draw()
	pal()
	
	
	
  for particules in all(fireworks) do
    for p in all(particules) do
      pset(p.x,p.y,p.color)
    end
  end
	
	--pset(mx,my,7) --show mouse pointer debug
	
	
end

function _update()
	mx,my = mouse.pos()
	local b = mouse.button()
	
	if btnp(4) then
		mx=rnd(126)+1
		my=rnd(120)+1
		b=1
	end
	
	cy+=1
  for particules in all(fireworks) do
    for p in all(particules) do
      p.dy+=.3    -- gravity
      p.x+=p.dx   -- update position
      p.y+=p.dy 
      if (p.y>127) del(particules,p) -- and del it if under the horizon
    end
    
  end
		
   if b==1 then
		if #particules<20 then
		  c=flr(rnd(7))+8
		  if c==13 then c=14 end
		  for i=1,160 do
			add(particules, p_create(mx,my,c,rnd(4)+1,rnd(1)))
		  end
		  sfx(0)
		end	
			
	end

		
	
	p1._update()
	
	t+=1
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
	spr(o.a_fr,o.x,o.y,1,1,fl)
end

__gfx__
00000000ddddddddd4444dddd4444dddd4444dddddddddddd4444dddd4444dddd4444ddd00000000000000000000000000000000000000000000000000000000
00000000d4444dddd4fffdddd4fffdddd4fffdddd4444dddd4fffdddd4fffdddd4fffddd00000000000000000000000000000000000000000000000000000000
00000000d4fffddd441f1ddd441f1ddd441f1dddd4fffddd441f1ddd441f1ddd441f1ddd00000000000000000000000000000000000000000000000000000000
00000000441f1ddd44fffddd4400fddd44fffddd441f1ddd44fffddd44ff00dd44fffddd00000000000000000000000000000000000000000000000000000000
0000000044fffddd43333ddd43003ddd43333ddd44fffddd43333ddd033300dd43333ddd00000000000000000000000000000000000000000000000000000000
0000000043333dddd00bbdddddddddddd00bbddd43333dddd3300dddddddddddd3300ddd00000000000000000000000000000000000000000000000000000000
00000000d33bbdddddd0ddddddddddddddd0ddddd33bbddd0ddddddddddddddd0ddddddd00000000000000000000000000000000000000000000000000000000
00000000d0dd0dddddddddddddddddddddddddddd0dd0ddddddddddddddddddddddddddd00000000000000000000000000000000000000000000000000000000
b3bb3bbb004444007a0000000c7cc7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3333333304999950accc00000c7cc7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54545454499944956cccc0000c7cc7c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444449945956cccc10000611600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444494999956ccc1111000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45454545499599956001111000aa9900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54545454049999506000000000a99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45454545005555006000000000099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22224222111111116004444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
24222242111111116041111400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
222222224141414160411114cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
221221222414242460411114cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
212222125152525260411114cccccccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1222122212221222604111141c1c1c1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
212121212121212160415514c1c1c1c1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1111111111111111604555541c1c1c1c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45454545888888887a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4454445488888888abbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44454444888888886bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444445888888886bbbb30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45444454888888886bbb333300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54445444888888886003333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
45454545888888886000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
54545454888888886000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000
dddddddddddddddddddddddddddddddd999999999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddddddddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddddddddddddddddddddddddddddddddaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddddd2dddddddddddddddddddddddddd999992999999999999999999999999990000000000000000000000000000000000000000000000000000000000000000
ddddd2ddddddddddddddddddddddddddeeeee2eeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
ddddd2ddddddddddddddddddddddddddaaaaa2aaaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
dddd222dddddddddddddddddddddddddaaaa222aaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddddd22dddddddddddddddddddddddddeeeee22eeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
dddd222dddddddddddddddddddddddddaaaa222aaaaaaaaaaaaaaaaaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddddd222ddddddddddddd2ddddddddddeeeee222eeeeeeeeeeeee2eeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
dddd222dddddddddddddd2ddddddddddaaaa222aaaaaaaaaaaaaa2aaaaaaaaaa0000000000000000000000000000000000000000000000000000000000000000
ddd222222ddddd2ddddd22dddddddddd999222222999992999992299999999990000000000000000000000000000000000000000000000000000000000000000
dddd2222dddddd2dddddd22ddddddddd999922229999992999999229999999990000000000000000000000000000000000000000000000000000000000000000
ddd2222d2ddddd2ddddd222dddd2dddd999222292999992999992229999299990000000000000000000000000000000000000000000000000000000000000000
dd2d22222dddd222ddddd2ddddd2ddddaa2a22222aaaa222aaaaa2aaaaa2aaaa0000000000000000000000000000000000000000000000000000000000000000
ddd22222d2dddd22dddd222dddd2dddd999222229299992299992229999299990000000000000000000000000000000000000000000000000000000000000000
ddd222222dddd2222dd2222ddd222dddaaa222222aaaa2222aa2222aaa222aaa0000000000000000000000000000000000000000000000000000000000000000
dd2222222ddddd222ddd2222ddd22ddd992222222999992229992222999229990000000000000000000000000000000000000000000000000000000000000000
d222d22222ddd222ddd222222d2222dd922292222299922299922222292222990000000000000000000000000000000000000000000000000000000000000000
ddd222222ddd222222dd222dddd222dd999222222999222222992229999222990000000000000000000000000000000000000000000000000000000000000000
dd2d2222d2ddd2222dd222222d222ddd992922229299922229922222292229990000000000000000000000000000000000000000000000000000000000000000
d222222222dd2222d2ddd222d222222d922222222299222292999222922222290000000000000000000000000000000000000000000000000000000000000000
2d2222222d22d22222d22222222222d2292222222922922222922222222222920000000000000000000000000000000000000000000000000000000000000000
2222222222222222222d222222222222222222222222222222292222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
22222222222222222222222222222222222222222222222222222222222222220000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
4041424340414243404142434041424300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051525350515253505152535051525300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6061626360616263606162636061626300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7071727370717273707172737071727300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0001000003630096300e6400c65009630057000300005700077000470001700027000470009700057000370007700037000a70002600026000160001600000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
