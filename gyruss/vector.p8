pico-8 cartridge // http://www.pico-8.com
version 8
__lua__
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- GAME STATES
state_start_screen = 0
state_game_loop = 1
state_game_over = 2
game_state = 0
crack_col1 = 6 crack_col2 = 7
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --  START MENU VARS
menuOrigin = {x=62, y=50, current_rotation = 0, rotation_speed = 0.001}
menu_time = 0

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- GAME VARS
currentcol = 1
exprate = 0.06 exprate_min = 0.06 exprate_max = 0.1 exprate_hit_penalty = 0.01 exprate_inc = 0.0002
game_time = 0
difficulty = 0

world = {rot=0, vel=0, acc=0.001, maxspeed = 5, f=0.99}
totallanes = 10 lane_subdivisions=2 lanediv = 0 max_object_radius = 10
obstimer = 0 obstimer_max = 10 obstimer_min = 1
-- obstacle types
type_normal = 8 type_shootable = 11
loops = {} totalloops = 5 loopsspawned = 1
origin = {x=62, y=62, rinc = 0.01, rcountcurrent=0, f=0.99}
maxloopsize = 200 loopstagger = 15 staggertimer = 0

min_player_acceleration = 0.006 max_player_acceleration = 0.02 
min_player_friction = 0.75 max_player_friction = 0.56

player_hit = false
player = {lives_left = 3, angle=0, vel=0, current_radius=6, normal_radius = 6, col = 9, width = 0.03, height=1.0, lane = 0, bullets=1, can_fire=true, hit_box = 3, hit_safe_time = 30, current_safe_timer = 0, can_be_hit = true, anim_in_duration = 60}
btnleft = false btnright = false btnup = false btndown = false btnone = false btntwo = false
bullets = {} bulletrate = 0.075 bullet_height = 0.5 bullet_colour = 12 
hit_combo = 0
obstacles = {}
blasts = {} minimum_blast_particles = 10
waves = {} wavecounter = 0 currentwave = {} constant_wall_spacing = 10
score = 0
damage = {}

button_cooldown_duration = 30 current_button_cooldown = 0 button_cooldown_fraction = 0
recieve_input = false
menu_transition_duration = 30
current_menu_transition_time = 0

dbug_msg1 = "" dbug_msg2 = "" dbug_msg3 = "" dbug_msg4 = "" dbug_msg5 = "" dbug_msg6 = ""

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- WAVE CONFIGURATIONS
lanediv = 1/totallanes
spirals = {}
SPIRAL_REGULAR = {increment = lanediv, spacing = 5, width = lanediv, shootable = true}
SPIRAL_BULLET_HELL = {increment = -0.2+(lanediv/4), spacing = 5, width = lanediv/4, shootable = false}
SPIRAL_TIGHT = {increment = lanediv/4, spacing = 3, width = lanediv/4, shootable = false}
SPIRAL_GATE = {increment = lanediv, spacing = 0, width = lanediv, shootable = true}

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- init
function _init()

	reset_game()
	setup_wave_configurations()
	change_state(state_start_screen)
end
function setup_wave_configurations()
	
	-- SPIRAL TYPES
	add(spirals, SPIRAL_REGULAR)
	add(spirals, SPIRAL_TIGHT)
	add(spirals, SPIRAL_BULLET_HELL)
end

function reset_button_cooldown()
	current_button_cooldown = 0
end
function update_button_cooldown()
	recieve_input = (current_button_cooldown>= button_cooldown_duration)
	if(recieve_input == false)then
		current_button_cooldown += 1
		button_cooldown_fraction = (current_button_cooldown/button_cooldown_duration)
	end

	dbug_msg5 = current_button_cooldown
end

function game_reset_loops()
	for i=1,totalloops do
		loops[i] = 0
	end
	loops[1] = 1
end

function change_state(_new_state)
	game_state = _new_state
	if(game_state == state_start_screen)then
		reset_start_menu()
	end
	if(game_state == state_game_loop)then
		reset_game()
	end
	if(game_state == state_game_over)then
		reset_start_menu()
	end
end
function reset_start_menu()
	world.rot = 0
	world.vel = 0.005
	origin.y = menuOrigin.y
	menu_time = 0
	current_menu_transition_time = menu_transition_duration
	reset_button_cooldown()
end

function reset_game()
currentcol = 1
exprate = 0.06 exprate_min = 0.06 exprate_max = 0.12 exprate_hit_penalty = 0.01 exprate_inc = 0.0001
game_time = 0
difficulty = 0

world = {rot=0, vel=0, acc=0.001, maxspeed = 5, f=0.99}
obstimer = 0 obstimer_max = 10 obstimer_min = 1
-- obstacle types
type_normal = 8 type_shootable = 11
loops = {} totalloops = 5 loopsspawned = 1
origin = {x=62, y=62, r=10, rinc = 0.01, rcountcurrent=0, f=0.99}
maxloopsize = 200 loopstagger = 15 staggertimer = 0
player = {lives_left = 3, angle=0, vel=0, acc=0.006, f = 0.8, current_radius=6, normal_radius = 6, col = 9, width = 0.03, height=1.0, lane = 0, bullets=1, can_fire=true, hit_box = 3, hit_safe_time = 30, current_safe_timer = 0, can_be_hit = true, anim_in_duration = 60}
btnleft = false btnright = false btnup = false btndown = false btnone = false btntwo = false
bullets = {} bulletrate = 0.075 bullet_height = 0.5 bullet_colour = 12 
hit_combo = 0
obstacles = {}
blasts = {} minimum_blast_particles = 10
waves = {} wavecounter = 0 currentwave = {} constant_wall_spacing = 10
score = 0
lanediv = 1/totallanes
game_reset_loops()
reset_damage()

-- set player rotation to bottom
player.angle = (7*lanediv) + ((lanediv*0.5)-player.width*0.5)



add_next_wave()

	-- set starting wave
	currentwave = waves[1]

end
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- update
function _update()

	btnleft = btn(0)
	btnright = btn(1)
	btnup = btn(2)
	btndown = btn(3)
	btnone = btn(4)
	btntwo = btn(5)

	if(game_state == state_start_screen)then
		update_start_screen_state()
	end

	if(game_state == state_game_loop)then
		update_game_state()
	end

	if(game_state == state_game_over)then
		update_game_over_state()
	end
end

function update_start_screen_state()
	start_screen_update_inputs()
	world.rot += world.vel
	menu_time +=1

	update_button_cooldown()
end

function start_screen_update_inputs()
	if(btnone or btntwo and recieve_input)then
		reset_game()
		change_state(state_game_loop)
	end
end

function update_game_over_state()
	start_screen_update_inputs()
	world.rot += world.vel
	menu_time +=1
end

function game_over_update_inputs()
	if(btnone or btntwo and recieve_input)then
		reset_game()
		change_state(state_game_loop)
	end
end

function update_game_state()
if(player.lives_left>1)then cls() end

	game_update_inputs()

	game_update_world()

	game_update_wave()

	game_update_obstacles()

	game_update_bullets()

	game_update_player()

	game_update_blasts()

	game_update_loops()

	game_update_score()

end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- update methods
function game_update_loops()
	--spawn loops
	if(loopsspawned<totalloops) then
		staggertimer+=1
		if(staggertimer==loopstagger) then
			loopsspawned+=1
			loops[loopsspawned]=1
			staggertimer=0
		end
	end

	for i=1,loopsspawned do 
		l = loops[i]
		l += (l*exprate)
		if(l>maxloopsize)then l=1 end
		loops[i] = l
	end
end

function game_update_world()

	--update world
	world.vel *= world.f
	world.vel += rnd(world.acc) - (world.acc/2)
	world.rot += world.vel
	--update origin
	origin.rcountcurrent += origin.rinc
	origin.x=64+cos(origin.rcountcurrent)*origin.r
	origin.y=64+sin(origin.rcountcurrent)*origin.r

	-- speed and difficulty
	if(exprate <= exprate_max and game_time % 2 ==0)then
		exprate += exprate_inc
	end

	difficulty = (exprate-exprate_min)/(exprate_max - exprate_min)

	game_time +=1
end

function game_update_inputs()

	-- player left / right
	if(btnleft)	then player.vel -= player.acc end
	if(btnright)then player.vel += player.acc end

	if(btndown)then reset_game() end

	-- shoot
	if(btnone or btntwo)then
		if(game_time>15 and recieve_input)then fire_bullet(player.angle) end
	end
end

function game_update_blasts()
	for b in all(blasts)do

		for p in all(b.blast_particles) do
			p.angle = (p.angle + p.speedx) % 1.0
			p.radius += p.speedy
			p.speedx *= p.friction
			p.speedy *= p.friction
			p.speedy += 0.01
		end

		b.time_left -= 1

		if(b.time_left <=0)then 
			remove_blast(b) 
		end
	end
end

function game_update_wave()

	if(currentwave!=nil)then

		-- add wall if wave has a constant
		if(wavecounter % constant_wall_spacing ==0)then
			for constangle in all(currentwave.constants)do
				create_obstacle(constangle*lanediv, 0, lanediv, 0)
			end
		end

		-- trigger obstacles for this count
		for item in all(currentwave.list) do
			if(item.time == wavecounter)then
				create_obstacle(item.angle, item.type, item.width, 0)
				del(currentwave.list, item)
			end
		end

		-- update counter, change waves if needs be
		wavecounter += 1

		if(wavecounter > currentwave.duration)then
			del(waves, currentwave)
			add_next_wave()
			start_next_wave()
		end		
	end
end
function add_next_wave()
	add_spacer_wave(15)

	waveSeed = flr(rnd(3))
	include_shootable = false

	-- RANDOM
	if(waveSeed == 0)then
		--_spacing_min, _spacing_max, _length, _constants, _hasshootable
		if(rnd()>0.25)then include_shootable = true end
		add_random_wave(2,20, 2 + flr(rnd(8)), {}, include_shootable)
	end

	-- SPIRAL
	if(waveSeed == 1)then

		spiral_seed = flr(rnd(3))

		if(spiral_seed==0)then
			add_spiral_wave(SPIRAL_REGULAR, 5+flr(rnd(20)))
		end

		if(spiral_seed==1)then
			add_spiral_wave(SPIRAL_TIGHT, 5+flr(rnd(20)))
		end

		if(spiral_seed==2)then
			add_spiral_wave(SPIRAL_BULLET_HELL, 10 + flr(rnd(10)))
		end
	end

	-- GATE
	if(waveSeed == 2)then
		shootable = true
		add_slalom_wave(1 + flr(rnd(1)))
	end
end
function start_next_wave()
	currentwave = waves[1]
	wavecounter = 0
end

function game_update_obstacles()
	for obs in all(obstacles) do
		obs.value += (exprate*obs.value)

		if(obs.value > max_object_radius)then 
			remove_obstacle(obs) 
		else
			check_player_collision(obs.angle, obs.width, obs.value)
		end
	end
end

function game_update_bullets()
	for b in all(bullets)do
		
		b.value -= (b.value*exprate)
		
		if(b.value <0.01)then
			remove_bullet(b)
			hit_combo = 0
		else
			for o in all(obstacles)do
				if(check_collision(b.angle, b.width, b.value, o.angle, o.width, o.value, bullet_height))then
					remove_bullet(b)
					if(o.type == type_shootable)then 
						remove_obstacle(o) 
						create_blast(b.angle, o.value, -0.025, -0.3, type_shootable, 40)
						hit_combo += 1
					else
						create_blast(b.angle, o.value, -0.025, 0.1, type_normal,10)
						create_blast(b.angle, o.value, -0.0045, -0.2, bullet_colour,10)
						hit_combo = 0
					end

					break
				end
			end
		end
	end
end

function game_update_player()
	player.vel *= get_difficulty_adjusted_value(min_player_friction, max_player_friction)
	player.angle += player.vel
	player.angle = player.angle % 1.0
	player.lane = get_lane(player.angle)
	player.acc = get_difficulty_adjusted_value(min_player_acceleration, max_player_acceleration)

	update_button_cooldown()

	-- hit logic
	if(player.current_safe_timer <= 0)then 
		player.can_be_hit = true
	else
		player.can_be_hit = false
		player.current_safe_timer -= 1
	end
end

function game_update_score()
	score += (exprate * (hit_combo+1))
end

function get_difficulty_adjusted_value(_min_value, _max_value)
	if(_max_value > _min_value)then
		range = _max_value - _min_value
		return _min_value + (range*difficulty)
	else
		range = _min_value - _max_value
		return _min_value - (range*difficulty)
	end
end

function is_in_range(n,target, range)
	return (n > target-range and n < target + range)
end
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- lane / obstacle methods
function add_attack_wave(_constants, _list, _length, _hasshootable)
	d = 0

	shootable = -1
	if(_hasshootable)then 
		shootable = flr(1+rnd(_length-1)) 
	end

	for i in all(_list)do
		if(i.time > d)then d = i.time end
		if(i.index == shootable)then 
			i.type = type_shootable 
		end
	end
	add(waves, {constants = _constants, duration = d+15, list = _list})
end
function add_spacer_wave(_duration)
	add(waves, {constants = {}, duration = _duration, list = {}})
end

function add_wave_item( _index, _time, _type, _angle, _width)
	return {index = _index, time = _time, type=_type, angle=_angle, width = _width}
end
function add_spiral_wave(_config, _length)
	list = {}
	for i=1, _length do
		add(list, add_wave_item(i, i * _config.spacing, type_normal, (i*_config.increment)%1.0, _config.width) )
	end
	add_attack_wave({}, list, _length, _config.shootable)
end

function add_random_wave(_spacing_min, _spacing_max, _length, _constants, _hasshootable)
	list = {}
	time = 0
	count = 0

	while(count <= _length) do

		a = get_free_lane(_constants)
		rnd_width = lanediv * (0.25+(rnd()*0.75))
		add(list, add_wave_item(count, time, type_normal, a*lanediv, rnd_width))
		time += (_spacing_min + flr(rnd(_spacing_max - _spacing_min )))
		count += 1
	end
	add_attack_wave(_constants, list, _length, _hasshootable)
end

function add_slalom_wave(_gates)
	for i=1,_gates do
		add_spiral_wave(SPIRAL_GATE, 10)
 		add_spacer_wave(60)
	end
end

function create_obstacle(a, obstacle_type, _width, _speed)
	add(obstacles, {value=0.01, type=obstacle_type, lane = lane_number, angle = a, width=_width})
end

function remove_obstacle(obs)
	del(obstacles, obs)
end

function create_damage()
	-- iterations = 2+flr(rnd(5))
	iterations = 1+flr(rnd(3))
	for i=1,iterations do
		
	crack_x = rnd(128)
	crack_y = rnd(128)
	num_tendrils = 4+flr(rnd(10))
	tendrils = {}

	-- damage > tendrils > points

	for i=1,num_tendrils do
		temp_tendril = {}
		px = crack_x
		py = crack_y
		rnd_tendril_length = 2+flr(rnd(2))
		rnd_angle = rnd()
		for j=1,rnd_tendril_length do
			rnd_radius = 5 + rnd(20)
			add(temp_tendril, {x=px, y=py})
			px = (px + ( rnd_radius * cos(rnd_angle) ) )
			py = (py + ( rnd_radius * sin(rnd_angle) ) )
			

			-- increment angle
			rnd_angle += (rnd(0.1)-0.05)
		end
		add(tendrils, temp_tendril)
	end

		crack_col = crack_col1
		if(rnd()>0.5)then crack_col = crack_col2 end
		add(damage, {tendrils=tendrils, colour = crack_col, life = 90})
	end
end

function remove_damage(d)
	del(damage, d)
end

function reset_damage()
	damage = {}
end

function get_lane(a)
	return abs(flr(a*totallanes)%totallanes)+1
end

function get_free_lane(_constants)
	a = flr(rnd(totallanes))
	return a
end

function get_lanes_touched(a, w)
	result = {}
	add(result, get_lane(a))
	if((a%lanediv)+w >= lanediv)then add(result, get_lane(a+w)) end
	return result
end

function get_lane_angle(lanenum)
	return lanenum * lanediv
end

function is_same_lane(a,b)
	return(get_lane(a) == get_lane(b))
end

-- check angle, width and radius (ydepth) to see if player ship is hit
function check_player_collision(a,w,r)
	player_hit = false
	if(player.can_be_hit)then
		player_hit = check_collision(player.angle,player.width,player.current_radius,a,w,r, player.height)
	end
	if(player_hit==true)then
		--_angle, _radius, _speedx, _speedy, _col, _scale
		create_blast(player.angle, player.current_radius, 0.0045, 0.3, player.col, 10)
		create_damage()

		rectfill(0,0,128,128, type_normal)

		player.current_safe_timer = player.hit_safe_time;
		player.can_be_hit = false
		hit_combo = 0
		player.lives_left -= 1
		exprate -= exprate_hit_penalty

		if(player.lives_left <=0 )then
			change_state(state_game_over)
		end
	end
end

function check_collision(a_angle, a_width, a_radius, b_angle, b_width, b_radius, hit_box)
	
	-- - - - - object a
	a_min = a_angle
	a_max = a_angle + a_width
	if(a_max > 1.0)then
		a_min -= 1
		a_max -= 1
	end

	-- - - - - object b
	b_min = b_angle
	b_max = b_angle + b_width
	if(b_max > 1.0)then
		b_min -= 1
		b_max -= 1
	end

	edge_min = min(a_max, b_max)
	edge_max = max(a_min, b_min)
	contact_angle = ((edge_min - edge_max) > 0)
	contact_depth = is_in_range(a_radius, b_radius, hit_box)
	return (contact_angle and contact_depth)
end



-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- bullet methods
function fire_bullet(a)
	if(player.can_fire)then
		add(bullets, {angle=a, width=player.width, value=player.current_radius, lanes=get_lanes_touched(a,player.width)})
		player.can_fire = false
		reset_button_cooldown()
		create_blast(player.angle, player.current_radius-player.height, -0.025, -0.4, bullet_colour, 20)
	end
end


function remove_bullet(b)
	player.can_fire = true
	del(bullets,b)
end

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- blast methods
function create_blast(_angle, _radius, _speedx, _speedy, _col, _scale)
	temp_particles = {}
	range = _scale - minimum_blast_particles
	totalparticles = minimum_blast_particles + flr(rnd(range))
	for i=1,totalparticles do
		p = {angle = _angle, radius = _radius, speedx = (rnd(2)-1) * _speedx, speedy = (_speedy * 0.2) + (rnd() * (_speedy*0.8)), friction = (0.7+rnd()*0.29) }
		add(temp_particles, p)
	end
	new_blast = {colour = _col, angle = _angle, radius = _radius, time_left = 45, blast_particles = temp_particles}
	add(blasts, new_blast)
end
function remove_blast(b)
	del(blasts, b)
end

-- -- -- -- -- -- -- -- -- -- -- draw
function _draw()
	
if(game_state == state_start_screen)then
		draw_start_menu_state()
	end

	if(game_state == state_game_loop)then
		draw_game_state()
	end

	if(game_state == state_game_over)then
		draw_game_over_state()
	end

			
end

function draw_start_menu_state()
	cls()

	circ(origin.x, origin.y, 50, currentcol)
	sm_radius = 5
	draw_lanes(sm_radius)

	-- DRAW TEXT - LOOP - HOLE - 
	halfX = lanediv*0.75
	halfY = sm_radius * 0.5
	osc = 0
	osc_inc = 4


	-- L = 0
	scale = get_letter_oscillation(osc)
	a = 0
	line_y(halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour())
	line_x(halfX - (halfX*scale), halfX*scale, halfY +(halfY*scale),get_random_colour())
	-- O = 1
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*1
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_y(a + halfX, halfY, -halfY*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +(halfY*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --top
	-- O = 2
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*2
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_y(a + halfX, halfY, -halfY*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +(halfY*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --btm
	-- P = 3
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*3
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_y(a + halfX, halfY, -(halfY*0.5)*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY*0.5)*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --btm
	-- dash = 4
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*4
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY+(halfY*0.5)*scale ,get_random_colour()) --btm
	-- H = 5
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*5
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_y(a + halfX, halfY, -halfY*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY+(halfY*0.5)*scale ,get_random_colour()) --btm
	-- O = 6
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*6
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_y(a + halfX, halfY, -halfY*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +(halfY*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --btm
	-- L = 7
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*7
	line_y(a+halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour())
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +(halfY*scale),get_random_colour())
	-- E = 8
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*8
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY*0.5)*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --mid
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY)*scale) ,get_random_colour()) --btm
	-- dash = 9
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*9
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY+(halfY*0.5)*scale ,get_random_colour()) --btm




	print("press z/x to begin", 30,110,12)
end

function draw_game_over_state()
	cls()

	circ(origin.x, origin.y, 50, currentcol)
	sm_radius = 5
	draw_lanes(sm_radius)

	-- DRAW TEXT - GAME - OVER - 
	halfX = lanediv*0.75
	halfY = sm_radius * 0.5
	osc = 0
	osc_inc = 4


	-- G = 0
	scale = get_letter_oscillation(osc)
	a = 0
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_y(a + halfX, halfY+(halfY*0.5)*scale, -(halfY*0.5)*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --top
	line_x(a+halfX - ((halfX*0.25)*scale), (halfX*0.25)*scale, halfY +((halfY*0.5)*scale),get_random_colour()) --mid
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY)*scale) ,get_random_colour()) --btm
	
	-- A = 1
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*1

	-- leftX = a + ((halfX*0.5)*scale)
	leftX = a + (halfX - (halfX*scale))
	midX = a + (halfX - (halfX*0.5)*scale)
	rightX = a + halfX
	topY = halfY
	btmY = halfY+(halfY*scale)

	line_connect_points(leftX, btmY, midX, topY, get_random_colour()) -- left
	line_connect_points(midX, topY, rightX, btmY, get_random_colour()) -- right
	line_x(a+halfX - ((halfX*0.75)*scale) , (halfX*0.5)*scale, halfY+((halfY*0.5) * scale), get_random_colour())

	-- M = 2
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*2

	-- M Layout
	leftX = a + (halfX - (halfX*scale))
	peak_one_x = a + (halfX - (halfX*0.75)*scale)
	midX = a + (halfX - (halfX*0.5)*scale)
	peak_two_x = a + (halfX - (halfX*0.25)*scale)
	rightX = a + halfX
	topY = halfY
	btmY = halfY+(halfY*scale)

	line_connect_points(leftX, btmY, peak_one_x, topY, get_random_colour())
	line_connect_points(peak_one_x, topY, midX, btmY, get_random_colour())
	line_connect_points(midX, btmY, peak_two_x, topY, get_random_colour())
	line_connect_points(peak_two_x, topY, rightX, btmY, get_random_colour())
	
	-- E = 3
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*3
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY*0.5)*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --mid
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY)*scale) ,get_random_colour()) --btm

	-- dash = 4
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*4
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY+(halfY*0.5)*scale ,get_random_colour()) --btm

	-- O = 5
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*5
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_y(a + halfX, halfY, -halfY*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +(halfY*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --btm

	-- V = 6
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*6

	-- v layout
	leftX = a + (halfX - (halfX*scale))
	midX = a + (halfX - (halfX*0.5)*scale)
	rightX = a + halfX
	topY = halfY
	btmY = halfY+(halfY*scale)

	line_connect_points(leftX, topY, midX, btmY, get_random_colour()) -- left
	line_connect_points(midX, btmY, rightX, topY, get_random_colour()) -- right
	
	-- E = 7
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*7
	line_y(a + halfX - (halfX*scale), halfY, -halfY*scale, get_random_colour()) -- left
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY*0.5)*scale),get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY ,get_random_colour()) --mid
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY +((halfY)*scale) ,get_random_colour()) --btm

	-- R = 8
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*8

	-- r layout
	leftX = a + (halfX - (halfX*scale))
	rightX = a + halfX
	topY = halfY
	midY = halfY +((halfY*0.5)*scale)
	btmY = halfY+(halfY*scale)

	line_y(leftX, 	halfY, -halfY*scale, get_random_colour()) -- left
	line_y(rightX, 	midY, (halfY*0.5)*scale, get_random_colour()) -- right
	line_x(a+halfX - (halfX*scale), halfX*scale, midY,get_random_colour()) --btm
	line_x(a+halfX - (halfX*scale), halfX*scale, topY,get_random_colour()) --btm
	line_connect_points(leftX, midY, rightX, btmY, get_random_colour())

	
	-- dash = 9
	osc += osc_inc
	scale = get_letter_oscillation(osc)
	a = lanediv*9
	line_x(a+halfX - (halfX*scale), halfX*scale, halfY+(halfY*0.5)*scale ,get_random_colour()) --btm


	print("Score: ", 30,108,type_shootable)
	print(flr(score), 54,108,get_random_colour())
	print("press z/x to retry", 30,120,12)
end
function get_letter_oscillation(_offset)
	return get_oscillation(menu_time, 0.03, _offset, 0.5, 1)
end
function get_oscillation(_seed, _factor, _offset, _min, _max)
	range = _max - _min
	return _min + (cos( (_seed+_offset)*_factor ))* (range/2)
end

function get_random_colour()
	return flr(rnd(16))
end
function draw_game_state()
	game_draw_loops()
	
	-- pip lines intro
	if(game_time < 80)then
		draw_lanes( loops[1] *(exprate*1.5) )
	else
		draw_lanes(maxloopsize)
	end

	game_draw_obstacles()

	game_draw_bullets()

	game_draw_blasts()

	game_draw_player()

	game_draw_damage()

	game_draw_hud()
end

-- -- -- -- -- -- -- -- -- -- -- draw methods
function game_draw_loops()
	for i=1,loopsspawned do
		circ(origin.x, origin.y, loops[i], currentcol)
	end
end
function draw_lanes(_size)
	if(player.lives_left>1)then
		for i=0,totallanes do

			line_y(i * lanediv, _size, _size, currentcol)
		end
	else
		-- change lane colour
		if(game_time % 100 == 0 and game_state == state_game_loop)then  
			if(currentcol == 1)then
				currentcol =0
			else
				currentcol = 1
			end
		end

		for i=0,totallanes*4 do
			line_y(i * lanediv/4, _size, _size, currentcol)
		end
	end
end
function game_draw_obstacles()
	for obs in all(obstacles) do
		line_x( obs.angle, obs.width, (obs.value), obs.type)
		line_connect_points(obs.angle, obs.value, obs.angle + obs.width/2, obs.value*0.8, obs.type)
		line_connect_points(obs.angle + obs.width/2, obs.value*0.8, obs.angle+obs.width, obs.value, obs.type)
	end
end
function game_draw_bullets()
	for b in all(bullets)do
		line_x(b.angle, b.width, b.value, bullet_colour)
		-- trail
		line_x(b.angle, b.width*0.9, b.value*1.1, bullet_colour)
		line_x(b.angle, b.width*0.7, b.value*1.2, bullet_colour)
		line_x(b.angle, b.width*0.5, b.value*1.3, bullet_colour)
		line_x(b.angle, b.width*0.3, b.value*1.4, bullet_colour)
	end
end

function game_draw_blasts()
	for b in all(blasts)do

		time_left = b.time_left

		for p in all(b.blast_particles)do
			
			if(rnd(time_left)>10)then
				line_y(p.angle, p.radius, 0.01, b.colour)
			end
		end
	end
end

function game_draw_player()
	-- start animation
	if(game_time<player.anim_in_duration)then
		player.current_radius = (player.normal_radius+3) - ((game_time/player.anim_in_duration)*3.0)
	end

	if(player.current_safe_timer % 2 == 0)then

		half_width = player.width *0.5
		half_height = player.height *0.5

		player_centerX = player.angle + (player.width*0.5)
		player_centerY = player.current_radius - (player.height*0.5)

		scale = 0.3 + cos(game_time*0.05)*0.15

		-- new player design

		line_x(player.angle, player.width, 	player.current_radius-player.height, player.col) --top
		line_x(player.angle, player.width, 	player.current_radius, player.col)--btm
		line_y(player.angle, player.current_radius, player.height, player.col)--left
		line_y(player.angle+ player.width, 	player.current_radius, player.height, player.col)--right

-- update scale to reflect bullet cooldown fraction
scale *= button_cooldown_fraction
		
			-- energy core
			line_x(player_centerX - (half_width*scale), player.width*scale, player_centerY + (half_height*scale), bullet_colour)
			-- left edge
			line_connect_points(
				player_centerX - (half_width*scale),
				player_centerY + (half_height*scale),
				player_centerX,
				player_centerY- (half_height*scale),
				bullet_colour
				)
			-- right edge
			line_connect_points(
				player_centerX + (half_width*scale),
				player_centerY + (half_height*scale),
				player_centerX,
				player_centerY- (half_height*scale),
				bullet_colour
				)
		
	end
end

function game_draw_damage()
	
	for d in all(damage)do
		
		total_tendrils = tablelength(d.tendrils)
dbug_msg6 = d.life
		if(d.life >= 60 or d.life % 2 ==0)then

			for i=1,total_tendrils do

				temp_tendril = d.tendrils[i]
				total_tendril_points = tablelength(temp_tendril)

				for j=2,total_tendril_points do
					a = temp_tendril[j-1]
					b = temp_tendril[j]
					line(a.x, a.y, b.x, b.y, d.colour)
					-- line(a.x, a.y, b.x, b.y, get_random_colour())
				end
			end
		end
		d.life -=1
		if(d.life <= 0)then remove_damage(d) end
	end
end

function game_draw_hud()
	print("score: " .. flr(score), 0,2, player.col)
	print("combo: " .. hit_combo,0,10,type_shootable)
	

	for i=1,player.lives_left do
		offsety = i*5
		rectfill(128,128-offsety,120,125-offsety,player.col)
	end
end

--draw horizontal line
function line_x(a, w, y, col) -- angle(xpos), width, ypos, linecolour
	a+=world.rot
	y*= max_object_radius
line(		origin.x + (y*cos(a)),
			origin.y + (y*sin(a)),
			origin.x + (y*cos(a+w)),
			origin.y + (y*sin(a+w)),
			col)
end
--draw vertical line
function line_y(a, y, h, col) -- angle(xpos), ypos, height, linecolour
	a+=world.rot
	y*=max_object_radius
	h*=max_object_radius
line(		origin.x + (y*cos(a)),
			origin.y + (y*sin(a)),
			origin.x + ((y-h)*cos(a)),
			origin.y + ((y-h)*sin(a)),
			col)
end

function line_connect_points(a1, y1, a2, y2, col)
	a1 += world.rot
	a2 += world.rot

	y1 *= max_object_radius
	y2 *= max_object_radius

	line(
		origin.x + (y1 * cos(a1)),
		origin.y + (y1 * sin(a1)),
		origin.x + (y2 * cos(a2)),
		origin.y + (y2 * sin(a2))
		)
end

function tablelength(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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

