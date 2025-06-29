minetest.register_on_joinplayer(function(player)
  player:set_pos(vector.new(1000,0,1000)) -- player doesn't show up on noise chart
  player:hud_add({
    type = "image",
    text = "noise_vis_bg.png",
    scale = vector.new(100,100,100),
    position = {x=0,y=0}
  })
  player:hud_set_flags({hotbar = false, healthbar = false, crosshair = false, wielditem = false, breathbar = false, minimap = false, basic_debug = false, chat = false})
end)