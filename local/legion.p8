pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
--the.green.legion
--by guerragames 
cartdata("the_green_legion")

time=0
one_frame=.0333333
file=0
shake_t=0

function get_file()
 local fi=file*4
 cur_score=dget(fi)
 cur_gp=dget(fi+1)
 cur_lvl=dget(fi+2)
 cur_gm=dget(fi+3)

 if cur_lvl<1 or cur_lvl>10 then
  cur_lvl=1
 end 

 ps_level=1
 ps_active_count=1
 ps_max_active_count=1
 ps_shoot_rate=.3
 ps_pshoot_cdown=10
 ps_pshoot_damage=10
end

function store_file()
 local fi=file*4
 dset(fi,cur_score)
 dset(fi+1,cur_gp)
 dset(fi+2,cur_lvl)
 dset(fi+3,cur_gm)
end

function save_and_reset()
 cur_gm+=1
 store_file()
 run()
end

function reset_score()
 cur_score=0
 cur_gp=0
 cur_lvl=1
 cur_gm=0
 store_file()
 run()
end

function nl(s)
 local a={}
 local ns=""
 
 while #s>0 do
  local d=sub(s,1,1)
  if d=="," then
   add(a,ns+0)
   ns=""
  else
   ns=ns..d
  end
  
  s=sub(s,2)
 end
 
 return a
end

function unpack(y,i)
 i=i or 1
 local g=y[i]
 if(g)return g,unpack(y,i+1)
end

align_c=0
align_l=1
align_r=2

function po(t,x,y,c,bc,a)
  local ox=#t*2 
  if a==align_l then
   ox=0
  elseif a==align_r then
   ox=#t*4
  end
  local tx=x-ox
  color(bc)
  print(t,tx-1,y)print(t,tx-1,y-1)print(t,tx,y-1)print(t,tx+1,y-1)
  print(t,tx+1,y)print(t,tx+1,y+1)print(t,tx,y+1)print(t,tx-1,y+1)
  print(t,tx,y,c)
end

function normalize(x,y)
  local m=sqrt(x*x+y*y)
  return x/m,y/m,m
end

function force_sep(fo,mo,min_sep,max_sep)
  local xdiff,ydiff=fo.x-mo.x,fo.y-mo.y
  local nx,ny,mag=normalize(xdiff,ydiff)
  local min_sep,max_sep=mag-min_sep,mag-max_sep
  if max_sep>0 then
   mo.x+=nx*max_sep
   mo.y+=ny*max_sep
  elseif min_sep<0 then
   mo.x+=nx*min_sep
   mo.y+=ny*min_sep
  end
end

function rnd_i(c)
 return flr(rnd(c))+1
end

function next_i(l,i)
 i+=1
 if(i>#l)i=1
 return i
end

function lerp(min,max,t)
 return min+(max-min)*t
end

function rnd_range(min,max)
 if min and max then
  return lerp(min,max,rnd())
 end
 return 0
end

function scr_text(val)
 local s,v="",abs(val)
 repeat
  s=shl(v%0x0.000a,16)..s
  v/=10
 until v==0
 
 if val<0 then
  s="-"..s
 end
 
 return s
end

function gp_perc(p)
 return 1+p*cur_gp
end

sf={}
sf_next=1
sf_scroll_speed=.3
sf_max_speed=10
sf_target_rate=2
sf_rate=1.5
sf_to_spawn=0

for i=1,200 do
 s={lasty=-1,blink=5,bt=5}
 add(sf,s)
end

function sf_init()
 for k,s in pairs(sf)do
  s.y=128
 end

 sf_rate=0
end

function sf_update()
 sf_to_spawn+=sf_rate

  while sf_to_spawn>1 do
   local s=sf[sf_next]
   s.speed=rnd(sf_max_speed)
   s.x,s.y=rnd_i(128),-rnd(sf_scroll_speed+s.speed)
   s.lasty=s.y
   s.blink=rnd(.2)
   s.bt=s.blink
   sf_next=next_i(sf,sf_next)
   sf_to_spawn-=1
  end

 for k,s in pairs(sf)do
  s.lasty=s.y
  if s.y<128 then
   s.y+=s.speed+sf_scroll_speed
  else
   s.y=128
  end
 end
end

function sf_draw()
 for k,s in pairs(sf)do
  s.bt-=one_frame
  if s.bt<=0 then
   s.bt=s.blink
   s.color=(s.color==5)and 6 or 5
  end
  line(s.x,s.lasty,s.x,s.y,s.color)
 end
end

bs={}
bs_next=1
bs_cos={}
bs_sin={}

for i=1,101 do
  local angle=i/100
  add(bs_cos,cos(angle))
  add(bs_sin,sin(angle))
end

bs_lines={"boom!","bang!","bam!","pow!"}
bs_b_lines={"ka-booooooom!","ka-baaaaaang!","ka-baaaaaam!","ka-poooooow!"}

for i=1,20 do
 local boom={}
 for j=1,21 do
  add(boom,{})
 end
 
 add(bs,boom)
end

function bs_reset()
 for k,boom in pairs(bs)do
  boom.active=false
 end
end

function bs_spawn(x,y,min_size,max_size,max_time,bl,flash)
 local boom=bs[bs_next]
 boom.max_time=max_time
 boom.t=0
 boom.x,boom.y=x,y
 boom.flash=flash
 boom.active=true
 boom.text=nil
 
 if bl then
  boom.text=bl[rnd_i(#bl)]
 end
 
 boom.a_offset=rnd()

 for i=1,21 do
  local b=boom[i]
  b.r=0
  b.a=i/20
  b.max_r=min_size+rnd((max_size-min_size)*(i%2))
 end
 
 bs_next=next_i(bs,bs_next)
end


function bs_update()
 for k,boom in pairs(bs)do
  if boom.active then 
   boom.t+=one_frame
 
   for j=1,21 do
    local b=boom[j]
    b.r=b.max_r*boom.t/.2
    if b.r>b.max_r then
     b.r=b.max_r
    end
   end  
  
   if boom.t>=boom.max_time then
    boom.active=false
   end
  end
 end
end

function bs_index_to_ai(boom,i)
 return flr(1+100*(boom.a_offset+i/20)%100)
end

function bs_draw_l(boom,i1,i2,c,offr)
 local cx,cy=boom.x,boom.y
 local a1,a2=bs_index_to_ai(boom,i1),bs_index_to_ai(boom,i2)
 local m1,m2=boom[i1].r+offr,boom[i2].r+offr
 line(cx+m1*bs_cos[a1],cy+m1*bs_sin[a1],cx+m2*bs_cos[a2],cy+m2*bs_sin[a2],c)
end

function bs_draw()
 for k,boom in pairs(bs)do
  if boom.active then 
   if boom.flash and boom.t<.1 then
    rectfill(0,0,128,128,7)
    return
   end 
   
   local color,ocolor=10,8

   for j=2,19 do
    bs_draw_l(boom,j,j+1,ocolor,-4)
    bs_draw_l(boom,j,j+1,ocolor,-2)
   end

   bs_draw_l(boom,20,1,ocolor,-4)
   bs_draw_l(boom,1,2,ocolor,-4)
   bs_draw_l(boom,20,1,ocolor,-2)
   bs_draw_l(boom,1,2,ocolor,-2)

   for j=2,19 do
    bs_draw_l(boom,j,j+1,color,0)
   end

   bs_draw_l(boom,20,1,color,0)
   bs_draw_l(boom,1,2,color,0)

   if boom.text then
    po(boom.text,boom.x+2,boom.y-3,9+(boom.t*12)%2,0)
   end
  end
 end
end

exs={}
exs_next=1

for i=1,20 do
 local ex={} 
 ex.timer=0
 ex.bits={}

 for j=1,20 do
  add(ex.bits,{})
 end
 
 add(exs,ex)
end

function exs_reset()
 for k,ex in pairs(exs)do
  ex.timer=0
 end
end

function make_ex(x,y,size,dsize,speed,timer)
 local ex=exs[exs_next]
 
 ex.timer=timer

 for k,bit in pairs(ex.bits)do
  bit.x,bit.y=x,y
  local dx,dy,mag=normalize(rnd_range(-1,1),rnd_range(-1,1))
  local s=speed+rnd(2)
  bit.size,bit.dsize=size,dsize
  bit.dx,bit.dy=dx*s,dy*s
 end
 
 exs_next=next_i(exs,exs_next)
end

function exs_update()
 for k,ex in pairs(exs)do
  if ex.timer>0 then
   ex.timer-=one_frame
   local alive_count=0
   for k,bit in pairs(ex.bits)do
    bit.dx*=.9
    bit.dy*=.9
    bit.x+=bit.dx
    bit.y+=bit.dy
	bit.size+=bit.dsize
    if bit.size>0 then
     alive_count+=1
    end
   end
   if alive_count==0 then
    ex.timer=0
   end
  end
 end
end

function exs_subdraw(ex,size_offset,color)
 for k,bit in pairs(ex.bits)do
  circfill(bit.x,bit.y,bit.size+size_offset,color)
 end
end

function exs_draw()
 for k,ex in pairs(exs)do
  if ex.timer>0 then
   exs_subdraw(ex,1,5)
   exs_subdraw(ex,0,6)
  end
 end
end

ps={}

ps_level=1
ps_max_active_count=1
ps_shoot_rate=.3
ps_pshoot_cdown=10
ps_pshoot_damage=10

ps_active_count=1

attack_held=0
attack_queued=false

ps_shoot_timer=0
pattack_held=0

pattack_anim=nl("0,0,0,0,0,0,0,0,0,0,2,2,2,4,4,")

function player_init(p,i)
 p.active=false
 p.x,p.y=66,136
 p.spr=i-1
 p.pattack_i=#pattack_anim+1
 p.cdown=0
 p.muzzle_flash,p.blink=0,0
end

for i=1,8 do
 local p={}  
 player_init(p,i)
 add(ps,p)
end

function ps_reset_ng()
 for k,p in pairs(ps) do
  p.active=false
 end
 
 for i=1,ps_max_active_count do
  local p=ps[i]
  p.x,p.y=60,136+8*i
  p.active=true
  p.cdown=0
  p.getting_back=true
 end

 ps_active_count=ps_max_active_count
end
 
function ps_reset_nl()
 for i=ps_active_count+1,ps_max_active_count do
  local p=ps[i]
  p.x,p.y=60,136
  p.active=true
  p.cdown=0
  p.getting_back=true
 end

 ps_active_count=ps_max_active_count
end

function add_to_score(amount,enemy_health)
 if enemy_health>0 then
  cur_score+=shr(amount,16)
 else
  cur_score+=shr(amount+enemy_health,16)
 end
end

function upgrade_row(n,s,t)
 return {score=shr(n,s),type=t}
end

upgrade_table =
{
 upgrade_row(100,16,1),upgrade_row(200,16,2),upgrade_row(400,16,3),
 upgrade_row(800,16,1),upgrade_row(1300,16,2),upgrade_row(2000,16,3),
 upgrade_row(3000,16,1),upgrade_row(4500,16,2),upgrade_row(6500,16,3),
 upgrade_row(9000,16,1),upgrade_row(12000,16,2),upgrade_row(16000,16,3),
 upgrade_row(21000,16,1),upgrade_row(27000,16,2),upgrade_row(32000,16,3),
 upgrade_row(32000,15,1),upgrade_row(32000,14,2),upgrade_row(32000,13,3),
 upgrade_row(32000,12,1),upgrade_row(32000,11,2),upgrade_row(32000,10,3),
 upgrade_row(32000,9,1),upgrade_row(32000,8,2),upgrade_row(32000,7,3),
}

function next_upgrade_txt()
 local next_upgrade=upgrade_table[ps_level]
 if next_upgrade then
  return "nxt:"..scr_text(next_upgrade.score)
 end
 return "max lvl!"
end

function ps_upgrades_update()
 local upgraded=true
 while upgraded do
  upgraded=false
  local lv_upgrade=upgrade_table[ps_level]

  if lv_upgrade then
   if cur_score>=lv_upgrade.score then
    upgraded=true
    ps_level+=1
  
    if lv_upgrade.type==1 then
     if ps_max_active_count<#ps then
      ps_max_active_count+=1
      ps_active_count+=1
    
      local new_ship=ps[ps_active_count]
      new_ship.x,new_ship.y=56,128
      new_ship.active=true
      new_ship.cdown=0
      new_ship.getting_back=true
     end
    elseif lv_upgrade.type==2 then
     if ps_shoot_rate>0.1 then
      ps_shoot_rate-=0.025
     end
    elseif lv_upgrade.type==3 then
     if ps_pshoot_cdown>6 then
      ps_pshoot_cdown-=.5
      ps_pshoot_damage*=2
     end
    end
   end
  end
 end
end

function ps_player_bounds()
 local p1=ps[1]
 return p1.x+3,p1.y+1,p1.x+3,p1.y+3
end

function pshoot_collision_checker(bullet,x,y,x2,y2)
 local xmin=ps[1].x
 return x<=xmin+8 and x2>=xmin
end

function ps_check_pshoot()
 local xmin=ps[1].x
 for k,eb in pairs(ebs)do
  eb.active=false
 end 
 
 for k,e in pairs(es)do
  if e.active then
   local emin_x,emin_y,emax_x,emax_y=es_enemy_bounds(e)
   
   if emin_x<=xmin+8 and emax_x>=xmin then
    es_damage(e,ps_pshoot_damage,emin_x+e.spr_width/2,emax_y)
   end   
  end
 end
 
 boss_check_damage(ps[1],5,pshoot_collision_checker)
end

function ps_pshoot()
 if ps[2].active and
    ( ps[2].cdown<=0 and ps[2].pattack_i>#pattack_anim ) then
  sfx(1)
  
  shake_t=.2
 
  local splayer=ps[1]
  ps_check_pshoot(splayer)
  
  for i=2,ps_active_count do
   if ps[i].active then
    ps[i-1]=ps[i]
   end
  end 

  splayer.pattack_i=1
  splayer.y=2
  ps[ps_active_count]=splayer
 end 
end

function ps_check_seps()
 for i=2,ps_active_count do
  local p=ps[i]
  if p.active then
   if not p.getting_back then
    if p.pattack_i>#pattack_anim then
     force_sep(ps[i-1],p,10,10)
     force_sep(ps[1],p,10+2*i-4,i*10)
    end
   end
  end
 end
end

function ps_update_shooting()
 if btn(4)then
  if attack_held==0 then
   attack_queued=true
  end

  attack_held+=one_frame
 else
  attack_held=0
 end
 
 if attack_held>0 or attack_queued then
  if ps_shoot_timer <=0 then
   sfx(0)
 
   for k,p in pairs(ps) do
    if p.active and p.cdown<=0 then
     bullets_make_bullet(p.x+2,p.y-3)
     p.muzzle_flash=0.05
    end
   end
   ps_shoot_timer=ps_shoot_rate
   attack_queued=false
  end
 end
 
 ps_shoot_timer-=one_frame
end

function ps_explode()
 local p1=ps[1]

 sfx(7)
 for i=1,4 do
  make_ex(p1.x+2+rnd(4),p1.y+2+rnd(4),8+rnd(4),-0.2,2,4)
 end
 
 local x,y=p1.x+4,p1.y+4
 
 bs_spawn(x,y,12,40,.7)
 bs_spawn(x,y,8,30,.7)
 bs_spawn(x,y,6,20,.7,bs_lines)
 
 shake_t=.5

 for i=2,ps_active_count do
  if ps[i].active then
   ps[i-1]=ps[i]
  end
 end  
 
 p1.active=false
 ps[ps_active_count]=p1
 
 ps_active_count-=1
 
 local new_p1=ps[1]
 if ps_active_count<=0 or new_p1.cdown>0 then
  gameover=true
  title_timer=0
  cur_gm+=1
  store_file()
 else
  new_p1.blink=3
 end
end

function ps_check(x,y,x2,y2)
 local p1=ps[1]
 
 if p1.blink<=0 then
  local xmin,ymin,xmax,ymax=ps_player_bounds()

  if x <=xmax and x2>=xmin and
     y <=ymax and y2>=ymin then
   ps_explode()
   return true
  end
 end
 
 return false
end

function ps_update()
 local p1=ps[1]
 
 if p1.muzzle_flash>0 then
  p1.muzzle_flash-=one_frame
 end
 
 if p1.blink>0 then
  p1.blink-=one_frame
 end

 local speed=(attack_held>0.2)and 1 or 2
 
 if btn(0)then
  p1.x-=speed
 end

 if btn(1)then
  p1.x+=speed
 end

 if btn(2)then
  p1.y-=speed
 end

 if btn(3)then
  p1.y+=speed
 end

 p1.x=max(0,min(121,p1.x))
 p1.y=max(0,min(120,p1.y))

 ps_check_seps()
 ps_update_shooting()

 -- power attack
 if btn(5)then
  if pattack_held==0 then
   ps_pshoot()
  end

  pattack_held+=one_frame
 else
  pattack_held=0
 end
 
 for i=2,ps_active_count do
  local p=ps[i]
  if p.active then
   if p.muzzle_flash>0 then
    p.muzzle_flash-=one_frame
   end  
  
   if p.pattack_i<=#pattack_anim then
    p.pattack_i+=1
    
    if p.pattack_i>#pattack_anim then
     p.cdown=ps_pshoot_cdown
     p.getting_back=true
    end
   end
   
   if p.cdown>0 then
    p.cdown-=one_frame
   end 

   if p.getting_back then
    local pi2=ps[i-1]
      
    local nx,ny,mag=normalize(pi2.x-p.x,pi2.y-p.y)
      
    if mag<=10 then
     p.getting_back=false
    else
     p.x+=nx*2
     p.y+=ny*2
    end
   end
  end
 end
 
 ps_upgrades_update()
end

function ps_spr_draw(p,ox,oy,r)
 local x,y=p.x+ox,p.y+oy
 spr((r>.5)and 192 or 193,x+2,y+7)
 spr(p.spr,x,y)
end

function pal_color(c)
 for i=1,15 do
  pal(i,c)
 end
end

function ps_draw_shadows(p,r)
 pal_color(0)
 ps_spr_draw(p,1,0,r)
 ps_spr_draw(p,-1,0,r)
 ps_spr_draw(p,0,1,r)
 ps_spr_draw(p,0,-1,r)
 pal()
 
 if p.muzzle_flash>0 then
  circfill(p.x+3,p.y-1,3,10)
 end  
end

function ps_draw_secondary()
 for i=ps_active_count,2,-1 do
  local p=ps[i]
  
  if p.active then
   local r=rnd()
   ps_draw_shadows(p,r)
 
   if p.cdown>0 then
    pal(7,8)
    pal(6,2)
   elseif p.pattack_i<#pattack_anim then
    local anim_frame=pattack_anim[p.pattack_i]
    local px,py=p.x-2,p.y-2
  
    spr(16+anim_frame,px,py,2,1)
 
    for ty=1,13 do
     spr(32+anim_frame,px,py+ty*8,2,1)
    end
    
    spr(48+anim_frame,px,py+112,2,1)
    pal(7,8)
    pal(6,2)
   else  
    pal(7,5)
    pal(6,1)
   end

   ps_spr_draw(p,0,0,r)
  end
 end
end

function ps_draw_first()
 local p1=ps[1]
 local should_blink=p1.blink>0 and p1.blink%.2>=.1
 if not should_blink then
  local r=rnd()
  ps_draw_shadows(p1,r)
  ps_spr_draw(p1,0,0,r)
 end
end

bullets={}
bullets_anim=nl("241,242,243,242,")
bullets_next=1

for i=1,200 do
 add(bullets,{})
end

function bullets_make_bullet(x,y)
 local nb=bullets[bullets_next]
 nb.x,nb.y=x,y
 nb.active=true
 nb.anim_index=1
 bullets_next=next_i(bullets,bullets_next)
end

function bullets_check(b,x,y,x2,y2)
 return b.x+4>=x and b.x-1<=x2 and b.y+8>=y and b.y<=y2
end

function bullets_update()
 for k,b in pairs(bullets)do
  if b.active then
   if b.y>0 then
    b.y-=5
    b.anim_index=next_i(bullets_anim,b.anim_index)
   else
    b.active=false
   end
  end
 end
end

function bullets_draw()
 for k,b in pairs(bullets)do
  if b.active then
   spr(bullets_anim[b.anim_index],b.x,b.y)
  end
 end
end

ebs={}
ebs_next=1
ebs_blink=0
ebs_blink_on=true

for i=1,2000 do
 add(ebs,{})
end

function ebs_reset()
 for k,eb in pairs(ebs)do
  eb.active=false
 end
end

function ebs_make_bullets(x,y,speed,count,inc_a,start_a)
 sfx(5)
 local ia=start_a
 for i=1,count do
  local eb=ebs[ebs_next]
  eb.x,eb.y=x,y
  eb.velx,eb.vely=speed*sin(ia),speed*cos(ia)
  eb.active=true
  ebs_next=next_i(ebs,ebs_next)
  
  ia-=inc_a
 end 
end

function ebs_update()
 if ebs_blink<=0 then
  ebs_blink=.05
  ebs_blink_on=not ebs_blink_on
 else
  ebs_blink-=one_frame
 end

 for k,eb in pairs(ebs)do
  if eb.active then
   if eb.y<-8 or eb.x<-8 or eb.y>142 or eb.x>142 then
    eb.active=false
   else
	eb.y+=eb.vely
    eb.x+=eb.velx

	if not gameover then
     if ps_check(eb.x,eb.y,eb.x+3,eb.y+3)then
	  eb.active=false
	 end
    end
   end
  end
 end
end

function ebs_draw()
 pal()

 if ebs_blink_on then
  pal(14,8)
 end
  
 for k,eb in pairs(ebs)do
  if eb.active then
   spr(224,eb.x,eb.y)
  end
 end
 
 pal()
end

function ebs_shoot_aimed(x,y,speed,count,angle)
 local to_player_x,to_player_y=ps[1].x-x,ps[1].y-y
 local nx,ny,mag=normalize(to_player_x,to_player_y)
 local a=atan2(ny,nx)
 ebs_make_bullets(x,y,speed,count,angle/count,a+.5*angle)
end

function ebs_shoot_spread(x,y,speed,count,angle)
 ebs_make_bullets(x,y,speed,count,1/count,angle)
end

boss_x=20
boss_y=8

boss_active=false
boss_exploding_timer=0
boss_desc = nil

parts={}
max_parts_w=9
max_parts_h=11

thruster_parts=nl("252,253,254,255,")

flame_parts={
 { idle=nl("236,236,237,237,")},
 { idle=nl("238,238,239,239,")},
}

glue_parts=nl("201,202,203,204,205,206,207,217,218,219,220,221,222,234,235,250,251,")

shooter_parts={
 {
  idle=nl("199,"),
  open=nl("199,199,199,199,198,197,196,196,196,196,197,198,"),
  shoot=nl("197,196,"),
  close=nl("196,197,198,199,"),
  dead=nl("200,"),
 },
 {
  idle=nl("215,"),
  open=nl("215,214,213,212,213,214,"),
  shoot=nl("213,212,"),
  close=nl("212,213,214,215,"),
  dead=nl("216,"),
 },
 {
  idle=nl("231,"),
  open=nl("231,230,229,228,229,230,"),
  shoot=nl("229,228,"),
  close=nl("228,229,230,231,"),
  dead=nl("232,"),
 },
 {
  idle=nl("247,"),
  open=nl("247,246,245,244,245,246,"),
  shoot=nl("245,244,"),
  close=nl("244,245,246,247,"),
  dead=nl("248,"),
 },
}

for j=1,max_parts_h do
 add(parts,{})
 for i=1,max_parts_w do
  add(parts[j],{})
 end
end

function boss_reset()
 boss_active=false
 boss_phase=0
 boss_exploding_timer=0
 boss_base_y=-128
end

function add_thruster(j,i)
 local t1=parts[j-1][i]
 t1.active=true
 t1.shooter=false
 t1.anims=nil
 t1.spr=thruster_parts[rnd_i(#thruster_parts)]
 
 local t1=parts[j-2][i]
 t1.active=true
 t1.shooter=false
 t1.anims=flame_parts[rnd_i(#flame_parts)]
 t1.current_anim=t1.anims.idle
 t1.anim_index=1
 t1.anim_time=0
end

function boss_init_shooter_part(part)
 part.active,part.shooter=true,true
 part.anims=shooter_parts[rnd_i(#shooter_parts)]
 
 part.current_anim=part.anims.idle
 part.anim_index=1
 part.anim_time=0
  
 part.shooting_timer=0
 
 part.aimed = (rnd() < boss_desc.aimed_bullet_chance)

 part.shoot_rate=rnd_range(boss_desc.min_shoot_rate,boss_desc.max_shoot_rate)/gp_perc(.01)

 part.bullet_speed=rnd_range(boss_desc.min_bullet_speed,boss_desc.max_bullet_speed)
 
 part.bullet_count=min(40,flr(rnd_range(boss_desc.min_bullet_count,boss_desc.max_bullet_count)*gp_perc(.1)))
 
 part.closed_time=rnd_range(boss_desc.min_closed_time,boss_desc.max_closed_time)
 part.opened_time=rnd_range(boss_desc.min_opened_time,boss_desc.max_opened_time)
 part.bullet_a=0
 part.bullet_a_inc=rnd_range(boss_desc.min_bullet_a_inc,boss_desc.max_bullet_a_inc)
 part.bullet_a_spread=rnd_range(boss_desc.min_bullet_a_spread,boss_desc.max_bullet_a_spread)

 part.lifetime=0
 part.health=boss_desc.health*gp_perc(.2)
end

function clone_part(t_part,s_part)
 t_part.active,t_part.shooter=s_part.active,s_part.shooter
 t_part.anims,t_part.spr=s_part.anims,s_part.spr
 
 t_part.current_anim,t_part.anim_index=s_part.current_anim,s_part.anim_index
 t_part.anim_time=s_part.anim_time
  
 t_part.shooting_timer,t_part.aimed=s_part.shooting_timer,s_part.aimed
 
 t_part.shoot_rate=s_part.shoot_rate
 t_part.bullet_speed,t_part.bullet_count=s_part.bullet_speed,s_part.bullet_count
 t_part.closed_time,t_part.opened_time=s_part.closed_time,s_part.opened_time
 t_part.bullet_a=0
 t_part.bullet_a_inc,t_part.bullet_a_spread=s_part.bullet_a_inc,s_part.bullet_a_spread
 
 t_part.lifetime,t_part.health=s_part.lifetime,s_part.health
end

function make_boss()
 boss_active=true
 boss_exploding_timer=0
 
 for k,v in pairs(parts)do
  for k2,p in pairs(v)do
   p.active,p.shooter=false,false
   p.anim_index=1
  end
 end

 local cx=5

 local x=cx
 local y=2+flr(rnd(max_parts_h-2))+1

 boss_init_shooter_part(parts[y][x])

 local count=boss_desc.size-1

 while count>0 do
  local rnd_dir=rnd(1)

  if rnd_dir<.25 then
   if y>3 then
    y-=1
   end
  elseif rnd_dir<.5 then
   if y<max_parts_h-1 then
    y+=1
   end
  elseif rnd_dir<.75 then
   if x>1 then
    x-=1
   end
  elseif rnd_dir<1 then
   if x<cx then
    x+=1
   end
  end
  
  local part=parts[y][x]

  if not part.active or not part.shooter then
   part.active=true

   if rnd()<boss_desc.shooter_chance then
    count-=1
	boss_init_shooter_part(part)
    part.current_anim=part.anims.idle
   else
    part.shooter=false
	part.anims=nil
    part.spr=glue_parts[rnd_i(#glue_parts)]
   end
  end
 end

 local start_index=rnd_i(2)

 local added_thruster=false

 for i=start_index,cx,2 do
  for j=3,max_parts_h do
   if parts[j][i].active then
    add_thruster(j,i)

	added_thruster=true
	break
   end
  end
 end

 if not added_thruster then
  for j=3,max_parts_h do
   if parts[j][cx].active then
    add_thruster(j,cx)

	added_thruster=true
	break
   end
  end
 end

 for j=1,max_parts_h do
  for i=1,cx do
   if parts[j][i].active then
    local mirror_part=parts[j][max_parts_w-i+1]
	clone_part(mirror_part,parts[j][i])
   end
  end
 end

 local empty_row=true

 while empty_row do
  for i=1,max_parts_w do
   if parts[1][i].active then
    empty_row=false
   end
  end

  if empty_row then
   local temp_row=parts[1]
   for j=2,max_parts_h do
    parts[j-1]=parts[j]
   end
   parts[max_parts_h]=temp_row
  end
 end
end

function set_current_anim(part,anim)
 part.current_anim,part.anim_index=anim,1
 part.anim_time=0
end

function boss_check_damage(bullet,damage_amount,collision_checker)
 for j=1,max_parts_h do
  for i=1,max_parts_w do
   local part=parts[j][i]

   if part.shooter and part.active and part.health>0 then
    if part.current_anim!=part.anims.idle then 
     local part_x,part_y=boss_x+i*8,boss_y+j*8
   
     if collision_checker(bullet,part_x,part_y,part_x+8,part_y+8)then
      part.health-=damage_amount
      
      add_to_score(damage_amount,part.health)
      
      if part.health<=0 then
	   sfx(2)
       part.health=0
     
       set_current_anim(part,part.anims.dead)
         
       local ex,ey=part_x+4,part_y+4
     
       make_ex(ex,ey,6,-.5,1,2)      
       bs_spawn(ex,ey,6,20,.4,bs_lines)
      else
	   sfx(3)
       local ex,ey=bullet.x+1.5,part_y+8
       make_ex(ex,ey,2,-.2,1,2)
       bs_spawn(ex,ey,4,16,.2)
      end 
      
      return true
     end
    end
   end
  end
 end
 
 return false
end

function boss_update()
 if not boss_active then
  return
 end

 if boss_base_y<0 then
  boss_base_y+=.5
 end

 boss_x=lerp(8,32,.5+.5*sin(boss_desc.speedx*time))
 boss_y=boss_base_y+lerp(0,8,.5+.5*cos(boss_desc.speedy*time))
 
 local alive_parts=0
 
  for j=1,max_parts_h do
   for i=1,max_parts_w do
    local part=parts[j][i]

    if part.active then
	 local part_x,part_y=boss_x+i*8+2,boss_y+j*8+2
    
	 if part.shooter then
      part.lifetime+=one_frame

      if part.health>0 then     
       alive_parts+=1
      end
      
      if part.current_anim==part.anims.idle then
	   if part.anim_time>=part.closed_time then
	    set_current_anim(part,part.anims.open)
	   end
	  elseif part.current_anim==part.anims.open then
       if part.anim_index>=#part.current_anim then
	    set_current_anim(part,part.anims.shoot)
	    part.shooting_timer=0
	   end
	  elseif part.current_anim==part.anims.shoot then
	   part.shooting_timer-=one_frame

	   if part.shooting_timer<=0 then
	    part.shooting_timer=part.shoot_rate
        if part.aimed then
         ebs_shoot_aimed(part_x,part_y,part.bullet_speed,part.bullet_count,part.bullet_a_spread)
        else
         part.bullet_a+=part.bullet_a_inc
         ebs_shoot_spread(part_x,part_y,part.bullet_speed,part.bullet_count,part.bullet_a)
	    end
       end

       if part.anim_time>=part.opened_time then
	    set_current_anim(part,part.anims.close)
	   end
	  elseif part.current_anim==part.anims.close then
       if part.anim_index>=#part.current_anim then
	    set_current_anim(part,part.anims.idle)
	   end
	  end
	 end

     if part.anims then
	  part.anim_time+=one_frame
      part.anim_index=next_i(part.current_anim,part.anim_index)
     end
    end
   end
  end
 
 if alive_parts<=0 then
  if boss_exploding_timer==0 then
   boss_exploding_timer=1
   shake_t=1
   ebs_reset()
   
	if boss_phase==0 and cur_lvl==10 then
	 boss_phase=1
	else
	 music(0)
	end   
  else
   boss_exploding_timer-=one_frame
   
   if boss_exploding_timer<=0 then
	local ex,ey=boss_x+44,boss_y+24
    
	sfx(7)
    make_ex(ex,ey,10,-.15,1,5)      
    make_ex(ex,ey,8,-.15,4,5)      
    make_ex(ex,ey,6,-.15,6,5)      

    bs_spawn(ex,ey,15,60,1,bs_b_lines,true)
    boss_active=false
    shake_t=1
	
	if boss_phase==1 then
	 boss_reset()
     make_boss()
	 boss_phase=2
	end
   else
     sfx(2)
     for q=1,5 do
      local j,i=rnd_i(max_parts_h),rnd_i(max_parts_w)

      local part=parts[j][i]

      if part.active then
	   local ex,ey=boss_x+i*8+rnd(8),boss_y+j*8+rnd(8)
       make_ex(ex,ey,2,-.1,1,2)
       bs_spawn(ex,ey,4,16,.2)
      end
     end
   end
  end  
 end
end

function boss_draw()
 if boss_active then
  pal()

  for j=1,max_parts_h do
   for i=1,max_parts_w do
    local part=parts[j][i]
    if part.active then
     local x,y=boss_x+i*8,boss_y+j*8
     if part.anims then
      spr(part.current_anim[part.anim_index],x,y,1,1,i>5)
     else
      spr(part.spr,x,y,1,1,i>5)
     end
    end
   end
  end
 end
end

function enemy_regen(spr_index,size,max_count)
 local colors={11,3,5}
 local s=size*8
 local half_s=s/2
 local bx,by=(spr_index%16)*8,flr(spr_index/16)*8
 
 for i=0,s*s do
  sset(bx+i%s,by+i/s,0)
 end

 local x,y=half_s,rnd_i(s-1)

 local smallest_x=x
 
 local count=max_count
 
 while count>0 do
  local sx,sy=bx+x,by+y
  if sget(sx,sy)==0 then
   if count>=max_count-1 then
    sset(sx,sy,8)
   else
    sset(sx,sy,colors[rnd_i(#colors)])
   end
   count-=1
  end
  
  local rnd_dir_y=rnd(3)

  if rnd_dir_y<1 then
   if y>2 then
    y-=1
   end
  elseif rnd_dir_y<2 then
   if y<s-1 then
    y+=1
   end
  end 
   
  local rnd_dir_x=rnd(3)
  
  if rnd_dir_x<1 then
   if x>1 then
    x-=1
    
    if x<smallest_x then
     smallest_x=x
    end
    
   end
  elseif rnd_dir_x<2 then
   if x<half_s then
    x+=1
   end
  end
 end
 
 local start_index=rnd_i(2)

 local added_thruster=false

 for i=start_index,half_s-1,2 do
  for j=1,s-1 do
   if sget(bx+i,by+j)!=0 then
    sset(bx+i,by+j-1,10)

	added_thruster=true
	break
   end
  end
 end

 if not added_thruster then
  for j=1,s-1 do
   if sget(bx+half_s,by+j)!=0 then
    sset(bx+half_s,by+j-1,10)

	added_thruster=true
	break
   end
  end
 end

 for j=0,s do
  for i=0,half_s do
   local sp=sget(bx+i,by+j)
   if sp!=0 then
    sset(bx+s-i,by+j,sp)
   end
  end
 end

 palt(0,false)
 
 local empty_row=true
 local empty_row_count=0

 while empty_row and empty_row_count<s do
  for i=0,half_s do
   if sget(bx+i,by)!=0 then
    empty_row=false
	break
   end
  end

  if empty_row then
   empty_row_count+=1

   for j=1,s-1 do
    for i=0,s do
     sset(bx+i,by+j-1,sget(bx+i,by+j))
    end
   end
   
   for i=0,s do
    sset(bx+i,by+s-1,0)
   end
  end
 end
 
 palt()

 local height=0
 for j=0,s do
  local empty_row=true
  
  for i=0,s do
   if sget(bx+i,by+j)!=0 then
    height+=1
    empty_row=false
    break
   end   
  end
  
  if empty_row then
   break 
  end
 end

 local width=s-2*max(0,smallest_x)+1
 
 return -flr(-width),-flr(-height)
end

es={}
es_next=1
es_active_count=0
es_sprs=nl("8,9,10,11,12,13,14,15,22,23,24,25,26,38,40,42,44,46,")
es_sprs_w={}
es_sprs_h={}

es_slots={}
es_slots_avail=0

for i=1,100 do
 add(es,{})
end

function es_reset()
 for k,e in pairs(es)do
  e.active=false
 end
 
 es_next=1
 es_active_count=0
end

function es_enemy_bounds(e)
 local x,y=e.x+flr((8*e.spr_size-e.spr_width)/2),e.y
 return x,y,x+e.spr_width,y+e.spr_height
end

function enemy_behaviors(e)
   local p1x=ps[1].x
   
   if p1x>e.basex+e.track_rate then
    e.basex+=e.track_rate
   elseif p1x<e.basex-e.track_rate then
    e.basex-=e.track_rate
   else
    e.basex=p1x
   end

   e.y+=e.speed
   e.x=e.basex+e.sin_mag*sin(e.sin_phase*e.lifetime)
   
   if e.y<10 then
    e.y=.9*e.y+1
   elseif e.y>128 then
    e.active=false
    es_active_count-=1
	dead_count+=1
   end
end

function es_init_launch_slots()
  for i=1,12 do
   es_slots[i]=i-1
  end
  
  es_slots_avail=#es_slots
end

function es_spawn(ed)
 if es_active_count>=#es then
  return
 end

 local e=es[es_next] 
 
 while e.active do
  es_next=next_i(es,es_next)
  
  e=es[es_next]
 end
 
 if es_slots_avail<=0 then
  es_init_launch_slots()
 end
 
 local slot_index=rnd_i(es_slots_avail)
 local last_slot=es_slots_avail
 
 local used_slot_value=es_slots[slot_index]
 
 es_slots[slot_index]=es_slots[es_slots_avail]
 es_slots[es_slots_avail]=-1
 
 es_slots_avail-=1
 
 e.basex=16+used_slot_value*8
 
 e.speed=rnd_range(ed.min_speed,ed.max_speed)
 e.x,e.y=e.basex,-8-e.speed
 
 e.sin_mag=rnd_range(ed.min_sin_mag,ed.max_sin_mag)
 e.sin_phase=rnd_range(ed.min_sin_phase,ed.max_sin_phase)
 e.spr=es_sprs[ed.spr]
 e.spr_size=(ed.spr<=13)and 1 or 2
 e.spr_width=es_sprs_w[ed.spr]
 e.spr_height=es_sprs_h[ed.spr]
 e.track_rate=rnd_range(ed.min_track_rate,ed.max_track_rate)
 
 e.bullet_type=ed.bullet_type
 
 e.shoot_rate=rnd_range(ed.min_shoot_rate,ed.max_shoot_rate)/gp_perc(.01)
 e.shoot_timer=e.shoot_rate
 e.bullet_speed=rnd_range(ed.min_bullet_speed,ed.max_bullet_speed)
 e.bullet_count=flr(ed.bullet_count*gp_perc(.1))
 
 e.bullet_count=min(40,e.bullet_count)
 
 e.bullet_a_inc=ed.bullet_a_inc
 e.bullet_a=0
 
 e.active=true
 e.lifetime=0
 e.health=ed.health*gp_perc(.2)
 e.damaged_timer=0
 
 es_active_count+=1
end

function es_damage(e,damage_amount,hit_x,hit_y)
 e.health-=damage_amount
 add_to_score(damage_amount,e.health)
 e.damaged_timer=0.1
 
 if e.health<=0 then
  sfx(2)
  e.active=false
  es_active_count-=1
  local ex=e.x+4*e.spr_size
  local exs_y=e.y+e.spr_height/2
  local ex_w=2+4*e.spr_size
  make_ex(ex,exs_y,ex_w,-.5,1,2)      
  bs_spawn(ex,exs_y,ex_w,20*e.spr_size,.4,bs_lines)
  dead_count+=1
 else
  sfx(3)
  make_ex(hit_x,hit_y,2,-0.2,1,2)
  bs_spawn(hit_x,hit_y,4,16,.2)
 end
end

function es_update()
 for k,e in pairs(es)do
  if e.active then
   e.lifetime+=one_frame
  
   if e.damaged_timer>0 then
    e.damaged_timer-=one_frame
   end
   
   enemy_behaviors(e)
   
   if e.bullet_type and e.shoot_rate>0 then
    e.shoot_timer+=one_frame
	
	if e.shoot_timer>=e.shoot_rate then
	 e.shoot_timer=0
	 
     local bx,by=e.x+e.spr_size*4-2,e.y+e.spr_height
     
     if e.bullet_type==0 then
      e.bullet_a+=e.bullet_a_inc
      ebs_shoot_spread(bx,by,e.bullet_speed,e.bullet_count,e.bullet_a)
     else
      ebs_shoot_aimed(bx,by,e.bullet_speed,e.bullet_count,e.bullet_a_inc)
     end
    end
   end
  end
 end
end

function es_draw_spr(e,ox,oy)
 spr(e.spr,e.x+ox,e.y+oy,e.spr_size,e.spr_size)
end

function es_draw()
 for k,e in pairs(es)do
  if e.active then
   pal_color((e.damaged_timer>0)and 7 or (e.shoot_rate!=0 and e.shoot_timer<.2)and 14 or 0)
   es_draw_spr(e, 1, 0)
   es_draw_spr(e,-1, 0)
   es_draw_spr(e, 0, 1)
   es_draw_spr(e, 0,-1)
   pal()

   if e.damaged_timer>0 then
     pal(11,10)
     pal(3,8)
     pal(5,9)
   end
 
   es_draw_spr(e,0,0)
   pal()
  end
 end
end

function enemy_desc(s,mi_s,ma_s,mi_p,ma_p,mi_m,ma_m,mi_tr,ma_tr,mi_sr,ma_sr,mi_bs,ma_bs,bt,bc,ba,h)
 return {
  spr=s,
  min_speed=mi_s,
  max_speed=ma_s,
  min_sin_phase=mi_p,
  max_sin_phase=ma_p,
  min_sin_mag=mi_m,
  max_sin_mag=ma_m,
  min_track_rate=mi_tr,
  max_track_rate=ma_tr,
  min_shoot_rate=mi_sr,
  max_shoot_rate=ma_sr,
  min_bullet_speed=mi_bs,
  max_bullet_speed=ma_bs,
  bullet_type=bt,
  bullet_count=bc,
  bullet_a_inc=ba,
  health=h,
 }
end

es_desc={
  enemy_desc(unpack(nl("1,1.5,2.5,0,0,0,0,0,0,0,0,0,0,0,0,0,1,"))),
  enemy_desc(unpack(nl("4,.5,1,.1,.5,4,6,0,0,0,0,0,0,0,0,0,2,"))),
  enemy_desc(unpack(nl("15,.05,.1,.1,.2,10,20,0,0,1,2,.5,1,0,6,.01,40,"))),
  enemy_desc(unpack(nl("10,.05,.1,.1,.2,10,20,0,0,1,3,1,2,0,1,0,4,"))),
  enemy_desc(unpack(nl("13,.05,.1,.1,.2,6,15,0,0,2,4,1,2,1,4,.25,4,"))),

  enemy_desc(unpack(nl("3,2,3,0,1,0,10,.5,1,0,0,0,0,0,0,0,1,"))),
  enemy_desc(unpack(nl("12,.01,.1,0,0,0,0,0,0,1,2,1,2,0,10,0,6,"))),
  enemy_desc(unpack(nl("18,.01,.05,.1,.2,10,16,.05,.2,1,2,1,2,1,10,.25,20,"))),
  enemy_desc(unpack(nl("14,.1,.2,.1,.2,10,16,0,0,.4,.8,1,2,0,4,.0125,6,"))),
  enemy_desc(unpack(nl("16,.05,.1,.2,.4,20,30,0,0,2,4,.2,.8,0,20,0,15,"))),

  enemy_desc(unpack(nl("17,.05,.1,0,0,0,0,0,0,.5,1,.5,1,0,3,.05,20,"))),
  enemy_desc(unpack(nl("2,2,4,0,0,0,0,0,0,.8,1.2,1,2,1,1,0,1,"))),
  enemy_desc(unpack(nl("11,.5,1,0,0,0,0,0,0,1,2,.2,.5,0,20,0,2,"))),
  enemy_desc(unpack(nl("9,.1,.2,.1,.2,2,4,0,0,.4,.8,1,2,0,5,.02,3,"))),
  enemy_desc(unpack(nl("7,.01,3,.01,.6,0,20,0,1,.1,4,.1,3,0,6,.05,3,"))),

  enemy_desc(unpack(nl("8,.01,1,.01,.6,0,20,0,.2,1,2,.1,.5,0,40,.05,5,"))),
  enemy_desc(unpack(nl("6,.01,.5,.01,.6,0,10,0,.2,.08,.1,.4,.6,0,1,.05,10,"))),
  --spr left:5
}

function m_boss_desc(h,sx,sy,s,sc,mi_o,ma_o,mi_c,ma_c,mi_sr,ma_sr,mi_bs,ma_bs,mi_bc,ma_bc,mi_bai,ma_bai,mi_bas,ma_bas,abc)
 return {
  health=h,
  speedx=sx,
  speedy=sy,
  size=s,
  shooter_chance=sc,
  min_opened_time=mi_o,
  max_opened_time=ma_o,
  min_closed_time=mi_c,
  max_closed_time=ma_c,
  min_shoot_rate=mi_sr,
  max_shoot_rate=ma_sr,
  min_bullet_speed=mi_bs,
  max_bullet_speed=ma_bs,
  min_bullet_count=mi_bc,
  max_bullet_count=ma_bc,
  min_bullet_a_inc=mi_bai,
  max_bullet_a_inc=ma_bai,
  min_bullet_a_spread=mi_bas,
  max_bullet_a_spread=ma_bas,
  aimed_bullet_chance=abc,
 }
end

levels={
 { --1
  spawn_rate=1,
  --wave_str="1-1",
  wave_str="10-1,10-2,10-1; 10-4,10-2,10-1; 1-3; 10-2,20-1,10-4; 2-3,10-1",
  boss=m_boss_desc(unpack(nl("5,.1,.2,3,.2,2,4,.2,.4,2,3,.5,1,2,8,.1,.2,.1,.5,.5,"))),
 },

 { --2
  spawn_rate=1,
  wave_str="10-5; 10-4,10-5,20-2; 1-8; 1-10; 1-8,1-10,1-8,1-10",
  boss=m_boss_desc(unpack(nl("10,.4,.7,8,.5,2,4,.2,.4,3,4,.4,.8,2,4,.02,.1,.1,.2,.5,"))),
 },
 
 { --3
  spawn_rate=.95,
  wave_str="4-9; 4-7,10-6; 6-9,2-3; 10-9,4-3,50-1",
  boss=m_boss_desc(unpack(nl("20,.8,.1,10,.7,2,3,.2,.6,4,6,.2,.4,10,16,.02,.1,1,1,.5,"))),
 },

 { --4
  spawn_rate=.9,
  wave_str="5-1,5-2,5-6,5-1,5-2,5-6,5-1,5-2,5-6; 10-4,10-5; 10-7,10-5; 6-7,6-5,6-4; 1-3,1-10,1-8,6-9",
  boss=m_boss_desc(unpack(nl("40,.05,.01,5,.3,.4,.8,1,2,.03,.06,.8,1,3,5,.001,.01,.05,.1,0,"))),  
 },
 
 { --5
  spawn_rate=.85,
  wave_str="2-11; 10-5,20-6; 10-7; 6-11; 6-7,20-6",
  boss=m_boss_desc(unpack(nl("60,.5,.1,2,.1,1,2,2,3,.03,.06,.8,1,4,8,.001,.005,.05,.1,0,"))),
 },
 
 { --6
  spawn_rate=.8,
  wave_str="20-12; 12-13,20-6; 12-14,20-6; 12-14,12-13,20-6; 6-8; 6-10",
  boss=m_boss_desc(unpack(nl("40,.6,.5,4,.4,.5,1,2,3,.05,.1,.8,1,4,8,0,0,.05,.1,1,"))),
 },

 { --7
  spawn_rate=.75,
  wave_str="20-14; 20-13; 20-12,2-9; 8-9,20-12; 10-11,20-12;",
  boss=m_boss_desc(unpack(nl("20,.1,.6,18,.8,.2,1,1,2,.5,2,.5,1,6,6,.02,.05,.01,.01,.5,"))),
 },
 { --8
  spawn_rate=.1,
  wave_str="100-1; 100-2; 100-6; 2-3,80-1; 6-7,100-2; 20-6,4-13,20-6,4-13,20-6,4-13,20-6,4-13,20-6,4-13; 4-8,40-1,40-1,40-6",
  boss=m_boss_desc(unpack(nl("20,.5,.5,10,.1,.1,.2,1,2,.03,.06,.8,1,3,7,.001,.01,.05,.1,0,"))),
 },

 { --9
  spawn_rate=.6,
  wave_str="1-3; 1-8; 1-9; 1-10; 1-11; 20-3; 3-8,12-9; 20-9; 20-11; 10-10,10-11;",
  boss=m_boss_desc(unpack(nl("10,.1,.2,8,.1,.4,.4,4,4,1,1,.8,.8,10,20,.01,.02,.5,.75,1,"))),
 }, 

 { --10
  spawn_rate=.8,
  wave_str="10-15; 10-16; 10-17; 40-15; 40-16; 40-17;",
  boss=m_boss_desc(unpack(nl("20,.3,.8,20,.5,.1,4,.1,4,.1,3,.3,1,1,30,.01,.25,.01,.99,.5,"))),
 },
}


function lv_waves_parse(levels)
 for k,level in pairs(levels)do
  local wave_index,bunches_index=1,1
 
  level.waves={}
  level.waves[wave_index]={}
  local current_wave=level.waves[wave_index]
  current_wave.bunches={}
 
  local current_num_str=""
  local current_bunch=nil
  local str=level.wave_str

  while #str>0 do
   current_wave=level.waves[wave_index]
  
   local d=sub(str,1,1)
  
   if d==" " then
   elseif d=="-" then
    current_wave.bunches[bunches_index]={}
    current_bunch=current_wave.bunches[bunches_index]
    current_bunch.count=current_num_str+0
    current_num_str=""
   elseif d=="," then
    current_bunch.type=current_num_str+0
    current_num_str=""
    bunches_index +=1
   elseif d==";" then
    current_bunch.type=current_num_str+0
    current_num_str=""
    wave_index +=1
    bunches_index=1
    level.waves[wave_index]={}
    current_wave=level.waves[wave_index]
    current_wave.bunches={}
   else
    current_num_str=current_num_str..d
   end
  
   str=sub(str,2)
  end
 
  if current_num_str!="" then
   current_bunch.type=current_num_str+0
   current_num_str=""
  end
 end
end

lv_waves_parse(levels)
get_file()
cur_level=levels[cur_lvl]

save_msg_timer=0
lv_timer=0
lv_scrolly1,lv_scrolly2=0,0
lv_target_scroll_speed=0
lv_scroll_speed=0
lv_wave_index=1
enemy_bunch_index=1
enemy_i=1
enemy_count=0
dead_count=0
lv_spawn_timer=0
lv_finished_timer=0
in_boss=false

function lv_regen_es()
 for i=1,#es_sprs do
  local num_pixels=6+i
  local size=(i<=13)and 1 or 2 
  local w,h=enemy_regen(es_sprs[i],size,size*num_pixels)
  es_sprs_w[i],es_sprs_h[i]=w,h
 end
end

function lv_start_level()
 cur_level=levels[cur_lvl]
 
 lv_scrolly1,lv_scrolly2=0,0
 in_boss=false
 lv_timer,lv_finished_timer=0,0
 lv_target_scroll_speed=1.5

 lv_wave_index=0
 
 lv_next_wave()
 lv_regen_es()
 
 boss_reset()
 
end

function lv_next_wave()
 enemy_count,dead_count=0,0
 enemy_i,enemy_bunch_index=1,1
 lv_wave_index+=1
 
 local cur_wave=cur_level.waves[lv_wave_index]
 lv_spawn_timer=cur_level.spawn_rate/gp_perc(.1)
 
 if lv_spawn_timer<.1 then
  lv_spawn_timer=.1
 end
 
 for i=1,#cur_wave.bunches do
  enemy_count+=cur_wave.bunches[i].count
 end
 
 es_init_launch_slots()
 
end

function lv_update()
 lv_timer+=one_frame
 save_msg_timer=max(0,save_msg_timer-one_frame)

 if lv_finished_timer>0 then
  lv_finished_timer-=one_frame
  
  if lv_finished_timer<=8 then
   lv_target_scroll_speed=10
  end
  
  if lv_finished_timer<=0 then
   cur_lvl=next_i(levels,cur_lvl)
   
   if cur_lvl==1 then
    cur_gp+=1
   end
   
   save_msg_timer=2
   store_file()
   ps_reset_nl()
   lv_start_level()
  end
  
 elseif in_boss then
  if not boss_active then
   lv_finished_timer=10
  end
 
 else
  lv_spawn_timer-=one_frame
  
  local cur_wave=cur_level.waves[lv_wave_index]  

  if lv_spawn_timer<=0 and es_active_count<#es then 
  
   if enemy_bunch_index<=#cur_wave.bunches then
    local enemy_bunch=cur_wave.bunches[enemy_bunch_index]
    es_spawn(es_desc[enemy_bunch.type])
	
    enemy_i+=1
    
    if enemy_i>enemy_bunch.count then
     enemy_bunch_index+=1
     enemy_i=1
    end
    
    lv_spawn_timer=cur_level.spawn_rate/gp_perc(.1)
   end
  end
 
  if dead_count>=enemy_count then
   
   if lv_wave_index>=#cur_level.waves then
    if cv!=fev then
	 music(30)
	end
	
    in_boss=true
    lv_target_scroll_speed=.1

    boss_desc=cur_level.boss
	make_boss()
   else
    lv_next_wave()
   end
   
  end
 end
 
 -- scrolling map
 local scroll_accel=.1
 
 if lv_scroll_speed+scroll_accel<lv_target_scroll_speed then
  lv_scroll_speed+=scroll_accel
 elseif lv_scroll_speed-scroll_accel>lv_target_scroll_speed then
  lv_scroll_speed-=scroll_accel
 else
  lv_scroll_speed=lv_target_scroll_speed
 end 
 
 sf_scroll_speed=lv_scroll_speed
 sf_target_rate=lv_scroll_speed
 
 if sf_rate+scroll_accel<sf_target_rate then
  sf_rate+=scroll_accel
 elseif sf_rate-scroll_accel>sf_target_rate then
  sf_rate-=scroll_accel
 else
  sf_rate=sf_target_rate
 end 
 
 sf_max_speed=4*lv_scroll_speed
 
 sf_update()

 lv_scrolly1+=.2*lv_scroll_speed
 lv_scrolly2+=lv_scroll_speed
 
end

function lv_draw()

 sf_draw()

 local lv_map_type=cur_lvl-1
 local l_cell=lv_map_type*8
 local r_cell=l_cell+4

 local ox=0
 
 if lv_timer<=5 then
  ox=48*(5-lv_timer)/5
 elseif lv_finished_timer>0 then
  ox=48*(10-lv_finished_timer)/10
 end
 
 local s1endy=lv_scrolly1%128
 local s1starty=s1endy-128
 local s1startx,s1endx=-ox,96+ox
 
 map(l_cell,0,s1startx,s1starty,4,16)
 map(r_cell,0,s1endx,s1starty,4,16)

 map(l_cell,0,s1startx,s1endy,4,16)
 map(r_cell,0,s1endx,s1endy,4,16)

 local s2endy=lv_scrolly2%128
 local s2starty=s2endy-128
 local s2startx,s2endx=s1startx-3,s1endx+3
 
 map(l_cell,16,s2startx,s2starty,4,16)
 map(r_cell,16,s2endx,s2starty,4,16)

 map(l_cell,16,s2startx,s2endy,4,16)
 map(r_cell,16,s2endx,s2endy,4,16)

end

fev={}
fev.start=function()
 sf_init()
 lv_start_level()
 title_timer=0
end

fev.update=function()

 if btnp(2) then
  file-=1
  file%=3
  get_file()
 end

 if btnp(3) then
  file+=1
  file%=3
  get_file()
 end
 
 title_update()
 sf_update()
 lv_update()
 ps_upgrades_update()
 es_update()
 ebs_update()
 if btn(4)or btn(5)then
  set_view(gv)
 end

 blink_text_update()
end

function fev_title_draw(by,phase,c,bc)
 local x,y=64+10*cos(time/3-phase),by+5*sin(time-phase)
 po("\\_____/",x,y-12,c,bc)
 po(".the.",x,y-12,c,bc)
 po("\\_.green._/",x,y-6,c,bc)
 po(".legion.",x,y,c,bc)
 po(".______.",x,y+2,c,bc)
 po("   ___   ",x,y+4,c,bc)
 po("/   __   \\",x,y+6,c,bc)
 po("    .    ",x,y+8,c,bc)
 po("/ \\",x,y+10,c,bc)
end

title_timer=0

function title_update()
 if title_timer<1 then
  title_timer+=one_frame
 end
end

function title_draw()
 local by=lerp(-20,40,title_timer)
 fev_title_draw(by,.2,5,1)
 fev_title_draw(by,.1,2,3)
 fev_title_draw(by,0,8,11)
end

blink_text,blink_text_on=0,true

function blink_text_update()
 blink_text-=one_frame
 
 if blink_text <=0 then
  blink_text=.1
  blink_text_on=not blink_text_on
 end
end

fev.draw=function()
 lv_draw()
 draw_ui()
 
 es_draw()
 ebs_draw()
 title_draw()
 
 po("ship a: "..scr_text(dget(0)),32,80,8,11,align_l)
 po("ship b: "..scr_text(dget(4)),32,88,8,11,align_l)
 po("ship c: "..scr_text(dget(8)),32,96,8,11,align_l)
 
 po(">",25,80+file*8,8,11,align_l)
 
 po("press z or x to start",64,110,8,blink_text_on and 11 or 3)
 po("guerragames 2016",64,121,2,3)
end

gv={}

gv.start=function()
 music(0)

 shake_t=0
 exs_reset()
 bs_reset()
 boss_reset()
 lv_start_level()
 es_reset()
 ebs_reset()
 ps_reset_ng()
 ps[1].x=60
 ps[1].y=136
 
 gameover=false
end

gv.update=function()
 if shake_t>0 then
  shake_t-=one_frame
  camera(rnd_range(-1,1),rnd_range(-1,1))
 else
  camera()
 end
 
 blink_text_update()
 
 if gameover then
  title_update()
  
  if title_timer>1 then
   if btn(4)or btn(5)then
    gv.start()
   end
  end
 end

 lv_update()
 
 if not gameover then
  ps_update()
 end
 
 bullets_update()
 
 boss_update()

 es_update()

 ebs_update()
 
 if not gameover then
  _touch()
 end
 
 exs_update()
 bs_update()
end

function print_ui_l(txt,y)
 po(txt,1,y,7,1,align_l)
end

function draw_ui()
 print_ui_l("exp:"..scr_text(cur_score),1)
 
 local lvl_text="w-"..cur_lvl
 if cur_gp>0 then
  lvl_text="ng+"..cur_gp.." "..lvl_text
 end
 
 po(lvl_text,128,1,7,1,align_r)
 
 print_ui_l(next_upgrade_txt(),7)
 print_ui_l("lvl:"..ps_level,13)
 
 if cv==fev then
  print_ui_l("deaths:"..cur_gm,19)
 end
end

gv.draw=function()
 lv_draw()
 
 --local line=128
 --line-=6
 --print("mem:"..stat(0),0,line,7)
 --line-=6
 --print("cpu:"..stat(1),0,line,7)
 --line-=6

 if save_msg_timer>0 then
  po("game saved!",64,110,8,blink_text_on and 11 or 3) 
 end
 
 draw_ui() 
 
 boss_draw()

 exs_draw()

 if not gameover then
  ps_draw_secondary()
 end
 
 es_draw()

 if not gameover then
  ps_draw_first()
 end
 
 bs_draw()

 bullets_draw()

 ebs_draw()

 if gameover then
  title_draw()
  po("game over",64,70,blink_text_on and 8 or 2,blink_text_on and 11 or 3)
  po("press z or x to continue",64,80,blink_text_on and 8 or 2,blink_text_on and 11 or 3)
 end
end

cv=fev

function set_view(new_view)
 cv=new_view
 cv.start()
end

function views_update()
 cv.update()
end

function views_draw()
 cv.draw()
end

function _init()
 menuitem(1,"die and save!?",save_and_reset)
 menuitem(2,"reset score!?",reset_score)
 
 music(40)

 sf_init()

 set_view(fev)
end

function _touch()
 if in_boss then
  for k,b in pairs(bullets)do
   if b.active then
    if boss_check_damage(b,1,bullets_check)then
     b.active=false
    end
   end
  end
 end
 
 for k,e in pairs(es)do
  if e.active then
   local min_x,min_y,max_x,max_y=es_enemy_bounds(e)

   local hit=ps_check(min_x,min_y,max_x,max_y)
   local hit_x,hit_y=e.x+4,max_y
   
   for k2,b in pairs(bullets)do
    if b.active then
	 if bullets_check(b,min_x,min_y,max_x,max_y)then
      b.active=false
	  hit=true
	  hit_x=b.x+1.5
	  break
     end
    end
   end

   if hit then   
    es_damage(e,1,hit_x,hit_y) 
   end
  end
  
 end
end

function _update()
 time+=one_frame
 views_update()
end

function _draw()
 cls()
 views_draw()
end

__gfx__
00070000000700000067600000070000000700000007000000070000000700000707070007070700000700000007000000070000000700000007000000070000
006c6000606c6060067c7600006c6000076c6700006c6000066c6600006c6000006c6000706c6070006c6000006c6000006c6000006c6000076c6700706c6070
007c7000707c7070077c7700007c7000707c7070007c7000607c7060007c7000007c7000007c7000007c7000067c7600007c7000067c7600007c7000077c7700
707c7070707c7070677c7760067c7600707c7070707c7070707c7070607c7060707c7070707c7070607c7060707c7070607c7060706c6070707c7070707c7070
76777670767776707677767067777760767776707677767070777070767776707677767076777670767776707607067070777070700700707677767076777670
60676060606760607067607077676770606760607067607070676070706760706067606060676060706760707067607070676070006760007067607070676070
000a0000000a0000600a0060760a0670000a0000600a0060700a0070700a0070000a0000000a0000070a0700060a0600760a0670070a0700070a0700600a0060
00000000000000000000000060000060000000000600060060000060760006700000000000000000006060007000007070000070000000006000006006000600
00088888000000000000888000000000000088800000000000000000000000000000000000000000000000000088880000888800009a9900000a900000009000
008999998000000000089998000000000008aaa800000000000000000000000000000000000000000000000008aaa98008aaa980090007900000009000000090
089aaaaa980000000089aaa9800000000008aaa80000000000000000000000000000000000000000000000008aa7aa988a707a98900000980000000900000000
089aaaaa980000000089aaa9800000000008aaa80000000000000000000000000000000000000000000000008a777a988a000a98a00000a80000000a0000000a
89aaaaaaa98000000089aaa98000000000008a800000000000000000000000000000000000000000000000008aa7aa988a707a9890000098a000000900000009
09aaaaaaa90000000008aaa80000000000008a8000000000000000000000000000000000000000000000000089aaa99889aaa998970007989000000990000000
89aaaaaaa980000000089a980000000000000a000000000000000000000000000000000000000000000000000899998008999980099a99800a00009000000090
09aaaaaaa900000000089a980000000000000a0000000000000000000000000000000000000000000000000000888800008888000088880000999a0000909000
089aaaaa9800000000089a980000000000000a00000000000000030003000000000b0303030b00000000030003000000000b0303030b00000000030003000000
0899aaaa9800000000089a980000000000000a00000000000b00330003300b000b0b3333333b0b000b00330003300b000b0b3333333b0b000b00330003300b00
0899aaaa9800000000089a980000000000000000000000000b003b030b300b000b0b3b333b3b0b000b003b030b300b000b0b3b333b3b0b000b003b030b300b00
089aa9aa9800000000089a980000000000000000000000000b0b03b3b30b0b000b00bb333bb00b000b0b03b3b30b0b000b00bb333bb00b000b0b03b3b30b0b00
089aa9a99800000000089a980000000000000a00000000000b0bb33333bb0b0003b0bb333bb0b3000b0bb33333bb0b0003b0bb333bb0b3000b0bb33333bb0b00
089aaaa99800000000089a980000000000000a000000000003330bb8bb0333000330bb383bb0330003330bb8bb0333000330bb383bb0330003330bb8bb033300
089a9aa99800000000089a980000000000000a0000000000000bb3b8b3bb00000b30033833003b00000bb3b8b3bb00000b30033833003b00000bb3b8b3bb0000
089a9aaa9800000000089a980000000000000000000000000b00b3b3b3b00b000b300bb3bb003b000b00b3b3b3b00b000b300bb3bb003b000b00b3b3b3b00b00
089aaa9a9800000000089a980000000000000a00000000000b003bb3bb300b000bbb3bb3bb3bbb000b003bb3bb300b000bbb3bb3bb3bbb000b003bb3bb300b00
089a9a9a9800000000089a980000000000000a00000000000b333b030b333b00bb3b3b030b3b3bb00b333b030b333b00bb3b3b030b3b3bb00b333b030b333b00
08999a99980000000008999800000000000000000000000000b33b000b33b000003b3b0b0b3b300000b33b000b33b000003b3b0b0b3b300000b33b000b33b000
08999a99980000000008999000000000000000000000000000b33b000b33b0000b333bbbbb333b0000b33b000b33b0000b333bbbbb333b0000b33b000b33b000
00989998980000000008989000000000000000000000000000bb0300030bb0000b3b330b033b3b0000bb0300030bb0000b3b330b033b3b0000bb0300030bb000
0098999890000000000090900000000000000a0000000000000b0b000b0b00000b303b0b0b303b00000b0b000b0b00000b303b0b0b303b00000b0b000b0b0000
0090898080000000000090800000000000000a0000000000000000000000000000b03b000b30b000000000000000000000b03b000b30b0000000000000000000
00800800000000000000800000000000000000000000000000000000000000000000300000300000000000000000000000003000003000000000000000000000
44444444100000000000000000000000000000010000a00000bbb3000bbbbb03053bb0301111111199949994000000000011110001110000000011100eeeeee0
455555542110000000000000000000000000001200aaa20003333b30053b000bb5b335b0111111119994999400000000012222101c2210000001c221e1222215
44444444521100000000000000000000000011250a222a203b3bb3b03533553b3535553b444444419144444444444000122c22211222100000012221e2ee5525
5555455455111100000000000000000000111155a22822a053b33bb53350550505053b5599999991911999999999900012c222211222111001112221e2111125
4444444444521110000000000000000001112544028a82aa3b3bb3b5bb353b30035bbbbb99999991911999999999900012c222210111c2211c221110e2ee5525
455454554445521100000000000000001125544402a82a2053b33b50b335b3b50b503b55111111119111111111199000122222210001222112221000e2111125
4444444445444521100000000000000012544454002aa200003bb55330503b353bb03350111111119994999400199000012222100001222112221000e1222215
4445544444455551110000000000001115555444000a00000055503b003b55000033550011411411999499940019900000111100000011100111000005555550
4555445544444445211000000000011254444444000a00003305550030bb353bbbb035bb0000111199949994001990000001100001101100011000000eeeeee0
4444444455544555511000000000011555544555002aa200bb353b30b0b330b3b550b503000011119994999400199000001c21001c21c2101c210000e2111125
445554444445554452110000000011254444444402a22a20b335b3b03535503b3053b303144444419144444444499000001221001221221012210000e2ee5525
45544455444444445511000000001155444555440a2282aa30003b3555553b0050555330119999919119999999999000011110110110110001100000e2111125
4444554444554455445110000001154455544555aa28a8a0553b0555535b333b53b35bb31199999191199999999990001c2111c21110111000000000e2ee5525
55454444455555444521100000011254445444440a228a205bbbbb5b0b00bbb30b3b5b3b111111119111111111111000121c21221c211c2100000000e2111125
544444544444444445111000000111544555554400a22200003b500b3bb5333003b35300000011119994999400000000011221110221122100000000e2ee5525
4445545545544455452110000001125455444554000a00003033503300335500b005550300001411999411110000000000011000011001100000000005555550
44545444444444554211000000001124554455550000a000b3b0b330005553303300550000001111999400000000000000000000000001100000000000e22500
5554444545554444452100000000125444444444002aa2003b3535500bbb3500bb353b300000111199940000000000000000000000001c210000000000e22500
444444444444454445111000000111544455554402a28a205055503b3333b350b335b3b544444441914444440144444400000000000012210000000000e22500
4455544554555555445110000001154455444444aa28a820bb535bbbb3bb3b5335003b3599999991911999990119999900000000000001100000000000e22500
44444554444444545521100000011255444455550a22822a5003503b3b33bb55553b550099999991911999990119999901100000000000000000011000e22500
555554445555544451110000000011154444444402a222a0553bb03333bb3b535bbbbb031111111191111111011990001c2100000000000000001c2100e22500
4444444544444455211000000000011255544454002aaa00005533003b33b550053b550b00001111999400000119900012210000000000000000122100e22500
44455545445555451100000000000011545555440000a0003b30bb3003bb503030b3503b00001411999400000119900001100000000000000000011000e22500
44454544445555211000000000000001155555440000a0003300555035053b303b3035500000000000000000011990000111000000000000000011100eeeeee0
544444545544211100000000000000001254445500222a00bb303b30553b55500055503b0000000000000000011990001c221000000000000001c221e2222225
444444444445110000000000000000000115544402a822a0b335b3b55bbbbb53bb530bbb144444444444444401199444122210000000000000012221e2eeee15
54455554445210000000000000000000001125440a8a82aa30553b35553b5503505b503b119999999999999901199999122210000111000000012221e2eee515
4554444455110000000000000000000000011155aa2822a0553b0550303350bb553b3033119999999999999901199999011100001c22100000001110e2ee5515
444555555110000000000000000000000000011502a22a205bbbbb533305555005553350111111111111111101111111000000001222100000000000e2e55515
5444444451000000000000000000000000000125002aa200003b5503bb353b353b35bb30000000000000000000000000000000001222100000000000e2111115
5455544421000000000000000000000000000012000a000030330033b330b3b0b3b0b30000000000000000000000000000000000011100000000000005555550
3888888891100000810000000000011988888883100000100010000177aaa99a9999880099888880dd6700000000000000000000000076dd8850000055756767
33333388889111009810100000111988883333331500051011500005a77a99999898888899999988dd6770070000000000000000700776dd8566770055756777
3333888989554410899141000144559898883333515051510515000177a7aaa899a9980099a98800d666700070000000000000070007666d8566667055757670
433333888955554199551000145555988833333400101500005155157a7777aaa9888000a9999000d666770070000000000000070077666d8566666757557670
3444333899555554881100004555559983334443000150000000110077aaaa999999888098888880dd6667707007000000007007077666dd8560000757567677
333338888951111498100000411115988883333300015000005100157a7aaaa9a8888000a9800000dd6667070000700000070000707666dd8850000057567670
3388888898910001891000001000198988888833051010000510005177aa7a999998880088880000d6d66670000070000007000007666d6d8800000057567670
333388888110000081000000000001188888333301505151115000007aaaa99a9880000098000000ddd66667700070000007000776666ddd8000000057767670
3443388881100000810000000000011888833443000005111515051077aaaa998988000098800000ddd66766770070000007007766766ddd8000000057767670
33388888989100019810000010001989888883331500015000010150a7a77aaa9888880099988000dddd676677770700007077776676dddd8800000057567670
33333388895111148810000041111598883333335100150000051000777aaaa99998000099880000d6dd676667700000000007766676dd6d8850000057557670
444438883955555489810000455555938883444400110000000510007a77aa999880000098800000d6d66666670700000000707666666d6d8560000757557677
3333333889555541995510001455559883333333515515000051010077aaa7aaa9988000a9998800dd6666667000700000070007666666dd8566666777657670
333888888955441089914100014455988888833310005150151505157a7aaaa98888000099880000dd6676670000700000070000766766dd8566667075757670
3433338998911100981010000011198998333343500005110150005177a7a9989999888899998880d666767700070000000070007767666d8566770075756777
333388888110000081000000000001188888333310000100010000017aaaaa998988800099888000d666677000000000000000000776666d8850000055766767
3333333311111000810000000000001800011111000000151500000000888899a99aaa77a77aaa77d666677000000000000000000776666d8800000076765755
33444334995541009811100000011189001455995500051515000550889999999999a77a7777a77ad666767700070000000070007767666d8566700077765755
3333343389555410895541000014559801455598015001510150510000889a989aaa7a7777777777dd6676670000700000070000766766dd8566670007675755
333333448991141099555410014555990141199805151550001010000000899aaa7777a7aa7777a7dd6666667000700000070007666666dd8550070007675575
444333339810110099911410014119990011018900015000000150000888888998aaaa77777aaa77d6d66666770700000000707766666d6d8800000077676575
333344448991410088810100001018880014199800515000005150000000089a9aaaa7a77aa77777d6dd676677700000000007776676dd6d8550700007676575
334433339955100098100000000001890001559905101500051015000008888899a7aa7777777777dddd676677770070070077776676dddd8566000007676575
3333333411110000810000000000001800001111010005005100015000000089a99aaaa7a77aaaa7ddd66766770077000077007766766ddd8800000007676775
344443331111000081000000000000180000111110000010000000000000088889aaaa7777a77777ddd66677007000000000070077666ddd8800000007676775
3333344489551000981000000000018900015598150005150000000000088999aaa77a7aaaa77a7ad6d66770000700000000700007766d6d8566000007676575
333333339991410088100100001001880014199901500151000000000000889998aaa77777777777dd6667000007000000007000007666dd8550700007675575
444433338810110099911410014119990011018805101500000000000000088899aa77a777aa77a7dd6667770007000000007000777666dd8800000077675575
333344438991141099555410014555990141199800515000000000000088899aaa7aaa77aa7aaa77d666770070700000000007070077666d8550070007675677
33333333995554108955410000145598014555990001500000000000000088999aaaa7a777777777d666707000000000000000000707666d8566670007675757
3444344489554100888110000001188800145598000500000000000008889999999a7a7777777777dd6770070000000000000000700776dd8566700077765757
333333331111100081100000000001180001111100050000000000000008889989aaaaa777aaaaa7dd6777000000000000000000007776dd8800000076766755
a8a00000a8a0000007000000e0600000006b3b000033330000333300003333000052250000333300003333000033330000333300003333000033330000333300
a9a000000a000000e8e0000008000000065443b0036b3b30036b3b30036b3b3005402420036bbb3003600b30036bbb300006b0000036b300036bbb30036bbb30
0a000000000000000700000060e000006548843b363443b336b33bb336bb3bb35405000236bbbbb336b33bb336bbbbb3300330033336b33336b33bb3363030b3
0a0000000000000000000000000000003488884b334884b3333883b333333bb34000002536bbbbb336bbbbb3303bb3033636b3b336bbbbb3363003b3363030b3
0000000000000000000000000000000064888843364884333638833336b333332002000236bbbbb336bbbbb3303bb3033636b3b336bbbbb3363003b3363030b3
000000000000000000000000000000006348843b363443b336b33bb336b3bbb35450204236bbbbb336b33bb336bbbbb3300330033336b33336b33bb3363030b3
00000000000000000000000000000000063443b00363bb300363bb300363bb3002450420036bbb3003600b30036bbb300006b0000036b300036bbb30036bbb30
000000000000000000000000000000000063bb000033330000333300003333000054420000333300003333000033330000333300003333000033330000333300
00000000ee20000000ee00000002ee00003333000033330000333300003333000052550000333300003333000033330000333300003333000030030000300300
02ee2000e2ee200002ee200002ee2e00036bbb30036bbb30036bbb30036bbb3005402420036bbb30036bbb30036bbb30036bbb30000bb000000bb00003600b30
ee72ee002e62e0000e72e0000e62e200363333b3363333b3363333b336bbbbb354000042363003b3363030b3360000b33603b0b330633b0330633b0336b33bb3
ee22ee000e22e2000e22e0002e22e0006388883b6388883b338888333333333320200025360000b3360303b3363333b3360b30b3363003b3063003b036bbbbb3
02ee200002ee2e0002ee2000e2ee20006488884b6348843b363333b336bbbbb322050505360000b3363030b3360000b33603b0b3363003b3063003b036bbbbb3
000000000002ee0000ee0000ee2000006348843b363443b336bbbbb336bbbbb354500042363003b3360303b3363333b3360b30b330633b0330633b0336b33bb3
00000000000000000000000000000000063443b003633b30036bbb30036bbb3002440420036bbb30036bbb30036bbb30036bbb30000bb000000bb00003600b30
00000000000000000000000000000000006bbb00003bb30000333300003333000025520000333300003333000033330000333300003333000030030000300300
0ee000000eee000002ee200000eee000006bbb00003bb30000333300003333000055550000e22e0000333300003003000000000000000000000a000000000000
e72e0000e722e0002e72e2000e722e00065445b006633bb0036bbb30036bbb300540242000e22e00036bbb3003600b30000a00a000000000000aa00000000000
e22e0000e222e000e7222e00e72222e06548845b363443b336b33bb336bbbbb35405004200e22e00336bbb3336b33bb30a0a00a00000000000aaa00000000000
0ee00000e222e000e2222e00e22222e06488884b6348843b363883b336b33bb35000200500e22e000036b3000036b3000a0a0aa0000a00a000a9aa00000a0000
000000000eee00002e22e200e22222e06488884b6348843b363883b336b33bb32200000200e22e000036b3000036b300a909aa9a0a0a00900a999aa000aaa000
000000000000000002ee20000e222e006548845b363443b336b33bb336bbbbb35450204200e22e00336bbb3336b33bb3a9a9a9aa09a9a9900a9899a000a99a00
00000000000000000000000000eee000065445b006633bb0036bbb30036bbb300242042000e22e00036bbb3003600b300aa889a009aa9a900a9889a000a89a00
00000000000000000000000000000000006bbb00003bb30000333300003333000055220000e22e0000333300003003000098890000988a0000a88a0000a88a00
00eeee00070000000a000000070000000036bb000033330000333300003333000055550000e22e00003003000033330003333330033333300333333003333330
0e7722e079700000a8a000007970000003344bb00353bb30035bbb30036bbb300540202000e22e00036bbb300000600036bbbbb336bbbbb3036bbb30036bbb30
e772222ea9a0000078700000a9a00000338884bb35883bb33583bbb3363bbbb35400020200e22e0036b33bb33000300336bbbbb3333333330036b3000036b300
e722222e7a70000097a000007a7000006488884b338883b336383bb336b3bbb35040000500e22e00063003b03636b003036bbb30036bbb300033330000033000
e222222ea9a000000a900000a9a000006488884b3638883336b383b336bb3bb32005050400e22e00063003b03006b3630036b300003333000036b3000036b300
e222222e7090000007000000907000006b48883336b3885336bb385336bbb3b35450204200e22e0036b33bb330030003036bbb30036bbb3003333330036bbb30
0e2222e090000000090000000090000006b44330036b3530036bb530036bbb300200042000e22e00036bbb3000060000036bbb30036bbb30036bbb30036bbb30
00eeee0000000000000000000000000000bbb30000333300003333000033330000552200000ee000003003000033330000333300003333000033330000333300
__gff__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
41000000000043444600000000000047696a7a000000596a4d0000000000005c4f0000000000005f8f000000000000bf878800000000a7a88a8b000000008c8d85000000000000858100000000000083450000000000005581000000000000838500000000000085000000000000000000000000000000000000000000000000
71000000004344545657000000004747696a4b006b7a696a5d4c5e0000005c4d6f5f00000000006f8f000000000000bf979800000000b7b89a9b000000009c9d8500000000000085908100000000a3944545550000000075908100000000a3948500000000000085000000000000000000000000000000000000000000000000
62000000006354546600000000484700696a5b000000596a5d7c00006e4e4d4c6f6f00000000006f9f000000000000af878800000000a7a88a0000000000acad958500a50000858580a100000000b384005555455500005580a100000000b384958500a500008585000000000000000000000000000000000000000000000000
41420000005361614647460000465746696a7a00007b696a4c7d0000005d004c5f5f5f0000004f5f9f000000000000af979800000000b7b89a9b00000000bcbd950085a500a5b585809200000000839445450000757500758092000000008394950085a500a5b585000000000000000000000000000000000000000000000000
51520000006354545657000000466666696a7a7a0079696a4c4c0000004c6e4c6f006f0000007f6f8f000000000000bf878800000000a7a88a0000000000acad85b5b500b5a5859590910000000000a4550000000055757590910000000000a485b5b500b5a58595000000000000000000000000000000000000000000000000
51620000000074616647000000005757696a7a4b007b696a5d4c00005d4c4c5c6f006f000000006f8f000000000000af979800000000b7b89a9b00000000bcbd85850000a585969590b2000000009394550000000000750090b200000000939485850000a5859695000000000000000000000000000000000000000000000000
71720000000063547677780000004757696a4b00007b696a4c6d5e005c7c4c4c4f007f000000005f9f000000000000af878800000000a7a88a8b00000000acad9696000000a696969200000000008384550000007575750092000000000083849696000000a69696000000000000000000000000000000000000000000000000
52000000000073744647480000004748696a00007b7a696a5c6c4c0000006e4c6f000000007f006f8f000000000000bf979800000000b7b89a9b00000000bcbd85b585000000b585a2000000009394b00000000000005565a2000000009394b085b585000000b585000000000000000000000000000000000000000000000000
62000000000000635646474800000047696a0000797a696a4c4d4c0000004c4d6f7f0000006f006f8f000000000000bf878800000000a7a88a8b00000000acad85000000000000859100000000b384b000007575000000759100000000b384b08500000000000085000000000000000000000000000000000000000000000000
41420000000043446656000000770046696a7a7a6b7a696a4c7c4c7d00007d4c6f6f0000006f006f9f000000000000af979800000000b7b89a9b00000000bcbda6a6000000008585808100000000838455757500000055758081000000008384a6a6000000008585000000000000000000000000000000000000000000000000
51414200000063547666006800467747696a5b007b00596a5d4d4c0000004d5d6f6f0000005f5f6f9f000000000000af878800000000a7a8aaab000000009cada6a6000000869696909100000000a4945555000000555575909100000000a494a6a6000000869696000000000000000000000000000000000000000000000000
60515200004344544776777800007647696a7a00007b696a4c5c7d0000004c5d6f6f0000006f6f6f8f000000000000bf979800000000b7b8babb000000009c9d8585850086a6008690a10000008384b0550000007575007590a10000008384b08585850086a60086000000000000000000000000000000000000000000000000
61616200005354615657560000006747696a00000000596a4c6e5e006e4c7c4c6f6f0000006f6f6f8f000000000000af878800000000a7a8aaab000000008c8d0096b5000000b585b0808100b494b0a00000000000750000b0808100b494b0a00096b5000000b585000000000000000000000000000000000000000000000000
50710000006361546667780000000047696a4b000079696a4c4e00004e4c5d4c5f5f5f00005f6f5f8f000000000000bf979800000000b7b8babb000000009c9db596000000000085a090b100008384b00000000000000055a090b100008384b0b596000000000085000000000000000000000000000000000000000000000000
71720000007374617667000000004746696a5b000000596a4c4c00004c4c6e4c5f007f00005f4f5f8f000000000000bf878800000000a7a8aaab000000008c8d858686000000a5a5909100000000a4947500000000000055909100000000a494858686000000a5a5000000000000000000000000000000000000000000000000
62000000000000744600000000000048696a7a00006b696a5c6d4c005c007e5c6f000000007f006f9f000000000000af979800000000b7b8babb000000009c9d96a50000000096a5a1000000000000837545757500005575a10000000000008396a50000000096a5000000000000000000000000000000000000000000000000
62000000000043445600000000484848696a00000079696a4e0000000000004c6f4f00000000006f9f000000000000af878800000000a7a8babb000000008c8d96000000000000a591000000000000a4000045000075757591000000000000a496000000000000a5000000000000000000000000000000000000000000000000
41000000000063546600004800470048696a4b000079696a4c000000004c5c4e6f6f00000000007f8f000000000000bf979800000000b7b88a8b00000000acada6000000b586a5a580b200000000b384007500000075750080b200000000b384a6000000b586a5a5000000000000000000000000000000000000000000000000
71000000000073747648006800470046696a7a5b0000596a5c004c0000004c4c6f6f00000000006f8f000000000000af878800000000a7a89a9b00000000bcbda6a600000086a600b0809100008384a00075000000007500b0809100008384a0a6a600000086a600000000000000000000000000000000000000000000000000
62000000000000634676777800000057696a7a7a007b696a4c5c4e4c6c004c4d4f4f00000000006f8f000000000000bf979800000000b7b88a8b00000000acad850000000000a6b5b090a100a494a0b07575750075000075b090a100a494a0b0850000000000a6b5000000000000000000000000000000000000000000000000
41420000000043444647480000004757696a4b00006b696a4d4c4c004c00005c6f0000000000004f8f000000000000bf878800000000a7a89a9b00000000bcbd850000000000a696a090b200b384b0a07575750075750065a090b200b384b0a0850000000000a696000000000000000000000000000000000000000000000000
51520000000063645657580067574747696a5b000000596a5c5d4e004c4d6c4d6f7f00000000006f9f000000000000af979800000000b7b8aaab000000009c9d85b500000000969690a1000000a494a0006500000075757590a1000000a494a085b5000000009696000000000000000000000000000000000000000000000000
60620000000063546667680000005747696a5b000079696a4c4d4c005c4c6e4c6f6f000000004f5f9f000000000000af878800000000a7a8babb000000008c8d85960000000000859091000000b484a000750000007500009091000000b484a08596000000000085000000000000000000000000000000000000000000000000
71000000004344647646474700675746696a7a00007b696a5c004c00004c004e6f6f000000006f5f8f000000000000bf979800000000b7b8aaab000000009c9d0096b500000000b592000000009394b0000000000000000092000000009394b00096b500000000b5000000000000000000000000000000000000000000000000
41420000006364640056575700665747696a00000000596a4c6c6d5c6e4c5c4c4f4f000000006f6f8f000000000000bf878800000000a7a8babb00000000acad0000000000000085909200000000a4847565750000750055909200000000a4840000000000000085000000000000000000000000000000000000000000000000
51410000007374640066670000736656696a0000006b696a4e4c4c4d7d004c4c6f00000000006f6f8f000000000000bf979800000000b7b8aaab00000000bcbd0000a6000000858590b10000000000b4555575555555656590b10000000000b40000a60000008585000000000000000000000000000000000000000000000000
60710000000073744647570000004656696a5b00006b696a4c005d4c4c6c4c5c6f000000004f5f6f9f000000000000af878800000000a7a8babb00000000acad0085b500008595a690b1000000008394757500000000655590b10000000083940085b500008595a6000000000000000000000000000000000000000000000000
71720000000000635657670000005647696a4b00007b696a4c6c00004c6e5c4e6f5f5f00007f006f9f000000000000af979800000000b7b89a9b00000000bcbd9595000000008500b080b2000000b3940075000000000075b080b2000000b3949595000000008500000000000000000000000000000000000000000000000000
52000000000000444647000000004647696a7a4b7b7a696a5c4c00005d4c4c4d6f6f6f000000006f8f000000000000bf878800000000a7a89a9b000000008c8d950000000000a685b0a08081008394b00000650000657575b0a08081008394b0950000000000a685000000000000000000000000000000000000000000000000
62000000000000745600000000676647696a7a4b0000596a4d5c4c00006e4c4c5f5f6f000000006f8f000000000000af979800000000b7b8babb000000009c9d85a6000000009595b08091000000a4945575750055750065b08091000000a49485a6000000009595000000000000000000000000000000000000000000000000
41000000000000536667000000005678696a4b000000596a4c4c6c00006e5d4c6f007f000000006f9f000000000000af878800000000a7a8aaab000000008c8d959500000000009590b2000000008384557500000000656590b20000000083849595000000000095000000000000000000000000000000000000000000000000
71000000000000637600000000000078696a5b00006b696a4e5e000000006d5c5f0000000000007f9f000000000000af979800000000b7b8babb000000009c9d8500000000000085b1000000000000b45500000000000075b1000000000000b48500000000000085000000000000000000000000000000000000000000000000
__sfx__
000100003613034130321302f1302a130231301c1300e130071300112001110055000250003400014000400004000040000100002200012000000000000000000000000000000000000000000000000000000000
000301002c3512a351273512435123351213511f651233511b3511d3511f65116351106511c6511335119351173510f6510f6510c65113641106410c3310763108631093210d6210c62103621053210332102311
0003000011430147500b4700e77007470097600745005340054300432002420016000160001600016000160001600016000000000000000000000000000000000000000000000000000000000000000000000000
000200003b33026320083100150001600097000240003500086000250004600016000160001600016000160001600016000000000000000000000000000000000000000000000000000000000000000000000000
00020000181201c64011550121500b5601a6600c0600c560186600b55005250095500e6500e650096500124008630086300763007620026200161000000000000000000000000000000000000000000000000000
000300000e53010530115300f5300c520075200451001510015000150001500055000250003400014000400004000040000100002200012000000000000000000000000000000000000000000000000000000000
000100003613034130321302f1302a130231301c1300e130071300112001110055000250003400014000400004000040000100002200012000000000000000000000000000000000000000000000000000000000
000400001b673204732166322453246531f453206431f4431b6431a44319443164431544313443114430e4430d4330c4330943307423054230241301413014130840305403044030440303403024030140300003
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e0000215722157221572235722357223572245722457224572265722657226572295722850228572265722857228572285722957229572295722b5722b5722b5722d5722d5722d57230572000002f5722d572
010e0000215522150221552235022355223502215522155224552265522650226552295522850228552265521c552285021c552295021d5521d5021c5521c5521f552215522150221552245521c5521f55221552
010e000015552155521555215552135522350221502215021855218552185521855210552175022850226502175521755217552175520e5521d5021c5021c5021555221502155522150215552155521555213552
010e000015572185721c572175721a5721d572185721c5721f57221572215722157221572215721f5721d5721c5721f572215721d57221572245721f572235722657228572285722857224572000002357221572
010e00001305313043130431304313050130431304313050130531305013050000002104321003210030000021053210432104321043210032104321043000002105321043000000000021043210432104300000
010e0000093320930209332093320b3320b30209332093320c332003020c3320c3321133210302103320e3320433204302043320433205332053020433204332073320933209302093320c332043320733209332
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800001035310353133531735319353193531b35318353173431434312343113330f3330e3230d3130b31309313073230632305323053230332302323043230332303323033130331303313033130231301313
0110000039054103042b4041730419304193041b30432054173041430412304274040f3040e3040d3040b304093043b054063040530405304033041e404043040330430054033040330403304033040230401304
011000003b0043b0542b4041730419304193041b3043200417304300041230427404300540e3040d3040b304093043b054063040530405304033041e404043040330430054033040330403304033040230401304
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010e0000215422154221502215022454221542215022150221542215422150221502265422154221502215022154221542215022150224542215422150221502215422154221502215021f5421c5421f54221542
010e0000217701d70021770187001f7701f770217702377021770187001f770187001f77021770237701d770217701870421770187001a7701c7701d7701d77021770187001f770187001c7701a7701d7701d770
010e00002105300003000030000321043210432104300003210530000300000000002104321043210430000021053000000000000000210432104321043000002105321043000000000021043210432104300000
010e00002d0422d0422d0422d0422d0422d0422d0422d0422d0422d0422d0422d042300422d0422d0422d04229042290422904229042290422904229042290422904229042290422904226042280422904229042
010e00002b0422b0422b0422b0422b0422b0422b0422b0422b0422b0422b0422b04228042290422b0422b0422c0422c0422c0422c0422c0422c0422c0422c0422c0422c0422c0422c042290422b0422c04228042
010e00001556215502155621556217502155621550215562155021556215502155621556215502155621550211562115021156211562115021156211502115621156211562115621150211562115621156211502
010e00001356215502135621356217502135621550213562155021356215502135621356215502135621550214562125021456214562145021456211502145621456214562145621456214562145621456211502
010e00002105300003210532105321003210432100321053210032105300000210532104321053210430000021053000002105321053210032104321043000002105321043210530000021043210432104321053
010e000015755187551c75515755187551c75515755187551c75515755187551c755217551f7551d7551c75515555185551c55515555185551c55515555185551c55515555185551c555215551f5551d5551c555
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000002155221552215522355223552235522155221552215522455224552245522155221552265522655221552215522155223552235522355221552215522155224552245522455221552215522855228552
011000001c5521c5521c5521d5521d5521d5521c5521c5521c5521f5521f5521f5521c5521c55221552215521c5521c5521c5521d5521d5521d5521c5521c5521c5521f5521f5521f5522455223552215521f552
011000002153121531215312153121531215312153121531215312453124531245312453124531245312453124531215312153121531215312153121531215312153128531285312853128531285312853128531
011000001c5311c5311c5311c5311c5311c5311c5311c5311c5311f5311f5311f5311f5311f5311f5311f5311f5311c5311c5311c5311c5311c5311c5311c5311c53121531215312153121531215312153121531
001000002d61227612216122d6121a61214612106120d6122d6120a61209612096122d61209612096120961239612346122f61239612236121e61219612146122d6120c6120b6120a6122d612096120961209612
0010000028612246121a612286120f6120d6120a612076122861206612046120461228612046120461204612346122e61225612346121961214612116120b6122861206612056120561228612056120561205612
001000002d62227622216222d6221a62214622106220d6222d6220a62209622096222d62209622096220962239622346222f62239622236221e62219622146222d6220c6220b6220a6222d622096220962209622
0010000028622246221a622286220f6220d6220a622076222862206622046220462228622046220462204622346222e62225622346221962214622116220b6222862206622056220562228622056220562205622
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
01 0a0d0e44
01 5e1f2021
00 5e1f2022
00 5e1f2021
00 5e1f2022
00 23254344
00 24254344
00 23202644
00 24202644
00 5e1f2021
00 5e1f2022
00 0b205f44
00 0b201f44
00 0f201f44
00 0f201f44
00 0c204f44
00 0f200c44
00 0f200b44
00 0f200b44
00 23254344
00 24254344
00 23202644
02 24202644
00 54424344
02 54564344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 282a2c44
00 282a2c44
00 292b2d44
02 292b2d44
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
01 14424344
00 14424344
00 14154344
00 14424344
02 14164344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

