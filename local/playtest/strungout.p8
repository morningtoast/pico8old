pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- strung out in heaven's high
-- made by sean & ian for #agbic
-- inspired by daruma studio's famicase

function entity(vx,vy,vc)
local e={}
e.p={}
e.p[1]=vx
e.p[2]=vy
e.a=0
e.s=1
e.c=vc
e.children={}
return e
end

function vectorize(ve)
ve.points={}
ve.draw=drawvvector
return ve
end

function lerp(vfrom,vto,vt)
return vfrom+vt*(vto-vfrom)
end

function rotate(vp,va)
local ca=cos(va)
local sa=sin(va)
local p={}
p[1] = ca*vp[1]-sa*vp[2]
p[2] = sa*vp[1]+ca*vp[2]
return p
end

function vvadd(va,vb)
return {va[1]+vb[1],va[2]+vb[2]}
end
function vvsub(va,vb)
return {va[1]-vb[1],va[2]-vb[2]}
end
function vvmul(vv,vs)
return {vv[1]*vs,vv[2]*vs}
end
function vvlerp(va,vb,vt)
return{lerp(va[1],vb[1],vt),lerp(va[2],vb[2],vt)}
end

function addvinteraction(i,v,txt)
local interaction={}
interaction.txt=txt
interaction.v=v
add(interactions.a[i],interaction)
end

function _init()
cls()
cartdata("sweetheartsquadvstrungout")
scenes={}

-- scale vars
cellvgap=24 -- distance between cells
cellvspace=3 -- only cells divisible by cellvspace can contain stuff
mapvsize=31 -- distance in either direction from center
nipvdrain = 0.005 --speed at which catnip drains
nipvdrainvbuild = 0.003 --nipvdrain increase on each nip pickup
nipvgain = 10 --nip gained from pickups
initialvnip = 7.5
emptyvchance = 0.6 --chance for cells to spawn empty
satvchance = 0.1
nipvchance = 0.05
photovchance = 0.025
avspeed=0.01 --rotation speed
pvspeed=0.7 --movement speed

cellvgapvh=cellvgap/2
cellvfull=cellvgap*cellvspace

interactions={}
interactions.empty=0
interactions.cat=1
interactions.nip=2
interactions.sat=3
interactions.photo=10
interactions.rmin=2
interactions.rmax=18
interactions.a={}
for i=0,interactions.rmax do
interactions.a[i]={}
end

addvinteraction(0,"misc","nothing interesting here")
addvinteraction(1,"misc","nothing interesting here")
addvinteraction(2,"misc","nothing interesting here")
addvinteraction(3,"misc","nothing interesting here")

addvinteraction(6,"good","i'm happy. hope you're happy, too.")
addvinteraction(6,"good","moondust will cover you.")
addvinteraction(6,"good","it's safe out here.")

addvinteraction(8,"bad","hitting an all-time low?")
addvinteraction(8,"bad","they don't realize you're alive.")
addvinteraction(8,"bad","your circuit's dead. there's something wrong.")
addvinteraction(8,"bad","my mama said not to mess with you.")

addvinteraction(7,"bad","oh, no. not again.")
addvinteraction(7,"bad","i'll never be free.")
addvinteraction(7,"bad","there's nothing here for me.")

addvinteraction(4,"bad","the shrieking of nothing is killing me.")
addvinteraction(4,"bad","this chaos is killing me.")
addvinteraction(4,"bad","let me go home.")

addvinteraction(9,"good","i've heard a rumour from ground control.")
addvinteraction(9,"good","i'm coming home.")
addvinteraction(9,"good","it's not too late for me.")

addvinteraction(10,"blue","a picture of a japanese girl in synthesis.")
addvinteraction(10,"blue","a picture of home.")
addvinteraction(10,"blue","a picture of ground control.")
addvinteraction(10,"blue","a picture of something familiar.")
addvinteraction(10,"blue","a picture of a guitar.")
addvinteraction(10,"blue","a picture of a bag of catnip.")
addvinteraction(10,"blue","a picture of my old spaceship.")
addvinteraction(10,"blue","a picture of my parent's house.")
addvinteraction(10,"blue","a picture of someone i barely remember.")
addvinteraction(10,"blue","a picture of a girl i met.")
addvinteraction(10,"blue","a picture of a dark room.")
addvinteraction(10,"blue","a picture of a my friend from back home.")
addvinteraction(10,"blue","a picture of nothing.")
addvinteraction(10,"blue","a picture of a skyline.")
addvinteraction(10,"blue","a picture of a martian spider.")
addvinteraction(10,"blue","a picture of the old band.")
addvinteraction(10,"blue","a picture of a man with a snow white tan.")
addvinteraction(10,"blue","a picture of darkness and disgrace.")
addvinteraction(10,"blue","a picture of a boy in bright blue jeans.")
addvinteraction(10,"blue","a picture of a femme fatale.")
addvinteraction(10,"blue","a picture of shiny silver legwarmers.")
addvinteraction(10,"blue","a picture of sterile skyscrapers.")
addvinteraction(10,"blue","a picture of the last few corpses.")
addvinteraction(10,"blue","a picture of templars and saracens.")
addvinteraction(10,"blue","a picture of a best laid plan.")

addvinteraction(11,"blue","where did this come from?")
addvinteraction(11,"blue","some trinket from a world beyond.")
addvinteraction(11,"blue","i can hear music...")

addvinteraction(12,"good","drifting through the cosmos feels so freeing.")
addvinteraction(12,"good","i can still see earth from here.")
addvinteraction(12,"good","things aren't so scary right now.")

addvinteraction(13,"good","the ship is holding out pretty well.")
addvinteraction(13,"good","plenty of supplies here for me.")
addvinteraction(13,"good","lots of interesting readings out here.")

addvinteraction(14,"good","be sweet, sweet dove.")
addvinteraction(14,"good","hello spaceboy.")
addvinteraction(14,"good","maybe everything is going to be fine.")

addvinteraction(15,"blue","the stars go on forever.")
addvinteraction(15,"blue","i have this overwhelming feeling inside me.")
addvinteraction(15,"blue","don't you want to be free?")

addvinteraction(16,"blue","just another piece of space junk.")
addvinteraction(16,"blue","maybe this means something.")
addvinteraction(16,"blue","why does this remind me of home?")

addvinteraction(17,"bad","i'm not getting a signal.")
addvinteraction(17,"bad","ground control? are you there?")
addvinteraction(17,"bad","this is the worst trip i've ever been on.")

addvinteraction(5,"blue","i ain't got no money.")
addvinteraction(5,"blue","i ain't got no hair.")
addvinteraction(5,"blue","send me up a drink.")
addvinteraction(5,"blue","give my wife my love.")

-- cells
cells={}
for x=-mapvsize,mapvsize do
cells[x]={}
for y=-mapvsize,mapvsize do
local cell={}
cell.icon=flr(rnd(interactions.rmax-interactions.rmin))+interactions.rmin+1
local r=rnd()
if r < emptyvchance then
cell.icon = interactions.empty
elseif r-emptyvchance < satvchance then
cell.icon = interactions.sat
elseif r-emptyvchance-satvchance < nipvchance then
cell.icon = interactions.nip
elseif r-emptyvchance-satvchance-nipvchance < photovchance then
cell.icon = interactions.photo
end


cell.x=x
cell.y=y
cell.used=false
cell.interact=interactions.a[cell.icon][flr(rnd()*#interactions.a[cell.icon])+1]

cells[x][y]=cell
end
end

bg={}
for x=0,127+cellvgap,cellvgap do
bg[x]={}
for y=0,127+cellvgap,cellvgap do
bg[x][y]={}
bg[x][y].p={x,y}
bg[x][y].r=0
bg[x][y].cell=nil
end
end

-- stars
stars={}
local numvstars=32
for i=1,sqrt(numvstars) do
for j=1,sqrt(numvstars) do
local c=i*j/numvstars
if c < 0.33 then
c=15
elseif c < 0.66 then
c=12
else
c=7
end
local star=entity((sin(i/sqrt(numvstars))+sin(j/(sqrt(numvstars)+1)))*255,(cos(j/sqrt(numvstars))+cos(i/(sqrt(numvstars)-1)))*255,c)
star.pvv=i*j/numvstars*0.9+0.1
star.ovp={star.p[1],star.p[2]}
add(stars,star)
end
end

parts={}
pulses={}

-- camera
cam=entity(0,0)
cam.pvstack={}
cam.avstack={}
cam.svstack={}
cam.sp={}
cam.sp[1]=0
cam.sp[2]=0
cam.nvstack=1
add(cam.pvstack,cam.sp)
add(cam.avstack,cam.a)
add(cam.svstack,cam.s)

cam.push = function(vp)
add(cam.avstack,cam.a)
add(cam.svstack,cam.s)
local p = vvmul(rotate(vp.p,cam.a),cam.s)
cam.s*=vp.s
cam.a+=vp.a
add(cam.pvstack,cam.sp)
cam.sp=vvsub(cam.sp,p)
camera(cam.p[1]+cam.sp[1],cam.p[2]+cam.sp[2])
cam.nvstack+=1
end

cam.pop = function()
local a=cam.avstack[cam.nvstack]
local s=cam.svstack[cam.nvstack]
local p=cam.pvstack[cam.nvstack]
cam.a=a
cam.s=s
cam.sp=p
camera(cam.p[1]+cam.sp[1],cam.p[2]+cam.sp[2])
del(cam.avstack,a)
del(cam.svstack,s)
del(cam.pvstack,p)
cam.nvstack-=1
end

-- player
cat=entity(0,0,7)
cat.nip=initialvnip
cat.nipw1=false
cat.nipw2=false
cat.pw=false
cat.vva=0
cat.vvp=0
cat.s = 0.33
cat.cell = nil
cat.talk={}
cat.draw=function(vc)
cam.push(vc)

--rings
color(0)
circfill(0,0,90*cam.s)
color(12)
circfill(0,0,66*cam.s)
for a=0.1,1,0.1 do
if a > cat.nip/10 then color(7) end
local b=a+time()/10
line(
77*cam.s*cos(b),77*cam.s*sin(b),
77*cam.s*cos(b+0.03),77*cam.s*sin(b+0.03)
)
end
color(7)
for a=0.0625,1,0.0625 do
local b=a+time()/5
line(
90*cam.s*cos(b),90*cam.s*sin(b),
90*cam.s*cos(b+0.03),90*cam.s*sin(b+0.03)
)
end
color(0)
circfill(0,0,60*cam.s)

drawvchildren(vc)

cam.pop()
end


--head and body
catvmesh=vectorize(entity(0,-20,7))
catvmesh.points={
{11,-11},
{-11,-11},
{-23,-20},
{-23,10},
{-10,21},
{-7,21},
{-7,37},
{0,43},
{7,37},
{7,21},
{10,21},
{23,10},
{23,-20},
{11,-11}
}

--left arm
local p2=vectorize(entity(-10,21,7))
p2.points={
{0,0},
{-5,7},
{-5,13}
}

--right arm
local p3=vectorize(entity(10,21,7))
p3.points={
{0,0},
{5,7},
{5,13}
}

--left earline
local p4=vectorize(entity(-12,-11,7))
p4.points={
{0,0},
{-11,7}
}

--right earline
local p5=vectorize(entity(12,-11,7))
p5.points={
{0,0},
{11,7}
}

--left eye
local p6=vectorize(entity(-13,0,7))
p6.points={
{0,0},
{-4,4},
{0,8},
{6,8},
{10,4},
{6,0},
{0,0}
}

--left pupil
local p7=vectorize(entity(-10,0,7))
p7.points={
{0,0},
{0,8}
}

--right eye
local p8=vectorize(entity(7,0,7))
p8.points={
{0,0},
{-4,4},
{0,8},
{6,8},
{10,4},
{6,0},
{0,0}
}

--right pupil
local p9=vectorize(entity(10,0,7))
p9.points={
{0,0},
{0,8}
}


--mouth
local p10=vectorize(entity(-3,16,7))
p10.points={
{0,0},
{3,-3},
{6,0}
}

--left leg
local p11=vectorize(entity(-7,37,7))
p11.points={
{0,0},
{-5,7},
{-5,13}
}

--right leg
local p12=vectorize(entity(7,37,7))
p12.points={
{0,0},
{5,7},
{5,13}
}

--tail
local p13=vectorize(entity(0,43,7))
p13.points={
{0,0},
{0,18}
}

--headline
local p14=vectorize(entity(-7,21,7))
p14.points={
{0,0},
{14,0}
}

add(cat.children,catvmesh)
add(catvmesh.children,p2)
add(catvmesh.children,p3)
add(catvmesh.children,p4)
add(catvmesh.children,p5)
add(catvmesh.children,p6)
add(catvmesh.children,p7)
add(catvmesh.children,p8)
add(catvmesh.children,p9)
add(catvmesh.children,p10)
add(catvmesh.children,p11)
add(catvmesh.children,p12)
add(catvmesh.children,p13)
add(catvmesh.children,p14)


-- palette stuff
palette={}
palette.a={}
add(palette.a,{0,1,7,12,15,"earth blue"})
add(palette.a,{0,2,6,8,5,"mars red"})
add(palette.a,{14,15,0,7,13,"jupiter pink"})
add(palette.a,{0,4,10,9,15,"saturn sienna"})
add(palette.a,{4,5,13,0,2,"uranus brown"})
add(palette.a,{1,12,13,7,15,"neptune navy"})
add(palette.a,{2,14,13,15,7,"pluto purple"})
add(palette.a,{8,1,12,15,0,"mercury i guess?"})
add(palette.a,{3,5,6,7,11,"venus verde"})
add(palette.a,{10,4,9,0,7,"sol yellow"})
add(palette.a,{6,5,0,7,0,"luna grey"})
add(palette.a,{0,1,7,12,15,"random"})
palette.set=function(v)
if palette.c != nil then
sfx(63,3)
end
palette.c=flr((v-1)%#palette.a+1)
dset(1,palette.c)

--random
if palette.c==#palette.a then
local a={}
for i=1,5 do
local colour
local valid=false
while not valid do
valid=true
colour=flr(rnd(16))
for j in all(a) do
if colour==j then
valid=false
break
end
end
end

palette.a[palette.c][i] = colour
add(a,colour)
end
end

for i=1,5 do
pal(palette.a[1][i],palette.a[palette.c][i])
end

end


local savedvpalette=dget(1)
-- make sure we don't boot with random palette
if savedvpalette==0 or savedvpalette==#palette.a then
savedvpalette=1
end
palette.set(savedvpalette)

-- menu scene
local menu={}
menu.o1=0
menu.o2=0
menu.u=function()
if btnp(0) then palette.set(palette.c-1) end
if btnp(1) then palette.set(palette.c+1) end

if btnp(2) then menu.o1-=1 sfx(63,3) end
if btnp(3) then
menu.o1+=1
sfx(63,3)
if menu.o1==2 then
scenes.current="game"
say(interactions.cat,"i'll stay clean tonight. just one last trip...")
end
end
menu.o1 = mid(-1,menu.o1,1)
menu.o2=lerp(menu.o2,menu.o1,0.1)
end

menu.d=function()
camera(0,0)
color(0)
for i=0,99 do
line(rnd(127),0,rnd(127),127)
line(0,rnd(127),127,rnd(127))
end

camera(0,menu.o2*127+flr(sin(time()/10)*5+0.5)+16)

sspr(96,0,30,30,64-14,64-15)
color(12)
printvol("\143 \143 in heaven's high \143 \143",9,80,0,12)
if btn(3) then
printvol("\148 credits",44,90,12,0)
else
printvol("\148 credits",44,90,0,12)
end
if btn(3) then
printvol("\131 play",44,97,12,0)
else
printvol("\131 play",44,97,0,12)
end
camera(0,menu.o2*127)

color(15)
line(5,20,10,20)
line(5,90,10,90)
line(122,20,117,20)
line(122,90,117,90)
line(5,20,5,25)
line(5,90,5,85)
line(122,20,122,25)
line(122,90,122,85)

if btn(3) then
printvol("\131 back",1,-25,12,0)
printvol("\131 start",1,225,12,0)
else
printvol("\131 back",1,-25,0,12)
printvol("\131 start",1,225,0,12)
end
if btn(2) then
printvol("\148 back",1,132,12,0)
else
printvol("\148 back",1,132,0,12)
end

color(12)
sspr(80,0,16,16,56,-100)
printvol("strung out on heaven's high\nwas made by sean & ian\nfor a game by its cover (#agbic)\nbased on a famicase entry\nby daruma studio",1,-72,0,12)
printvol("\nyou are the action cat\n\nhow to play:\n\n \139+\145: turn\n \148+\131: move\nz or x: interact\n\nfind nip to keep the trip going\nuse satellites as landmarks\ncollect photos of the past",1,142,0,12)
sspr(16*2,0,16,16,40,216)
sspr(16*3,0,16,16,56,216)
sspr(16*4,16,16,16,72,216)

camera(0,0)
color(12)
rectfill(0,111,127,127)
color(0)
circfill(10,119,7)
print("\139 "..palette.a[palette.c][6].." \145",52-#palette.a[palette.c][6]/2*4,117)
color(12)
circfill(10,119,2)
for i=1,palette.c do
local a = -i/#palette.a+0.2
pset(10.5+cos(a)*5,119.5+sin(a)*5,7)
end

end

local over={}
over.over=false
over.txt={}
over.u=function()
if not over.over then
over.time=time()
add(over.txt,"-- action cat to ground control")
add(over.txt,"-- transmission starting...")
add(over.txt,"-- sordid details following:")
add(over.txt,"")

if game.details.good == 0 then
add(over.txt,"i never done good things")
elseif game.details.good == 1 then
add(over.txt,"i done one good thing")
else
add(over.txt,"i done "..game.details.good.." good things")
end
add(over.txt,"")

if game.details.bad == 0 then
add(over.txt,"i never done bad things")
elseif game.details.bad == 1 then
add(over.txt,"i done one bad thing")
else
add(over.txt,"i done "..game.details.bad.." bad things")
end
add(over.txt,"")

if game.details.blue == 0 then
add(over.txt,"i never did anything")
elseif game.details.blue == 1 then
add(over.txt,"i one thing")
else
add(over.txt,"i did "..game.details.blue.." things")
end
add(over.txt,"out of the blue")
add(over.txt,"")

-- "endings"
if game.details.good> game.details.bad + game.details.blue then
-- good end
add(over.txt,"i'm happy")
add(over.txt,"hope you're happy too")
elseif game.details.blue > game.details.bad+game.details.good then
-- blue end
add(over.txt,"strung out in heaven's high")
add(over.txt,"hitting an all-time low")
elseif game.details.bad > game.details.good+game.details.blue then
-- bad end
add(over.txt,"the shrieking of nothing")
add(over.txt,"is killing me")
else
-- neutral end
add(over.txt,"i'm floating around my tin can")
add(over.txt,"and there's nothing i can do")
end
add(over.txt,"")
add(over.txt,"-- transmission ended")
add(over.txt,"-- action cat signed off")
add(over.txt,"")
add(over.txt,"")
add(over.txt,"press z+x to restart")


over.over=true
over.last=0
end

if time()-over.time > #over.txt then
if btn(4) and btn(5) then
run()
end
elseif time()-over.time > over.last then
if over.txt[over.last] != "" then
sfx(63,3)
end
over.last+=1
end
end

over.d=function()
camera(0,0)
color(0)
rectfill(0,0,127,127)
color(12)
for i=1,#over.txt do
if time()-over.time > i then
print(over.txt[i],1,i*6)
end
end
end

-- game scene
game={}
game.details={}
game.details.good=0
game.details.bad=0
game.details.blue=0
game.details.misc=0
game.u=function()

-- input
if btn(0) then cat.vva += avspeed end
if btn(1) then cat.vva -= avspeed end
if btn(2) then cat.vvp -= pvspeed end
if btn(3) then cat.vvp += pvspeed/3 end

--catnip
cat.nip -= nipvdrain

cat.nip=min(cat.nip,10)

if cat.nip < 2 then
if not cat.nipw2 then
cat.nipw2 = true
say(interactions.cat,"fading fast - need nip!")
end
else
cat.nipw2 = false

if cat.nip < 5 then
if not cat.nipw1 then
cat.nipw1 = true
say(interactions.cat,"running out of nip...")
end
else
cat.nipw1 = false
end
end

if cat.nip < 0 then
scenes.current="over"
end

-- higher=bouncier scale
cat.s=0.3+(sin(time())+1)*0.03*max(0,cat.nip-7)

if btnp(4) or btnp(5) then
if cat.cell != nil then
cellvinteract(cat.cell)
end
end

-- dialogue
if cat.talk.txt != nil then
if cat.talk.wait == 0 then
local s=""
local c=sub(cat.talk.txt,1,1)
while c != " " and c != "\n" and #cat.talk.txt > 0 do
printh(c)
s=s..c
cat.talk.txt=sub(cat.talk.txt,2,#cat.talk.txt)
c=sub(cat.talk.txt,1,1)
end
if c!="\n" then
s=s..c
end
cat.talk.txt=sub(cat.talk.txt,2,#cat.talk.txt)

-- line break
if cat.talk.w+#s > 25 then
cat.talk.txt2=cat.talk.txt2.."\n"
cat.talk.h+=1
cat.talk.w=0
end

if #s != 0 then
sfx(63,3)
cat.talk.txt2=cat.talk.txt2..s
cat.talk.w+=#s

if c == "\n" then
cat.talk.txt2=cat.talk.txt2..c
cat.talk.w=0
cat.talk.h+=1
end
end

-- clear
if time()-cat.talk.time > 2+#cat.talk.txt2/30 then
cat.talk.txt2=nil
cat.talk.txt=nil
cat.talk.h=0
cat.talk.w=0
end
cat.talk.wait=3
else
cat.talk.wait-=1
end
end

--pulses
for p in all(pulses) do
if time()-pulsevtime > p.o then
p.p=vvlerp(p.p,p.t,0.1/cellvspace)
end
end

-- parts
for p in all(parts) do
p.d = vvmul(p.d,0.95)
p.p = vvadd(p.p,p.d)
p.s *= 0.95
if p.s < 0.1 then
del(parts,p)
end
end

-- player
cat.vva *= 0.7
cat.vvp *= 0.9

cat.a += cat.vva

local ca=cos(cat.a-0.25)
local sa=sin(cat.a-0.25)
cat.p[1] += ca*cat.vvp
cat.p[2] += sa*cat.vvp

catvmesh.s=1+sin(time())/10

local d={cam.p[1],cam.p[2]}
cam.p = vvlerp(cam.p, vvadd(cat.p,{ca*-32,sa*-32}), 0.1)

cam.p[1] = lerp(cam.p[1], cat.p[1], 0.1)
cam.p[2] = lerp(cam.p[2], cat.p[2], 0.1)
d = vvsub(cam.p,d)

-- stars
for star in all(stars) do
star.ovp[1]=star.p[1]
star.ovp[2]=star.p[2]
star.p[1] -= d[1]*star.pvv
star.p[2] -= d[2]*star.pvv

if star.p[1] > 255 then
star.p[1] -= 255
star.ovp[1] -= 255
elseif star.p[1] < 0 then
star.p[1] += 255
star.ovp[1] += 255
end
if star.p[2] > 255 then
star.p[2] -= 255
star.ovp[2] -= 255
elseif star.p[2] < 0 then
star.p[2] += 255
star.ovp[2] += 255
end
end

-- bg
local rmin=6
local cmin=nil
d=vvsub(cat.p,cam.p)
for a=0,127+cellvgap,cellvgap do
for b=0,127+cellvgap,cellvgap do
-- get offset for camera
-- and distortion
local p=bg[a][b]
p.p[1]=a-cam.p[1]%cellvgap
p.p[2]=b-cam.p[2]%cellvgap
local t = abs(d[1]-p.p[1]+64-cellvgapvh)
local s = abs(d[2]-p.p[2]+64-cellvgapvh)
p.r = sqrt(s+t)
p.a = atan2(t,s)

t=flr((a+cam.p[1])/cellvgap)/cellvspace
s=flr((b+cam.p[2])/cellvgap)/cellvspace

-- check for actual cells
if t%1==0 and
s%1 == 0 and
t == mid(-mapvsize,t,mapvsize) and 
s == mid(-mapvsize,s,mapvsize) 
then
p.cell = cells
[flr(t)]
[flr(s)]

-- check for closest cell
if p.r < rmin then
rmin = p.r
cmin = p.cell
end
else
p.cell = nil
end

-- distort based on speed
p.r = p.r/8*cat.vvp*cat.nip/5
end
end

cat.cell=cmin

-- out of bounds warning
if cat.p[1]+64 < -(mapvsize+1)*cellvfull
or cat.p[2]+64 < -(mapvsize+1)*cellvfull
or cat.p[1]+64 > (mapvsize+1)*cellvfull
or cat.p[2]+64 > (mapvsize+1)*cellvfull then
if not cat.pw then
cat.pw=true
say(interactions.cat,"nothing out this way - i should head back.")
end
else
cat.pw=false
end
end

game.d=function()
camera(0,0)
if cat.nip < 3 then
color(0)
rectfill(0,0,127,127)
else
local c=(cat.nip-3)/7
c=min(1,1.1-c)
color(12)
for i=1,10*max(0,0.2-c) do
line(rnd(127),0,rnd(127),127)
line(0,rnd(127),127,rnd(127))
end
color(5)
for i=1,5*max(0,0.4-c) do
line(rnd(127),0,rnd(127),127)
line(0,rnd(127),127,rnd(127))
end
color(0)
for i=1,200*c do
line(rnd(127),0,rnd(127),127)
line(0,rnd(127),127,rnd(127))
end
end

drawvbg()
drawvstars()

o=entity(64,64)
cam.push(o)

cat.draw(cat)

cam.pop()

drawvicons()
drawvpulses()

if cat.nip < 2.1 then
camera(0,0)
local c=1-(cat.nip/2.1)
c*=c
color(0)
for i=1,200*c do
local j=rnd(127)
line(j,0,j,127)
j=rnd(127)
line(0,j,127,j)
end
end

color(12)
for p in all(parts) do
p.draw(p)
end

drawvtalk()

--drawvdebug() 
end

scenes["menu"]=menu
scenes["game"]=game
scenes["over"]=over
scenes.current = "menu"


music(0,0,1+2+4)

-- transition
for y=0,127 do
local p=entity(cat.p[1],cat.p[2]+y,0)
p.d={0,0}

p.s=rnd()
p.draw=function(p)
color(0)
line(cam.p[1],cam.p[2]+p.p[2],cam.p[1]+127,cam.p[2]+p.p[2])
end

add(parts,p)
end
end

function _update()
scenes[scenes.current].u()
end

function say(i,s)
cat.talk.icon=i
cat.talk.txt =s
cat.talk.txt2=""
cat.talk.h=0
cat.talk.w=0
cat.talk.wait=3
cat.talk.time=time() 
end

function cellvinteract(cell)
if cell.icon == interactions.empty then
--empty cell
elseif cell.icon == interactions.nip then
cat.nip+=nipvgain
game.details.bad+=1
cam.p[1] += rnd(15)-rnd(15)
cam.p[2] += rnd(15)-rnd(15)

addvpop()

say(cell.icon,"found some space catnip!")
nipvdrain+=nipvdrainvbuild
cell.icon=interactions.empty
elseif cell.icon == interactions.photo then
game.details.blue+=1
cam.p[1] += rnd(15)-rnd(15)
cam.p[2] += rnd(15)-rnd(15)

addvpop()

say(cell.icon,cell.interact.txt)
cell.icon=interactions.empty
elseif cell.icon == interactions.sat then
if not cell.used then
pulsevtime=time()
game.details.good+=1
end
local i=0
local num=0
for s=max(-mapvsize,cell.x-2),min(mapvsize,cell.x+2) do
for t=max(-mapvsize,cell.y-2),min(mapvsize,cell.y+2) do
i+=1
if cells[s][t].icon == interactions.sat then
if cells[s][t] != cell then
if not cells[s][t].used then
if not cell.used then
local p={}
p.s={cell.x,cell.y}
p.p={cell.x,cell.y}
p.t={s,t}
p.o=i/128
add(pulses,p)
end
num+=1
end
end
end
end
end
if num == 0 then
say(cell.icon,"ground control:\nno inactive satellites within range")
elseif num == 1 then
say(cell.icon,"ground control:\n"..num.." inactive satellite within range")
else
say(cell.icon,"ground control:\n"..num.." inactive satellites within range")
end
else
say(cell.icon,cell.interact.txt)
if not cell.used then
game.details[cell.interact.v]+=1
end
end
cell.used = true
end

function addvpop()
for i=0,1,0.05 do 
local p=entity(cat.p[1]+25*cos(i)+64,cat.p[2]+25*sin(i)+64,12)
p.d={rnd(5)*cos(i),rnd(5)*sin(i)}

p.s=rnd(5)+5
p.draw=function(p)
cam.push(p)
circ(0,0,p.s)
cam.pop()
end

add(parts,p)
end
end

function _draw()
scenes[scenes.current].d()
end

function drawvdebug()
camera(0,0)
printvol("cam.x:"..cam.p[1],1,1,0,7)
printvol("cam.y:"..cam.p[2],60,1,0,7)
printvol("cat.x:"..cat.p[1],1,10,0,7)
printvol("cat.y:"..cat.p[2],60,10,0,7)
printvol("mem:"..stat(0),1,120,0,7)
printvol("cpu:"..stat(1),60,120,0,7)

printvol("nip:"..cat.nip,1,20,0,7)
printvol("good:"..game.details.good,1,30,0,7)
printvol("bad: "..game.details.bad,1,40,0,7)
printvol("blue:"..game.details.blue,1,50,0,7)
end

function drawvbg()
camera(0,0)
color(15)
for a=0,127+cellvgap,cellvgap do
for b=0,127+cellvgap,cellvgap do
local s=bg[a][b]
local x=s.p[1]+cos(s.a)*s.r
local y=s.p[2]+sin(s.a)*s.r
line(x-2,y,x+2,y)
line(x,y-2,x,y+2)
end
end
end

function drawvicons()
camera(0,0)
color(15)
for a=0,127+cellvgap,cellvgap do
for b=0,127+cellvgap,cellvgap do
local s=bg[a][b]
local x=s.p[1]+cos(s.a)*s.r
local y=s.p[2]+sin(s.a)*s.r
if s.cell != nil then

-- selected cell
if s.cell == cat.cell then
pal(7,palette.a[palette.c][4])
for c=x+cellvgapvh-1-8,x+cellvgapvh+1-8 do
for d=y+cellvgapvh-1-8,y+cellvgapvh+1-8 do
drawvicon(s.cell.icon,c,d)
end
end
pal(7,palette.a[palette.c][3])
end

drawvicon(s.cell.icon,x+cellvgapvh-8,y+cellvgapvh-8)
end
end
end
end

function drawvicon(i,x,y)
sspr(16*(i%6),flr(i/6)*16,16,16,x,y)
end

function drawvstars()
camera(0,0)
for star in all(stars) do
color(star.c)
circ(star.p[1],star.p[2],1)
line(star.p[1],star.p[2],star.ovp[1],star.ovp[2])
end
end

function drawvpulses()
camera(cam.p[1],cam.p[2])
color(12)
for p in all(pulses) do
line(p.s[1]*cellvfull+cellvgapvh,p.s[2]*cellvfull+cellvgapvh,
p.p[1]*cellvfull+cellvgapvh,p.p[2]*cellvfull+cellvgapvh)
end
color(7)
for p in all(pulses) do
circfill(p.p[1]*cellvfull+cellvgapvh,p.p[2]*cellvfull+cellvgapvh,2)
end
color(12)
for p in all(pulses) do
circ(p.p[1]*cellvfull+cellvgapvh,p.p[2]*cellvfull+cellvgapvh,2)
end
end

function drawvtalk()
camera(0,0)
if cat.talk.txt2!=nil then
color(0)
rectfill(0,103,127,127)
drawvicon(cat.talk.icon,0,108)
color(7)
local y = 113-(cat.talk.h)*3
print(cat.talk.txt2,26,y)
color(12)
print("\143",16,113)
end
end

function drawvchildren(vc)
for c in all(vc.children) do
c.draw(c)
end
end

function drawvvector(vp)
cam.push(vp)

color(vp.c)
p1 = vvmul(rotate(vp.points[1],cam.a),cam.s)
for i=2,#vp.points do
p2 = vvmul(rotate(vp.points[i],cam.a),cam.s)

line(p1[1],p1[2],p2[1],p2[2])

p1 = p2
end

drawvchildren(vp)

cam.pop()
end

function printvol(vs,vx,vy,vc1,vc2)
color(vc1)
for x=vx-1,vx+1 do
for y=vy-1,vy+1 do
print(vs,x,y)
end
end
color(vc2)
print(vs,vx,vy)
end
__gfx__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccc0ccccccccc0ccccc0000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ccccccc0ccccccccc0ccccccc00000
0000000000000000077000000000077000077700000000000000000000007000000000000000070000000000000000000cccccccc0ccccccccc0cccccccc0000
000000000000000007070000000070700770077077770000000000000007770000000000000000000000000000000000ccccc00000ccccccccc0ccccccccc000
000000000000000007007777777700700770077711177700000000000071700000000000000100000000070000000000ccccccccc0ccccccccc0cccc0cccc000
000000000000000007070000000070700000771171111700000000777177000000000007707107000000000000700000ccccccccc00000000000ccc000ccc000
00000000000000000770000000000770000771111711117000000771111000000000007001111000000000000000000000000cccc000ccccc000cccc0cccc000
000000000000000007007700007700700007111111711170000007117710000000000000770010000007777700000000ccccccccc000ccccc000cccc0ccc0000
000000000000000007070070070070700007111111111170000007177170000000070070700070000000711777777000cccccccc1000ccccc000cccc0cccc000
000000000000000007007700007700700007111111171170000001177770000000001071007000000000771111770000cccccc111000ccccc000cccc0cccc000
00000000000000000700000000000070000771111111717000007711770000000071100111000000000007717770000011110111101111111100ccc111111000
00000000000000000070000770000700000077111111717000077700000000000000000010000000000000777000000011110111101111111110c11111110000
00000000000000000007007007007000000007771111117000717000000000000007000000000000000000000000000011110111101111111110111111100000
00000000000000000000700000070000000000077777777000070000000000000000000000000000000000000000000011110111101111111110111110000000
00000000000000000000077777700000000000000000000000000000000000000000000000000000000000000000000011110111101111011110111100011000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111101111011110111110111000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111111101111011110711111111000
00000007000000000000001000000000000007777770000000000000000000000000000000777700000000007770000001111111001111011110711111111000
00000001070000000000011000000000000070000007000000000777777700000000077777000700000000070007700000111110001111011110771111171000
00000777111000000000101000100000000070700007000000077001111070000077700000770700000000700077777000077700007777077770777777777000
00077717777000000001001001100000000070000707000000070111010100000070077777070700001010710700000007777777007777077770777777777000
00001111101000000001001010100000000070700007000000071101711110000070700011070700000100700700000077777777007777077770777777777000
00777777777770000010001101000100000070077007000000007771777710000070710110170700101100071700000077770777707777077770777777777000
00111111111100000000010101000100000007000070010000000171111710000070701101070700000010070070000000000077707777077770000000000000
00001100777777000000011010001100000100700700000000001177001710000070711101070700011717007170000077770777707777777770007777700000
00777777711110000000010010011000000017000077000000070111101700000070711011770700071111707007000077777777707777777770007777700000
00001011000000000000110010011000001017070700710000070111111170000070717777000700071117707107000007777777000777777700007777700000
00007777777000000000100100101000000170070777710000070777771170000070770000000700077770770007000000077700000077777000007777700000
00007770011000000000100111011000000017770711101000070111111170000070000000777700000700000007000000000000000000000000000000000000
00000111700000000000000000000000010101117000000000007777777000000070007777000000000077000070000000000000000000000000000000000000
00000000000000000000000000000000000010001000100000000000000000000077770000000000000000777700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000077770000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001111111070000000000000007700000000000000000000000000000000000
00000000000000000000000000000000000000010101000000000000077700000001000071070000000007717771100000000000000000000000000000000000
00000001000000000000111111110000000001010101000000000000000000000001000077770000000171111110000000000000000000000000000000000000
00000017770000000000171771710000000101017701010000077700000000000001000001000000001710000000000000000000000000000000000000000000
00000071177010000000171771710000000101771101010000000000000000000001007777777000007107771777700000000000000000000000000000000000
00001077717007000000171111710000000101777101010000000000000000000001007001007000007171111111100000000000000000000000000000000000
00007711177101000000171771710000000101717701010000000000777700000001111111007000000171000000000000000000000000000000000000000000
00001777771000000000111111710000000101777101000000000007111170000000007000007000000171077170000000000000000000000000000000000000
00100111110071000000177771710000000101010101000000000071117770000001111100007000000710711117000000000000000000000000000000000000
00177000000010000000111111110000000001010101000000000077770000000077707100011100000000100001000000000000000000000000000000000000
00011011711000000000000000000000000001010100000000000000000000000071707777777100000000071000000000000000000000000000000000000000
00000000100000000000000000000000000001010100000000000000000000000077700100011100000000001700000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000001111100000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
011000000e6451c50010635000000c632000002e6100000010645000000c632000002e610000002e62000000106450000010635000000c632245002e6100000010645000000c632000002e610000002e62000000
011000001d5501d55122550225512455024551245512455124551245512455124551245512455100000000002455024551245512455124551245511d5501d5511d5511d5511d5511d5511d5511d5511d5511d551
011000002255022551225512255122551225511b5501b5511b5511b5511b5511b5511b5511b5511b5511b5511d5501d5512255022551245502455124551245512455124551245512455124551245510000000000
011000002455024551245512455124551245511d5501d5511d5501d5511d5511d5511d5511d5511d5511d5512255022551225512255122551225511b5501b5511b5501b5511b5511b5511b5511b5511b5511b551
011000001653000000165301653100500005002253022531005000050000500005000050000500125301253114530005001453014531000000000020530205310000000000000000000000000000000d5300d531
011000000f5300f5000f5300f53100000000001b5301b531000000000012530125310000000000145301453116530000001653016531005000050022530225310050000500005000050000500005001253012531
0110000014530005001453014531000000000020530205310000000000000000000000000000000d5300d5310f5300f5000f5300f53100000000001b5301b5300000000000125301253000000000001453014530
011000000000000000000000000022420224210000000000165001650022420224212242122421224212242100000000000000000000204202042100000000001650016500204202042120421204212042114421
01100000125001650014500145001e4201e421000000000000000000001e4201e4211e4211e4211e4211e42100000000000000000000224202242100000000001650016500224202242122421224212242122421
0110000000000000000000000000204202042100000000001650016500204202042120421204212042114421125001650014500145001e4201e421000000000000000000001e4201e4211e4211e4211e4211e421
0110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014500000002c550240002c5502c5052c55014505
011000002c550000002c55000000275500000025550255512555125551245502455122550225512255122551225012250122501000000000000000000000000000000000002c550000002c550000002c55000000
011000002c550000002c550000002755000000255502555125551255512455024551225502255122551225510000000000000002050020550205501f5501f5501f5001f5001f5001f5001f5501f5501f50000000
01100000000000000020550205501f5501f5501d5001d5501f5501f5501f500000000000000000000000000000000000002555000000255500000025550000002555000000255500000025550000002555000000
011000000000000000000000000020420204210000000000165001650020420204212042120421204211442100000000000000000000244202442100000000001650016500244202442124421244212442124421
011000000000000000000000000024420244210000000000165001650024420244212442124421244212442100000000000000000000204202042100000000001650016500204202042120421204212042120421
011000000000000000000000000022420224210000000000165001650022420224212242122421224212242100000000000000000000224202242100000000001650016500224202242122421224212242122421
011000001653000000165301653100500005002253022531005000050000500005000050000500125001250114530005001453014531000000000020530205310000000000000000000000000000000d5000d501
01100000145300050014530145310000000000205302053100000000000000000000000000000000000000001253000500125301253100000000001e5301e53100000000001d5301d53000000000001957019570
011000001e5301e5311d5301d531195701957112570125711257112571000000000000000000000c5700c5710d570195010d5700d5710d5000d50119570195711850018501185701857100000000001457014570
011000001d5301d5301e5011e5011b5301b53012500125011853018530115301153011530115300c5000c501125301250012530125300d5000d5011e5301e53018500185011d5301d53000000000001953019530
01100000125301e5011253012530000001e5001e5301e5311e5311e5311e5311e53100000000000000000000145301e5011453014530000001e50020530205311450114501145301453100000000000000000000
01100000155301e5011553015530000001e50021530215311550115501155301553100000000000000000000165301e5011653016530000001e50022530225311550115501165301653100000000000000000000
011000002755000000255500000025550000000000000000000000000000000000000000000000000000000025550255502555025550255502555025550255502755027550295502955029550295502955029550
0110000024550245501850025500245502455025500255002555025550275502755027500275002255022550225502250020550205501e5501e5501e5501e5501e5501e550000000000000000000002a5502a550
011000002a5502a5501850029550295502950027550275502555025550185002455024550295002255022550205502055020550205501e5001e5001e5001e5001d5501d550185001b5501b550295001d5501d550
011000001d5501d5501d5001d50000000000001d5501e5501b5501b5501b5501b550000000000000000000000000000000000000000000000000001d5501d5001d5501d550000002255022550000002455024550
011000000000000000000000000022420224210000000000165001650022420224212242122421224012240122420224212242122421224212242122421224212242122421224212242122401224012240122401
011000002242022421224212242122421224212242122421224212242122421224210000000000000000000020420204212042120421204212042120421204212042120421204212042120421204212042120421
011000002442024421244212442124421244212442124421244212442124421244212442124421244212442122420224212242122421224212242122421224212242122421224212242122421224212242122421
011000002242022421224212242122421224212242122421224212242122421224212242122421224212242124420244212442124421244212442124421244212442124421244212442124421244212442124421
011000002442024421244212442124421244212442124421244212442124421244212442124421244212442100000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002655026550000002655026550000002655026550265502655000000245502455000000225502255000000000001d5501d5001d550000001d550000001d5501d550000002155021550000002255022550
011000002456024560000002456024560000002456024560245602456000000225602256000000205602056000000000002050020500205602050020560205602250022500225602250024560245002456024500
01100000245002450000000245002456024500245602456024500245002450022500225602256020560205601f5601f5601f5001f500000000000000000000000000000000000000000000000000000000000000
01100000000000000000000000001e560000001e560000001e5601e5601e560205602056000000225602250022560225600000022560225600000022560225002256022560000002056020560000001e5601e560
011000001d5601d5601d5601e5611d5601d5601d5601e5611d5601d5601d5601e5611d5601d5601d5601e5611d5601d5601d5601e5611d5601d5601d5601e5611d5601d5601d5601e5611d5601d5601d5601e501
01100000225600000022560000002256000000205600000000000000001e5600000000000000000000000000225600000016500000002256014500205600000000000000001e5600000000000000000000000000
0110000020560000002056020560205602056020560000001e5601e5601e560000001d5600000020560205602056020560205601450020560145001e5601e56012500125001d5601d5601d5601d5601d56000000
011000002256000000225602256022560000002256000000225600000022560225602256000000000000000024560245602456024560245600000000000000002456024500255602550027560275602756027560
011000002755027550275502755027550000000000000000255502555025550255502555000000000000000024550245502455024550245500000000000000000000000000000000000000000000000000000000
011000001a2211a2211a2211a2211a2211a2211a2211a2211a2211a2211a2211a2211a2211a2211a2211a22118221182211822118221182211822118221182211822118221182211822118221182211822118221
011000001b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211b2211d2211d2211d2211d2211d2211d2211d2211d2211d2211d2211d2211d2211d2211d2211d2211d221
011000002422124221242212422124221242212422124221242212422124221242212422124221242212422122221222212222122221222212222122221222212222122221222212222122221222212222122221
011000002222122221222212222122221222212222122221222212222122221222212222122221222212222122221222212222122221222212222122221222212222122221222212222122221222212222122221
011000001922119221192211922119221192211922119221192211922119221192211922119221192211922118221182211822118221182211822118221182211822118221182211822118221182211822118221
011000002222122221222212222122221222212222122221222212222122221222212222122221222212222124221242212422124221242212422124221242212422124221242212422124221242212422124221
011000002522125221252212522125221252212522125221252212522125221252212522125221252212522122221222212222122221222212222122221222212222122221222212222122221222212222122221
011000002222122221222212222122221222212222122221222212222122221222212222122221222212222124221242212422124221242212422124221242212422124221242212422124221242212422124221
01100000165500050016550165510000000000225502255100000000000000000000000000000000000000001155000500115501155100000000001d5501d5510000000000115501155000000000001950019500
011000001155000500115501155100000000001d5501d551000000000011500115000000000000195001950014550005001455014551000000000020550205510000000000145501455000000000001950019500
0110000014550005001455014551000000000020550205510000000000000000000000000000000d5500d5500f5500f5000f5500f55000000000001b5501b55000000000000f5500f55000000000000000000000
011000000f5500f5000f5500f55000000000001b5501b55000000000000f5000f5000000000000000000000000000000000000000000000000000012550125001d500000000f550000000d500000000d55000000
01100000000000000000000000000000000000115501155011550115501155011550115500000000000000000d550000000d5500d5500000000000195501955000000000000d5500d55000000000000000000000
01100000115500000011550115500000000000055500555005550055500555005550055500000000000000001255000000125501255000000000001e5501e5500000000000125501255000000000001255012550
011000001455000000145501455000000000002055020550000000000014550145500000000000145501455019550000001955019550000000000025550255500000000000195501955000000000001955019550
011000001655016500165501655000000000001655016550000000000016550165500000000000165501655012550125500000000000125501255000000000001255012550000000000012550125500f50000000
011000001455014550000001455014550000000000000000145501455000000145501455000000000000000016550165001655016550000000000022550225500000000000165001650000000000001255012550
0110000014550145001455014550000000000020550205500000000000000000000000000000000d5500d55000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002c550000002c55000000275500000025550255512555125551245502455122550225512255116551225012250122501000000000000000000000000000000000002c550000002c550000002c55000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001b2701d2701f2702927030270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 00010407
00 00020508
00 00030609
00 000a0407
00 003b050e
00 000b110f
00 000c1110
00 000d121b
00 0017131c
00 0018141d
00 0019151e
00 001a161f
00 00203129
00 0021322a
00 0022332b
00 0023342c
00 0024352d
00 0025362e
00 0026372f
00 00273830
00 00280104
00 00020508
02 00030609
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41304344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
