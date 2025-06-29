#!/usr/bin/env lua5.1
dofile("../init.lua")

local _ = { 0 }
local R = { 1 }
local G = { 2 }
local B = { 3 }
local W = { 4 }

local pixels_colormapped_bt = {
	{ W, W, _, _, _, B, _, B, },
	{ W, W, _, _, _, B, B, B, },
	{ _, _, G, G, G, B, _, B, },
	{ _, _, G, _, G, B, B, B, },
	{ _, R, G, _, _, _, _, _, },
	{ _, R, G, G, G, _, _, _, },
	{ _, R, _, _, _, _, _, _, },
	{ R, R, R, _, _, _, _, _, },
}

local pixels_colormapped_tb = {
	{ R, R, R, _, _, _, _, _, },
	{ _, R, _, _, _, _, _, _, },
	{ _, R, G, G, G, _, _, _, },
	{ _, R, G, _, _, _, _, _, },
	{ _, _, G, _, G, B, B, B, },
	{ _, _, G, G, G, B, _, B, },
	{ W, W, _, _, _, B, B, B, },
	{ W, W, _, _, _, B, _, B, },
}

local pixels_colormapped_by_scanline_order = {
	["bottom_top"] = pixels_colormapped_bt,
	["top_bottom"] = pixels_colormapped_tb,
}

local colormap_32bpp = {
	{    0,   0,   0, 127 },
	{ 255,    0,   0, 255 },
	{    0, 255,   0, 255 },
	{    0,   0, 255, 255 },
	{ 255,  255, 255, 128 },
}

local colormap_24bpp = {
	{    0,   0,   0 },
	{ 255,    0,   0 },
	{    0, 255,   0 },
	{    0,   0, 255 },
	{ 255,  255, 255 },
}

local colormap_16bpp = {
	{    0,   0,   0,   0 },
	{ 255,    0,   0, 255 },
	{    0, 255,   0, 255 },
	{    0,   0, 255, 255 },
	{ 255,  255, 255, 255 },
}

local colormap_by_color_format = {
	["A1R5G5B5"] = colormap_16bpp,
	["B8G8R8"]   = colormap_24bpp,
	["B8G8R8A8"] = colormap_32bpp,
}

for color_format, _ in pairs(
	tga_encoder.features.color_format
) do
	if ("Y8" ~= color_format) then
		for scanline_order, _ in pairs(
			tga_encoder.features.scanline_order
		) do
			local filename
			local pixels
			filename = "type1" ..
				'-' .. color_format ..
				'-' .. scanline_order ..
				'.tga'
			pixels = pixels_colormapped_by_scanline_order[
				scanline_order
			]
			local colormap = colormap_by_color_format[
				color_format
			]
			local properties = {
				colormap = colormap,
				color_format = color_format,
				scanline_order = scanline_order,
			}
			print(filename)
			local image = tga_encoder.image(pixels)
			image:save(filename, properties)
		end
	end
end

local _ = {    0,   0,   0, 127 }
local R = { 255,    0,   0, 255 }
local G = {    0, 255,   0, 255 }
local B = {    0,   0, 255, 255 }
local W = { 255,  255, 255, 128 }

local pixels_rgba_bt = {
	{ W, W, _, _, _, B, _, B, },
	{ W, W, _, _, _, B, B, B, },
	{ _, _, G, G, G, B, _, B, },
	{ _, _, G, _, G, B, B, B, },
	{ _, R, G, _, _, _, _, _, },
	{ _, R, G, G, G, _, _, _, },
	{ _, R, _, _, _, _, _, _, },
	{ R, R, R, _, _, _, _, _, },
}

local pixels_rgba_tb = {
	{ R, R, R, _, _, _, _, _, },
	{ _, R, _, _, _, _, _, _, },
	{ _, R, G, G, G, _, _, _, },
	{ _, R, G, _, _, _, _, _, },
	{ _, _, G, _, G, B, B, B, },
	{ _, _, G, G, G, B, _, B, },
	{ W, W, _, _, _, B, B, B, },
	{ W, W, _, _, _, B, _, B, },
}

local pixels_rgba_by_scanline_order = {
	["bottom_top"] = pixels_rgba_bt,
	["top_bottom"] = pixels_rgba_tb,
}

local _ = {    0,   0,   0 }
local R = { 255,    0,   0 }
local G = {    0, 255,   0 }
local B = {    0,   0, 255 }
local W = { 255,  255, 255 }

local pixels_rgb_bt = {
	{ W, W, _, _, _, B, _, B, },
	{ W, W, _, _, _, B, B, B, },
	{ _, _, G, G, G, B, _, B, },
	{ _, _, G, _, G, B, B, B, },
	{ _, R, G, _, _, _, _, _, },
	{ _, R, G, G, G, _, _, _, },
	{ _, R, _, _, _, _, _, _, },
	{ R, R, R, _, _, _, _, _, },
}

local pixels_rgb_tb = {
	{ R, R, R, _, _, _, _, _, },
	{ _, R, _, _, _, _, _, _, },
	{ _, R, G, G, G, _, _, _, },
	{ _, R, G, _, _, _, _, _, },
	{ _, _, G, _, G, B, B, B, },
	{ _, _, G, G, G, B, _, B, },
	{ W, W, _, _, _, B, B, B, },
	{ W, W, _, _, _, B, _, B, },
}

local pixels_rgb_by_scanline_order = {
	["bottom_top"] = pixels_rgb_bt,
	["top_bottom"] = pixels_rgb_tb,
}

local tga_type_by_compression = {
	["RAW"] = "2",
	["RLE"] = "10",
}

local pixels_by_scanline_order_by_color_format = {
	["A1R5G5B5"] = pixels_rgba_by_scanline_order,
	["B8G8R8"] = pixels_rgb_by_scanline_order,
	["B8G8R8A8"] = pixels_rgba_by_scanline_order,
	["Y8"] = pixels_rgb_by_scanline_order,
}

for color_format, _ in pairs(
	tga_encoder.features.color_format
) do
	local pixels_by_scanline_order = pixels_by_scanline_order_by_color_format[
		color_format
	]
	for compression, _ in pairs(
		tga_encoder.features.compression
	) do
		local tga_type
		if (
			"Y8" == color_format and
			"RAW" == compression
		) then
			tga_type = "3"
		else
			tga_type = tga_type_by_compression[
				compression
			]
		end
		-- tga_encoder can not encode grayscale RLE (type 11)
		if not(
			"Y8" == color_format and
			"RLE" == compression
		) then
			for scanline_order, _ in pairs(
				tga_encoder.features.scanline_order
			) do
			local filename = "type" .. tga_type ..
					'-' .. color_format ..
					'-' .. scanline_order ..
					'.tga'
				local pixels = pixels_by_scanline_order[
					scanline_order
				]
				local properties = {
					color_format = color_format,
					compression = compression,
					scanline_order = scanline_order,
				}
				print(filename)
				local image = tga_encoder.image(pixels)
				image:save(filename, properties)
			end
		end
	end
end
