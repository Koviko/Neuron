﻿--Neuron, a World of Warcraft® user interface addon.
--Copyright© 2006-2014 Connor H. Chenoweth, aka Maul - All rights reserved.

local AddOnFolderName, private = ...
-- See http://wow.curseforge.com/addons/neuron-status-bars/localization/
local L = _G.LibStub("AceLocale-3.0"):NewLocale("Neuron", "zhCN", false)
if not L then return end 
--@localization(locale="zhCN", format="lua_additive_table", handle-unlocalized="comment")@