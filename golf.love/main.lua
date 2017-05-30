function love.load()
	-- roll the bones
	math.randomseed( os.time() )

	love.graphics.setDefaultFilter("nearest", "nearest", 0)

	screen = "hole"

	screenWidth = love.graphics.getWidth()
	screenHeight = love.graphics.getHeight()

	scale = love.window.getPixelScale( )
	trueScreenWidth = screenWidth * scale
	trueScreenHeight = screenHeight * scale

	hole_data = {}

	hole_data['name'] = "Turd"

	tiles = {}

	tiles[#tiles+1] = {name="rough"}
	tiles[#tiles+1] = {name="fairway"}
	tiles[#tiles+1] = {name="green"}
	tiles[#tiles+1] = {name="tee"}
	tiles[#tiles+1] = {name="trees"}
	tiles[#tiles+1] = {name="sand"}

	game_state = { current_tool = 1, camera = {x=1, y=1}, handedness = "right"}

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


	set_up_map()

end

function love.draw()

	draw_map()
	draw_hazards()
	draw_ball()
	draw_debug_messages()
	draw_mouse()

end

function love.update(dt)
	if primary_mouse_down then
		place_tile(game_state.current_tool)
	end
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
	end

	if button == 2 then
		secondary_mouse_down = false
	end
end

function love.keypressed(key)
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
		check_map_playability()
	end
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
          hazards[x][y] = {type = 1}
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
	            love.graphics.setColor(255, 255, 255, 255)
	            love.graphics.rectangle( 'fill', screen_x, screen_y,  tile_w, tile_h)
	        elseif map[x][y].type == 6 then
	            -- tee
	            love.graphics.setColor(234, 215, 121, 255)
	            love.graphics.rectangle( 'fill', screen_x, screen_y,  tile_w, tile_h)
	        end

	        love.graphics.setColor(r, g, b, a)
	        --love.graphics.print(map[x][y].type, screen_x, screen_y)
        end

    end

end

function draw_ball()

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

function draw_camera()

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
	strokes = {}

	for x=1, map_w do
        for y=1, map_h do
        	if map[x][y].type == 4 then
        		start_x = get_map_coordinates_from_mouse
        	end
        end
    end

	strokes[#strokes+1] = {0, 0, 0, 0, type = "tee"}
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

    love.graphics.rectangle( 'fill', mouse_map_x, mouse_map_y,  tile_w, tile_h)
end