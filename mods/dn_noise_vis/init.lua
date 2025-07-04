local worldpath = minetest.get_worldpath()

local get_value_noise = core.get_value_noise or core.get_perlin

local map_textures_path = worldpath .. "/noisemaps/"
minetest.mkdir(map_textures_path)

noise_vis = {
  last_image = {}
}


local dnp = {
  offset = 0.5,
  scale = 0.25,
  spread = {x = 10, y = 10, z = 10},
  seed = 47,
  octaves = 8,
  persistence = 0.6,
  lacunarity = 2.0,
  flags = "",
}


dofile(core.get_modpath("dn_noise_vis").."/util.lua")

local only_interface = minetest.settings:get_bool("only_interface", true)


function noise_vis.create_map(pos1, pos2, name, callback, noiseparams, whites, blacks, mapname)
  if whites and blacks then
    whites, blacks = tonumber(string.sub(whites, 5, -1)), tonumber(string.sub(blacks, 5, -1))
  else
    whites, blacks = 0, 255
  end
  pos1, pos2 = vector.round(pos1), vector.round(pos2)

	local minp = pos1
	local maxp = vector.new(pos2.x, pos1.y, pos2.z) -- single slice
  local res = vector.new(pos2.x-pos1.x,0,pos2.z-pos1.z)
  local ppos
  local player = core.get_player_by_name(name)
  if player then
    ppos = vector.round(player:get_pos())
  end

  local noisemap = get_value_noise({
    offset = noiseparams.offset or dnp.offset,
    scale = noiseparams.scale or dnp.scale,
    spread = noiseparams.spread or dnp.spread,
    seed = noiseparams.seed or dnp.seed,
    octaves = noiseparams.octaves or dnp.octaves,
    persistence = noiseparams.persistence or dnp.persistence,
    lacunarity = noiseparams.lacunarity or dnp.lacunarity,
    flags = noiseparams.flags or dnp.flags,
  })
  
  local lscale, loffset = noiseparams.scale or dnp.scale, noiseparams.offset or dnp.offset

  --local Nmax_v, Nmin_v = -10000, 10000 -- absurd oposite values
  
  local max_v, min_v = 2*lscale+loffset, -2*lscale+loffset

	local pixels = {}
	local colors = {}
  --[[ --unused min/max visible values
  for z = 1, res.z do
		for x = 1, res.x do
      local rel = vector.new(x+pos1.x, pos1.y, z+pos1.z)
      local n = noisemap:get_3d(rel)
      if n > Nmax_v then Nmax_v = n elseif n < Nmin_v then Nmin_v = n end
		end
	end]]
  noise_vis.last_image[name].max = tostring(string.sub(max_v, 1, 5))
  noise_vis.last_image[name].min = tostring(string.sub(min_v, 1, 5))
  local minn_max = max_v-min_v
  local bright = 255/minn_max -- multiplyer to get the highest value to 255
  for z = 1, res.z do
		for x = 1, res.x do
      local rel = vector.new(x+pos1.x, pos1.y, z+pos1.z)
      local n = noisemap:get_3d(rel)
      if n > max_v then max_v = n elseif n < min_v then min_v = n end
      local cagg = math.min(math.max(math.round((n-min_v)*bright), 0), 255)
      if cagg > (-whites+255) or cagg < (-blacks+255) then
        cagg = 29
      end
      pixels[z] = pixels[z] or {}
      pixels[z][x] = {cagg, cagg, cagg}
      if ppos and vector.distance(vector.new(ppos.x,pos1.y,ppos.z), rel) < 3 then
        local colordistance = math.abs(vector.distance(vector.new(ppos.x,pos1.y,ppos.z), vector.new(x+pos1.x, pos1.y, z+pos1.z))-3)*255
        pixels[z][x][1] = math.min(pixels[z][x][1]+(colordistance*0.1), 255)
        pixels[z][x][2] = math.max(pixels[z][x][2]-(colordistance*0.1), 0)
        pixels[z][x][3] = math.max(pixels[z][x][3]-(colordistance*0.1), 0)
      else
      end
		end
	end
  

  
  mapname = name or "tnoise"
  local filename = mapname .. ".tga"
  
  noise_vis.last_image[name].img = filename
  
  local filenamepath = map_textures_path .. mapname .. ".tga"
  
	tga_encoder.image(pixels):save(filenamepath)

  
  core.dynamic_add_media({
    filename = filename,
    filepath = filenamepath,
    to_player = name,
  }, callback or function()end)  
	return filename
end

local noisehud = {}

local function add_noisehud(name)
  local player = core.get_player_by_name(name)
  local pos = vector.round(player:get_pos())
  if noisehud[name] then
    player:hud_remove(noisehud[name])
    noisehud[name] = nil
  end
  noisehud[name] = player:hud_add({
    type = "image",
    text = noise_vis.last_image[name].img or "blank.png",
    scale = {x=5,y=5},
    position = {x=1,y=0},
    offset = {x=-300.,y=300},
  })
end


--[[
minetest.register_chatcommand("noise", {
	params = "",
	description = "",
	privs = {server=true},
	func = function(name, param)
    local player = core.get_player_by_name(name)
		local pos1 = vector.add(player:get_pos(), -100)
		local pos2 = vector.add(pos1, 200)
    local filename = noise_vis.create_map(pos1, pos2, player:get_player_name(), function(name)
      add_noisehud(name)
    end, {
      offset = 4,
      scale = 2,
      spread = {x = 100, y = 100, z = 100},
      seed = 47,
      octaves = 4,
    }, 50)

	end,
})]]
local function get_noise_formspec(name, image_path, fields)
  fields = fields or {}
  local offset = tonumber(fields.offset) or dnp.offset
  local scale = tonumber(fields.scale) or dnp.scale
  local spread_x = tonumber(fields.spread_x) or dnp.spread.x
  local spread_y = tonumber(fields.spread_y) or dnp.spread.y
  local spread_z = tonumber(fields.spread_z) or dnp.spread.z
  local seed = tonumber(fields.seed) or dnp.seed
  local octaves = tonumber(fields.octaves) or dnp.octaves
  local persistence = tonumber(fields.persistence) or dnp.persistence
  local lacunarity = tonumber(fields.lacunarity) or dnp.lacunarity
  local flags = fields.flags or dnp.flags
  local xpos = tonumber(fields.xpos) or 0
  local ypos = tonumber(fields.ypos) or 0
  local zpos = tonumber(fields.zpos) or 0
  local dist = tonumber(fields.dist) or 100
  local minv = fields.minv or noise_vis.last_image[name].min
  local maxv = fields.maxv or noise_vis.last_image[name].max
  local scrollblacks = fields.scrollblacks or "VAL: 255"
  local scrollwhites = fields.scrollwhites or "VAL: 0"
  local whites = tonumber(string.sub(scrollblacks, 5, -1))/255
  local blacks = tonumber(string.sub(scrollwhites, 5, -1))/255
  local tatedmin, tatedmax
  local code = [[
{
  offset = ]]..offset..[[,
  scale = ]]..scale..[[,
  spread = {x = ]]..spread_x..[[, y = ]]..spread_y..[[, z = ]]..spread_z..[[},
  seed = ]]..seed..[[,
  octaves = ]]..octaves..[[,
  persistence = ]]..persistence..[[,
  lacunarity = ]]..lacunarity..[[,
  flags = "]]..flags..[[",
}

]]
  if minv and maxv then
    whites = (-whites+1)
    blacks = (-blacks+1)
    tatedmin = math.round((minv*(1-(whites*1))+maxv*(whites*1))*100)*0.01
    tatedmax = math.round((minv*(1-(blacks*1))+maxv*(blacks*1))*100)*0.01
    code = code ..
[[local max_noise_value = ]]..tatedmax..[[

local min_noise_value = ]]..tatedmin
  end
  local background = "background[-0.5,-0.5;19,12;noise_vis_bg.png]"

  if only_interface then
    background = "" ..
      "allow_close[false]" ..
      "style_type[background;noclip=true]" ..
      "background[-20,-20;70,70;noise_vis_bg.png]"
  end
  local backimage = ""
  if not fields.codedisplay then
    backimage = "image[8.26,1.76;9.58,9.58;noise_vis_plate.png]"..
    "image[7.96,1.77;9.9,9.9;noise_axis.png]"
  else
    --backimage = "image[8.26,1.76;9.58,6.5;noise_vis_plate.png]"
  end
  
  local formspec = "size[17,10]" ..
                   "label[0.5,0;Noise Map Parameters]" ..
                   background ..
                   --"image[-0.5,-0.5;19,12;noise_vis_bg.png]" ..
                   "field[0.5,1;3,1;offset;Offset;"..offset.."]" ..
                   "field[0.5,2;3,1;scale;Scale;"..scale.."]" ..
                   "field[0.5,3;3,1;spread_x;Spread X;"..spread_x.."]" ..
                   "field[0.5,4;3,1;spread_y;Spread Y;"..spread_y.."]" ..
                   "field[0.5,5;3,1;spread_z;Spread Z;"..spread_z.."]" ..
                   "field[4.5,1;3,1;seed;Seed;"..seed.."]" ..
                   "field[4.5,2;3,1;octaves;Octaves;"..octaves.."]" ..
                   "field[8.5,1;3,1;persistence;Persistence;"..persistence.."]" ..
                   "field[12.5,1;3,1;lacunarity;Lacunarity;"..lacunarity.."]" ..
                   "field[100,100;3,1;flags;Flags;"..flags.."]" .. -- not adjustable in menu
                   "field[4.5,3;3,1;xpos;x Pos;"..xpos.."]" ..
                   "field[4.5,4;3,1;ypos;y Pos;"..ypos.."]" ..
                   "field[4.5,5;3,1;zpos;z Pos;"..zpos.."]" ..
                   backimage ..
                   "field[11.5,1;1,1;dist;Dist;"..dist.."]" ..
                   "image_button[0.75,5.8;7,3.5;noise_vis_button.png;submit;]" ..
                   "image_button[15.5,0;1.2,1.2;noise_vis_quit_button.png;quitbutton;]" ..
                   "image_button[2.74,8.9;3,1.5;noise_vis_code_button.png;code;]"

  if image_path and not fields.codedisplay then
    formspec = formspec .. "image[8.5,2;9,9;" .. image_path .. "]"
  end
  if fields.codedisplay then
    formspec = formspec ..
      "style_type[textarea;font=bold;font_size=20]" ..
      "textarea[8.7,1.9;7.55,6.35;codedisplayer;;"..code.."]" ..
      "image_button[8.32,7.5;7.77,2.33;noise_vis_to_code_button.png;codesubmit;]"
  end
  if minv and maxv then
    formspec = formspec ..
      "label[9.7,9.71;Noise values:]" ..
      "label[11.32,9.71;Min: "..minv.."]" ..
      "label[12.32,9.71;Max: "..maxv.."]" ..
      "image[16,1.8;0.6,9.5;noise_vis_255_gradient.png]" ..
      "image[16,1.8;0.6,"..((-blacks+1)*9.5)..";noise_vis_255_gradient.png^[colorize:#422:255]" ..
      "image[16,"..((-whites+1)*8.25+1.8)..";0.6,"..(whites*9.5)..";noise_vis_255_gradient.png^[colorize:#422:255]" ..
      "scrollbaroptions[min=0;max=255;arrows=true]"..
      "scrollbar[16.5,1.48;0.3,8.9;vertical;scrollwhites;"..(string.sub(scrollwhites, 5, -1)).."]" ..
      "scrollbaroptions[min=0;max=255;arrows=true]"..
      "scrollbar[16.8,1.48;0.3,8.9;vertical;scrollblacks;"..(string.sub(scrollblacks, 5, -1)).."]"
      --[[
      for i=0, 10 do
        local mult = math.round((maxv*(1-(i*0.1))+minv*(i*0.1))*100)/100
        local poss = 1.7*(1-(i*0.1))+9.6*(i*0.1)
        formspec = formspec .. "label[16,"..poss..";"..mult.."]"
        
      end]]
      if tatedmin and tatedmax then
        local poss = ((-whites+1)*8.25+1.8)
        formspec = formspec .. "label[16,"..poss..";"..tatedmin.."]"
        poss = ((-blacks+1)*8.25+1.3)
        formspec = formspec .. "label[16,"..poss..";"..tatedmax.."]"
      end
      
    
  end

  return formspec
end

minetest.register_chatcommand("noise", {
    params = "",
    description = "Open noise map parameters form",
    privs = {server=true},
    func = function(name, param)
        minetest.show_formspec(name, "noise_map:params", get_noise_formspec(name))
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "noise_map:params" then
        local offset = tonumber(fields.offset) or dnp.offset
        local scale = tonumber(fields.scale) or dnp.scale
        local spread_x = tonumber(fields.spread_x) or dnp.spread.x
        local spread_y = tonumber(fields.spread_y) or dnp.spread.y
        local spread_z = tonumber(fields.spread_z) or dnp.spread.z
        local seed = tonumber(fields.seed) or dnp.seed
        local octaves = tonumber(fields.octaves) or dnp.octaves
        local persistence = tonumber(fields.persistence) or dnp.persistence
        local lacunarity = tonumber(fields.lacunarity) or dnp.lacunarity
        local flags = fields.flags or dnp.flags
        local xpos = tonumber(fields.xpos) or 0
        local ypos = tonumber(fields.ypos) or 0
        local zpos = tonumber(fields.zpos) or 0
        local dist = tonumber(fields.dist) or 100
        local scrollblacks = fields.scrollblacks or "VAL: 255"
        local scrollwhites = fields.scrollwhites or "VAL: 0"
        local codedisplayer
        if fields.codedisplayer then
          codedisplayer = noise_vis.parse_table(fields.codedisplayer)
        end

        local pos1 = vector.new(xpos, ypos, zpos)
        local pos2 = vector.add(pos1, dist)

        local pname = player:get_player_name()
        local image_path = noise_vis.last_image[pname].img or "blank.png"
        
        local ffields = fields
        if fields.code then
          ffields["codedisplay"] = true
        end
        if codedisplayer and fields.codesubmit then
          local llooplist = codedisplayer
          if not codedisplayer.spread then
            llooplist = codedisplayer[""]
          end
          if llooplist and #llooplist then
            for noisep,value in pairs(llooplist) do
              ffields[noisep] = value
            end
            ffields["spread_x"] = llooplist.spread.x
            ffields["spread_y"] = llooplist.spread.y
            ffields["spread_z"] = llooplist.spread.z
          end
          
          offset = ffields.offset or offset
          scale = ffields.scale or scale
          spread_x = ffields.spread_x or spread_x
          spread_y = ffields.spread_y or spread_y
          spread_z = ffields.spread_z or spread_z
          seed = ffields.seed or seed
          octaves = ffields.octaves or octaves
          persistence = ffields.persistence or persistence
          lacunarity = ffields.lacunarity or lacunarity
          flags = ffields.flags or flags
          xpos = ffields.xpos or xpos
          ypos = ffields.ypos or ypos
          zpos = ffields.zpos or zpos
          dist = ffields.dist or dist
        end
        
        
        if fields.submit or fields.codesubmit or fields.code then
          if not fields.code or true then -- undisabled image gen when pressing code (en case of value changes for min max flux)
            local filename = noise_vis.create_map(pos1, pos2, player:get_player_name(), function(name)
              ffields.minv = noise_vis.last_image[pname].min
              ffields.maxv = noise_vis.last_image[pname].max

              image_path = noise_vis.last_image[pname].img or "blank.png"
              -- This callback can be used to update the formspec with the new image
              minetest.show_formspec(name, "noise_map:params", get_noise_formspec(name, image_path, ffields))
            end, {
                offset = offset,
                scale = scale,
                spread = {x = spread_x, y = spread_y, z = spread_z},
                seed = seed,
                octaves = octaves,
                persistence = persistence,
                lacunarity = lacunarity,
                flags = flags,
            }, scrollwhites, scrollblacks)
          else
            minetest.show_formspec(pname, "noise_map:params", get_noise_formspec(pname, image_path, ffields))
          end
        elseif fields.quitbutton then
          if only_interface then
            core.disconnect_player(pname)
          else
            core.close_formspec(pname, "noise_map:params")
          end
        else
          --minetest.show_formspec(pname, "noise_map:params", get_noise_formspec(pname, image_path, ffields))
        end
    end
end)

core.register_on_joinplayer(function(player)
  noise_vis.last_image[player:get_player_name()] = {}
end)
if only_interface then
  core.register_on_joinplayer(function(player)
    local name = player:get_player_name()
    minetest.show_formspec(name, "noise_map:params", get_noise_formspec(name))
  end)
end


