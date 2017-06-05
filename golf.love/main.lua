function love.load()
	-- roll the bones
	math.randomseed( os.time() )

	love.graphics.setDefaultFilter("nearest", "nearest", 0)

	config = {ballSpeed = 7}

	screen = "hole"

	screenWidth = love.graphics.getWidth()
	screenHeight = love.graphics.getHeight()

	scale = love.window.getPixelScale( )
	trueScreenWidth = screenWidth * scale
	trueScreenHeight = screenHeight * scale

	hole_data = {}

	-- A note about game scale: Each tile is about 50 yards which is not how it works in real life but

	hole_data['name'] = "Turd"

	tiles = {}

	tiles[#tiles+1] = {name="rough"}
	tiles[#tiles+1] = {name="fairway"}
	tiles[#tiles+1] = {name="green"}
	tiles[#tiles+1] = {name="tee"}
	tiles[#tiles+1] = {name="trees"}
	tiles[#tiles+1] = {name="sand"}

	game_state = { current_tool = 1, camera = {x=1, y=1}, handedness = "right", mode = "make", swinging=false, club = 1, power=4}

	tree_tile = love.graphics.newImage("graphics/forest.png")

	map_h = 15 -- 600px, leaving 67 for top menu
	map_w = 8 -- 320px, leaving 55 for side menu
	if game_state['handedness'] == "right" then
		map_x_offset = 0
	else
		map_x_offset = 55
	end
	map_y_offset = 0
	tile_h = 40
	tile_w = 40

	debug_messages = {}
	add_debug_message("Debug initialized",5)

	strokes = {}
	clubs = {}
	balls = {}
	clubs[#clubs+1] = {name="driver", angle=9.0, length=1}
	clubs[#clubs+1] = {name="4 iron", angle=25.0, length=0.7}
	clubs[#clubs+1] = {name="wedge", angle=45.0, length=0.3}
	clubs[#clubs+1] = {name="putter", angle=0.0, length=0.2}

	set_up_map()
end

function love.draw()

	draw_map()
	draw_hazards()
	draw_balls()
	draw_hole()
	draw_ui()
	draw_debug_messages()
	draw_mouse()

end

function love.update(dt)
	if primary_mouse_down then
		if game_state.mode == "make" then
			place_tile(game_state.current_tool)
		end
	end

	for i,v in ipairs(balls) do
		if v.active == true then

			distance_x = math.abs(strokes[#strokes].x - v.x)
			distance_y = math.abs(strokes[#strokes].y - v.y)

			if strokes[#strokes].x < v.x then
				v.x = v.x + (v.dx * dt)
			end
			
			if strokes[#strokes].x > v.x then
				v.x = v.x - (v.dx * dt)
			end

			if strokes[#strokes].y < v.y then
				v.y = v.y - (v.dy * dt)
			end

			if strokes[#strokes].y > v.y then
				v.y = v.y + (v.dy * dt)
			end
		end
	end

	love.timer.sleep(dt/2)
end

function love.mousepressed(x, y, button, istouch)
	if screen == "hole" then
		if button == 1 then
			primary_mouse_down = true
		end
		if button == 2 then
			secondary_mouse_down = true
		end
	end
end

function love.mousereleased(x, y, button, istouch)
	if button == 1 then
		primary_mouse_down = false
		if game_state.mode == "play" then
			if game_state.swinging == false then
				start_stroke()
				end_stroke()
			end
		end
	end

	if button == 2 then
		secondary_mouse_down = false
	end
end

function love.keypressed(key)
	if game_state.mode == "make" then
		if key == "1" then
			game_state.current_tool = 1
		end

		if key == "2" then
			game_state.current_tool = 2
		end

		if key == "3" then
			game_state.current_tool = 3
		end

		if key == "4" then
			game_state.current_tool = 4
		end

		if key == "5" then
			game_state.current_tool = 5
		end

		if key == "6" then
			game_state.current_tool = 6
		end

		if key == "p" then
			if check_map_playability() == true then
				start_hole()
			end
		end
	end

	if game_state.mode == "play" then
		if key == "1" then
			game_state.club = 1
		end

		if key == "2" then
			game_state.club = 2
		end

		if key == "3" then
			game_state.club = 3
		end

		if key == "4" then
			game_state.club = 4
		end
	end
end

function start_stroke()
	game_state.swinging = true
end

function end_stroke()
	game_state.swinging = false

	local mouse_x, mouse_y = get_map_coordinates_from_mouse(love.mouse.getX(), love.mouse.getY())

	launch_ball(strokes[#strokes].x, strokes[#strokes].y, mouse_x, mouse_y)
end

function launch_ball(from_x, from_y, to_x, to_y)
	balls[1].active = true
	add_stroke(to_x, to_y, "stroke")
end

function draw_ui()
	r, g, b, a = love.graphics.getColor()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print("Current tool: " .. tiles[game_state.current_tool].name, 10, 610)
	love.graphics.print("Current club: " .. clubs[game_state.club].name, 10, 630)
	love.graphics.setColor(r, g, b, a)
end

function add_debug_message(text, age)
	debug_messages[#debug_messages+1] = {text = text, created = os.time(), age = age}
end

function check_map_playability()

	local has_tee = false
	local has_hole = false

    for x=1, map_w do
		for y=1, map_h do
			if map[x][y].type == 3 then
				has_hole = true
			end
			if map[x][y].type == 4 then
				has_tee = true
			end
		end
    end

    if has_hole == true and has_tee == true then
		add_debug_message("Hole is playable.",5)
		return true
    end

    add_debug_message("Hole is not playable.",5)
    return false
end

function set_up_map()

	map_uuid = uuid()

	time_of_day = 0

	--map_name = place_first_names[math.random(1,#place_first_names)] .. " " .. place_last_names[math.random(1,#place_last_names)]

    --print("Creating new map, " .. map_name)

    map={}
    hazards={}

    -- build out map
    print("Building map...")

    for x=1, map_w do
        map[x] = {}
        hazards[x] = {}
       for y=1, map_h do
          map[x][y] = {elevation=0, type = 1}
          hazards[x][y] = {type = 0}
       end
    end

    print("Map is " .. map_w .. " wide by " .. map_h .. " tall")

    print("Map built.")

end

function draw_map()
	r, g, b, a = love.graphics.getColor()
	for x=1, map_w do
        for y=1, map_h do

			--current_y_pos = ((y*tile_h)+map_y_offset)-tile_h
			--current_x_pos = ((x*tile_w)+map_x_offset)-tile_w

			screen_x, screen_y = calculate_screen_position_from_map_coordinates(x,y)

	        if map[x][y].type == 1 then
	            -- rough
	            love.graphics.setColor(58, 119, 91, 255)
	            love.graphics.rectangle( 'fill', screen_x, screen_y,  tile_w, tile_h)
	        elseif map[x][y].type == 2 then
	            -- fairway
	            love.graphics.setColor(67, 183, 89, 255)
	            love.graphics.rectangle( 'fill', screen_x, screen_y,  tile_w, tile_h)

	        elseif map[x][y].type == 3 then
	            -- green
	            love.graphics.setColor(67, 219, 95, 255)
	            love.graphics.rectangle( 'fill', screen_x, screen_y,  tile_w, tile_h)

	        elseif map[x][y].type == 4 then
	            -- tee
	            love.graphics.setColor(72, 97, 72, 255)
	            love.graphics.rectangle( 'fill', screen_x, screen_y,  tile_w, tile_h)
	        elseif map[x][y].type == 6 then
	            -- sand
	            love.graphics.setColor(234, 215, 121, 255)
	            love.graphics.rectangle( 'fill', screen_x, screen_y,  tile_w, tile_h)
	        end

	        love.graphics.setColor(r, g, b, a)
	        --love.graphics.print(map[x][y].type, screen_x, screen_y)
        end

    end

end

function draw_hazards()
	r, g, b, a = love.graphics.getColor()
	for x=1, map_w do
        for y=1, map_h do

			--current_y_pos = ((y*tile_h)+map_y_offset)-tile_h
			--current_x_pos = ((x*tile_w)+map_x_offset)-tile_w

			screen_x, screen_y = calculate_screen_position_from_map_coordinates(x,y)

	        if hazards[x][y].type == 5 then
	            -- tee
	            love.graphics.setColor(255, 255, 255, 255)
	            love.graphics.draw(tree_tile, screen_x,screen_y)
	        end

	        love.graphics.setColor(r, g, b, a)
	        --love.graphics.print(map[x][y].type, screen_x, screen_y)
        end

    end
end

function draw_balls()
	if game_state.mode == "play" then
		r, g, b, a = love.graphics.getColor()

		for i,v in ipairs(balls) do
			local x,y = calculate_screen_position_from_map_coordinates(v.x,v.y)

			--add_debug_message(x .. "," .. y,5)
			x = x+(tile_h/2)-(2*balls[1].height)
			y = y+(tile_w/2)-(2*balls[1].height)

			love.graphics.setColor(255, 255, 255, 255)
			love.graphics.rectangle( 'fill', x, y,  (4*balls[1].height), (4*balls[1].height))
			love.graphics.setColor(0, 0, 0, 255)
			love.graphics.rectangle( 'fill', x+((4*balls[1].height)), y,  1, 1)
			love.graphics.rectangle( 'fill', x+((4*balls[1].height)), y+((4*balls[1].height)),  1, 1)
			love.graphics.rectangle( 'fill', x, y+((4*balls[1].height)),  1, 1)
			love.graphics.setColor(r, g, b, a)
		end
	end
end


function draw_hole()

	local has_green = false

	for x=1, map_w do
		for y=1, map_h do
			if map[x][y].type == 3 then
				has_green = true
				hole_x = x
				hole_y = y
			end
		end
    end

	if has_green == true then
		local x,y = calculate_screen_position_from_map_coordinates(hole_x,hole_y)

		--add_debug_message(x .. "," .. y,5)
		x = x+(tile_h/2)
		y = y+(tile_w/2)

		love.graphics.setColor(0, 0, 0, 255)
		love.graphics.rectangle( 'fill', x, y,  3, 3)
		love.graphics.setColor(r, g, b, a)
	end
end

function place_tile(tile)

	mouse_x = love.mouse.getX()
	mouse_y = love.mouse.getY()

	map_tile_x, map_tile_y = get_map_coordinates_from_mouse(mouse_x, mouse_y)

	if map_tile_x >= 1 and map_tile_x <= map_w and map_tile_y >= 1 and map_tile_y <= map_h and map[map_tile_x][map_tile_y].type ~= tile and hazards[map_tile_x][map_tile_y].type ~= tile then

		if tile == 1 then
			map[map_tile_x][map_tile_y].type = tile
		end

		if tile == 2 then
			map[map_tile_x][map_tile_y].type = tile
		end

		if tile == 3 then
			map[map_tile_x][map_tile_y].type = tile
		end

		if tile == 4 then
			map[map_tile_x][map_tile_y].type = tile
		end

		if tile == 5 then
			hazards[map_tile_x][map_tile_y].type = tile
		end

		if tile == 6 then
			map[map_tile_x][map_tile_y].type = tile
		end

		add_debug_message("placing " .. tiles[tile].name .. " " .. map_tile_x .. "," .. map_tile_y, 5)
	end
end

function scale_numbers(subject, old_min, old_max, new_min, new_max)
	OldRange = (old_max - old_min)
	NewRange = (new_max - new_min)
	NewValue = (((subject - old_min) * NewRange) / OldRange) + new_min

	return NewValue
end

function draw_debug_messages()
	r, g, b, a = love.graphics.getColor()
	local msg_x = 20
	local msg_y = 20

	for i=1, #debug_messages do
		if debug_messages[i].created+debug_messages[i].age > os.time() then

			local alpha = (os.time() - debug_messages[i].created)
			alpha = scale_numbers(alpha, 0, debug_messages[i].age, 255, 0)

			love.graphics.setColor(255, 255, 255, alpha)
			love.graphics.print(i .. ": " .. debug_messages[i].text, msg_x, msg_y)
			msg_y = msg_y + 20
		end
	end

	love.graphics.setColor(r,g,b,a)
end

function start_hole()
	add_debug_message("Starting hole...", 5)
	strokes = {}

	-- Find the tee
	for x=1, map_w do
        for y=1, map_h do
			if map[x][y].type == 4 then
				start_x = x
				start_y = y
			end
        end
    end

    -- Find the green
    for x=1, map_w do
		for y=1, map_h do
			if map[x][y].type == 3 then
				hole_x = x
				hole_y = y
			end
        end
    end

    hole_data['hole_x'] = hole_x
    hole_data['hole_y'] = hole_y

    balls[#balls+1] = {height = 1, active = false, x=start_x,y=start_y,dx=config.ballSpeed * math.cos(clubs[game_state.club].angle),dy=config.ballSpeed * math.sin(clubs[game_state.club].angle)}
	add_stroke(start_x, start_y, "tee")
	game_state.mode = "play"

	add_debug_message("Started hole.", 5)
end

function add_stroke(x,y,reason)
	add_debug_message("Stroke: " .. x .. ", " .. y, 5)
	strokes[#strokes+1] = {x=x, y=y, type=reason}
end

function calculate_map_position_from_screen_coordinates(x,y)
	map_tile_x = math.floor((x)/tile_w)
	map_tile_y = math.floor((y)/tile_h)

	map_y = ((map_tile_y*tile_h))
    map_x = ((map_tile_x*tile_w))

	return map_x, map_y
end

function calculate_screen_position_from_map_coordinates(x,y)
	map_y = ((y*tile_h)+map_y_offset)-tile_h
    map_x = ((x*tile_w)+map_x_offset)-tile_w

    return map_x, map_y
end

function get_map_coordinates_from_mouse(x,y)
	map_tile_x = math.floor((x)/tile_w)+1
	map_tile_y = math.floor((y)/tile_h)+1

	return map_tile_x, map_tile_y
end

function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

function draw_mouse()
	mouse_x = love.mouse.getX()
	mouse_y = love.mouse.getY()

	love.graphics.setColor(255, 255, 255,100)

	mouse_map_x, mouse_map_y = calculate_map_position_from_screen_coordinates(mouse_x, mouse_y)

	if(game_state.mode == "make") then
		love.graphics.rectangle( 'fill', mouse_map_x, mouse_map_y,  tile_w, tile_h)
    end

    if(game_state.mode == "play") then

		local screen_x, screen_y = calculate_screen_position_from_map_coordinates(strokes[#strokes].x, strokes[#strokes].y)

		screen_x = screen_x+(tile_h/2)
		screen_y = screen_y+(tile_w/2)

		shot_potential = (game_state.power * clubs[game_state.club].length)

		xup_diff = screen_x + (shot_potential*tile_h)
		yup_diff = screen_y + (shot_potential*tile_w)

		xdown_diff = screen_x - (shot_potential*tile_h)
		ydown_diff = screen_y - (shot_potential*tile_w)

		if mouse_x > xup_diff then
			mouse_x = xup_diff
		end

		if mouse_x < xdown_diff then
			mouse_x = xdown_diff
		end

		if mouse_y > yup_diff then
			mouse_y = yup_diff
		end

		if mouse_y < ydown_diff then
			mouse_y = ydown_diff
		end

		love.graphics.line(screen_x, screen_y, mouse_x, mouse_y)
		love.graphics.circle("fill", mouse_x, mouse_y, 20, 12)
		love.graphics.rectangle( 'fill', mouse_map_x, mouse_map_y,  tile_w, tile_h)
    end
end