--[[
    Addon: nostrum
    Author: YourName
    Version: 1.0
    Description: Nostrum Plugin for Ashita
    Link: https://docs.windower.net/addons/nostrum/
--]]

--------------------------------------------------------------------------------
-- Standard Ashita add-on metadata:
--------------------------------------------------------------------------------
addon.name      = "nostrum";
addon.author    = "YourName";
addon.version   = "1.0";
addon.desc      = "Nostrum Plugin for Ashita";
addon.link      = "https://docs.windower.net/addons/nostrum/";

--------------------------------------------------------------------------------
-- Required libraries:
--------------------------------------------------------------------------------
require("common")
local imgui = require('imgui');
local incoming_chunk_event, outgoing_chunk_event

--------------------------------------------------------------------------------
-- Main table that we return from this file:
--------------------------------------------------------------------------------
local box = {}
--------------------------------------------------------------------------------
-- UI Scaling (Modify `UI_SCALE` to resize everything)
--------------------------------------------------------------------------------
local UI_H_SCALE = 1  
local UI_V_SCALE = .88

-- Scaled button sizes
local btnWidth = math.floor(50 * UI_H_SCALE)
local btnHeight = math.floor(64 * UI_V_SCALE)
local btnSize = {btnWidth, btnHeight}

--------------------------------------------------------------------------------
-- ImGui color constants:
--------------------------------------------------------------------------------
local IMGUI_COL_Text           = 0
local IMGUI_COL_Button         = 21
local IMGUI_COL_ButtonHovered  = 22
local IMGUI_COL_ButtonActive   = 23

--------------------------------------------------------------------------------
-- Default color values for backgrounds/text:
--------------------------------------------------------------------------------
local DEFAULT_RED_BG    = 0xFFFF0000
local DEFAULT_BLACK_TXT = 0xFF000000

--------------------------------------------------------------------------------
-- Helper: Compute a lighter "highlight" color from a base color.
-- Assumes color is in 0xAARRGGBB format.
--------------------------------------------------------------------------------
local function GetHighlightColor(color)
    local a = math.floor(color / 0x1000000)           -- AA
    local r = math.floor((color % 0x1000000) / 0x10000)  -- RR
    local g = math.floor((color % 0x10000) / 0x100)      -- GG
    local b = color % 0x100                             -- BB

    -- Increase brightness by 30 (clamped to 255)
    r = math.min(255, r + 30)
    g = math.min(255, g + 30)
    b = math.min(255, b + 30)

    return (a * 0x1000000) + (r * 0x10000) + (g * 0x100) + b
end

--------------------------------------------------------------------------------
-- Spell Lists:
--   Each spell has: label, name, level, bg_color, text_color, enabled=<bool>
--------------------------------------------------------------------------------

-- Single Buffs (Protectra I–V, Shellra I–V, Blink, Aquaveil)
local singleBuffs = {
    { label = "Pro",  name = "Protectra",     level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "Pro2", name = "Protectra II",  level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Pro3", name = "Protectra III", level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Pro4", name = "Protectra IV",  level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Pro5", name = "Protectra V",   level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },

    { label = "Shell",  name = "Shellra",       level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "Shell2", name = "Shellra II",    level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Shell3", name = "Shellra III",   level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Shell4", name = "Shellra IV",    level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Shell5", name = "Shellra V",     level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },

    { label = "Blink", name = "Blink",         level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "Aqua",  name = "Aquaveil",      level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
}

-- Buff Spells (Sneak, Invisible, and now Haste)
local buffSpells = {
    { label = "Sneak", name = "Sneak",     level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "Invis", name = "Invisible", level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Haste", name = "Haste",     level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
}

-- Erase Spells (Poisona, Silena, Erase)
local eraseSpells = {
    { label = "P-na",   name = "Poisona", level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "Silena", name = "Silena",  level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "Erase",  name = "Erase",   level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
}

-- Cure/Regen Spells (Cure I–V, Regen I–IV)
local cureSpells = {
    { label = "C1", name = "Cure",     level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "C2", name = "Cure II",  level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "C3", name = "Cure III", level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = true },
    { label = "C4", name = "Cure IV",  level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "C5", name = "Cure V",   level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },

    { label = "R1", name = "Regen",    level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "R2", name = "Regen II", level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "R3", name = "Regen III",level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
    { label = "R4", name = "Regen IV", level = 10, bg_color = DEFAULT_RED_BG, text_color = DEFAULT_BLACK_TXT, enabled = false },
}

--------------------------------------------------------------------------------
-- Helper to send commands via Ashita's chat manager:
--------------------------------------------------------------------------------
local function sendCommand(cmd)
    local chatManager = AshitaCore:GetChatManager()
    if chatManager and chatManager.QueueCommand then
        pcall(function()
            chatManager:QueueCommand(0, cmd)
        end)
    end
end

--------------------------------------------------------------------------------
-- Draw a small square button with no text.
--------------------------------------------------------------------------------
local function DrawSmallSquareButton(size, bgColor, onClick)
    imgui.PushStyleColor(IMGUI_COL_Button,        bgColor)
    imgui.PushStyleColor(IMGUI_COL_ButtonHovered, bgColor)
    imgui.PushStyleColor(IMGUI_COL_ButtonActive,  bgColor)
    imgui.PushStyleColor(IMGUI_COL_Text,          0x00000000) -- Transparent text
    if imgui.Button("##SquareButton", size) then
        if onClick then onClick() end
    end
    imgui.PopStyleColor(4)
end

--------------------------------------------------------------------------------
-- Table to store the boolean state for each config button.
-- Keyed by a unique string for each spell.
--------------------------------------------------------------------------------
local configButtonState = {}

--------------------------------------------------------------------------------
-- Save configuration to an XML file ("current.xml").
--------------------------------------------------------------------------------
local function SaveConfigToFile()
    local file = io.open("current.xml", "w")
    if file then
        file:write("<config>\n")
        for key, state in pairs(configButtonState) do
            file:write(string.format('  <button key="%s" value="%s"/>\n', key, tostring(state)))
        end
        file:write("</config>\n")
        file:close()
    end
end

--------------------------------------------------------------------------------
-- Update configuration state to ensure all spells are represented.
--------------------------------------------------------------------------------
local function UpdateConfigWithMissingKeys()
    local function EnsureGroup(group, groupKey)
        for i, sp in ipairs(group) do
            local uniqueKey = string.format("%s_%d_%s", groupKey, i, sp.name)
            if configButtonState[uniqueKey] == nil then
                configButtonState[uniqueKey] = false
            end
        end
    end
    EnsureGroup(singleBuffs, "singleBuffs")
    EnsureGroup(buffSpells, "buffSpells")
    EnsureGroup(eraseSpells, "eraseSpells")
    EnsureGroup(cureSpells, "cureSpells")
end

--------------------------------------------------------------------------------
-- Load configuration from "current.xml" (simple parsing).
--------------------------------------------------------------------------------
local function LoadConfigFromFile()
    local file = io.open("current.xml", "r")
    if file then
        local content = file:read("*a")
        file:close()
        for key, value in content:gmatch('<button key="(.-)" value="(.-)"%s*/>') do
            configButtonState[key] = (value == "true")
        end
    end
end

--------------------------------------------------------------------------------
-- Load or create configuration.
-- On program start, if the file doesn't exist, create it with all spells.
-- If it does exist, load it and then update with any missing keys.
--------------------------------------------------------------------------------
local function LoadOrCreateConfigFile()
    local file = io.open("current.xml", "r")
    if file then
        local content = file:read("*a")
        file:close()
        for key, value in content:gmatch('<button key="(.-)" value="(.-)"%s*/>') do
            configButtonState[key] = (value == "true")
        end
    end
    UpdateConfigWithMissingKeys()
    SaveConfigToFile()
end

--------------------------------------------------------------------------------
-- Helper: Get the effective color for a spell in main UI based on config state.
-- If the config state is true, the spell's button uses sp.bg_color;
-- if false, the spell is omitted (returns nil).
--------------------------------------------------------------------------------
local function GetEffectiveColorForSpell(sp, groupKey, index)
    local uniqueKey = string.format("%s_%d_%s", groupKey, index, sp.name)
    if configButtonState[uniqueKey] then
        return sp.bg_color
    else
        return nil
    end
end

--------------------------------------------------------------------------------
-- Helper: For a special group, return only the highest-level enabled spell.
-- (Assumes the list is in ascending order by level.)
--------------------------------------------------------------------------------
local function GetHighestEnabledSpell(group, groupKey, pattern)
    local highest = nil
    local highestIndex = nil
    for i, sp in ipairs(group) do
        if sp.name:find(pattern) then
            local color = GetEffectiveColorForSpell(sp, groupKey, i)
            if color then
                highest = sp
                highestIndex = i
            end
        end
    end
    if highest then
        return { spell = highest, index = highestIndex }
    end
    return nil
end

--------------------------------------------------------------------------------
-- Helper: For a normal group, return the list of enabled spells.
--------------------------------------------------------------------------------
local function GetEnabledSpells(group, groupKey)
    local list = {}
    for i, sp in ipairs(group) do
        local color = GetEffectiveColorForSpell(sp, groupKey, i)
        if color then
            table.insert(list, { spell = sp, index = i })
        end
    end
    return list
end

--------------------------------------------------------------------------------
-- Flag to ensure we load configuration only once on startup.
--------------------------------------------------------------------------------
local configLoaded = false

--------------------------------------------------------------------------------
-- Config window.
-- (Shows all spells with toggles so the user can set the config state.)
--------------------------------------------------------------------------------
local showConfigBox = false
local function DrawConfigBox()
    if not showConfigBox then return end

    if imgui.Begin("Nostrum Config") then
        imgui.Text("These are your spells/abilities.")
        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        local function DrawConfigButtonForSpell(sp, groupKey, index)
            local label = string.format("%s (Lv%d)", sp.name, sp.level)
            local uniqueKey = string.format("%s_%d_%s", groupKey, index, sp.name)
            if configButtonState[uniqueKey] == nil then
                configButtonState[uniqueKey] = false
            end
            local currentColor = configButtonState[uniqueKey] and sp.bg_color or 0x00000000
            imgui.PushID(uniqueKey)
            DrawSmallSquareButton({14,14}, currentColor, function()
                configButtonState[uniqueKey] = not configButtonState[uniqueKey]
            end)
            imgui.PopID()
            imgui.SameLine()
            imgui.Text(label)
        end

        imgui.Text("Single Buffs:")
        for i, sp in ipairs(singleBuffs) do
            DrawConfigButtonForSpell(sp, "singleBuffs", i)
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        imgui.Text("Buff Spells:")
        for i, sp in ipairs(buffSpells) do
            DrawConfigButtonForSpell(sp, "buffSpells", i)
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        imgui.Text("Erase Spells:")
        for i, sp in ipairs(eraseSpells) do
            DrawConfigButtonForSpell(sp, "eraseSpells", i)
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        imgui.Text("Cure/Regen Spells:")
        for i, sp in ipairs(cureSpells) do
            DrawConfigButtonForSpell(sp, "cureSpells", i)
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        if imgui.Button("OK") then
            UpdateConfigWithMissingKeys()
            SaveConfigToFile()
            LoadOrCreateConfigFile()  -- reload settings from file
            showConfigBox = false
            configLoaded = false  -- force reload in main window on next frame
        end
    end
    imgui.End()
end

--------------------------------------------------------------------------------
-- The main Spell Grid window.
-- (Restores row/column layout including job abilities (/heal, Divine Seal) and uses the config state.)
--------------------------------------------------------------------------------
box.DrawWindow = function()
    if not configLoaded then
        LoadOrCreateConfigFile()
        configLoaded = true
    end

    DrawConfigBox()

    if imgui.Begin("Spell Grid") then
        if imgui.Button("Open Config") then
            showConfigBox = true
        end

        imgui.Spacing(); imgui.Separator(); imgui.Spacing()

        ---------------
        -- Job Abilities Column (12 Fixed Buttons, Including Blanks For now)
        ---------------
        imgui.BeginGroup()

        local jobAbilities = {
            { label = "Rest", command = "/heal" },
            { label = "DivS", command = '/ja "Divine Seal" <me>' },
            { label = "Dia",  command = '/ma "Dia II" <bt>' },
            { label = "Slow", command = '/ma "Slow" <bt>' },
            { label = "Para", command = '/ma "Paralyze" <bt>' },
            { label = "Pois", command = '/ma "Poison" <bt>' },
            { label = "Aero", command = '/ma "Aero" <bt>' },
            { label = "Fire", command = '/ma "Fire" <bt>' },
            { label = "",     command = "" },  -- Blank Button
            { label = "",     command = "" },  -- Blank Button
            { label = "",     command = "" },  -- Blank Button
            { label = "",     command = "" },  -- Blank Button
        }

        for _, ja in ipairs(jobAbilities) do
            if ja.label ~= "" then
                if imgui.Button(ja.label, {btnSize[1], btnSize[2] / 2}) then
                    sendCommand(ja.command)
                end
            else
                imgui.Button("", {btnSize[1], btnSize[2] / 2}) -- Blank Button for alignment
            end
        end

        imgui.EndGroup()
        imgui.SameLine()

        ---------------
        -- Spells Column (Starts Immediately After Job Abilities)
        ---------------
        imgui.BeginGroup()

        -- SINGLE BUFFS (Top row)
        local displayedSingleBuffs = {}
        local protectra = GetHighestEnabledSpell(singleBuffs, "singleBuffs", "Protectra")
        if protectra then table.insert(displayedSingleBuffs, protectra) end
        local shellra = GetHighestEnabledSpell(singleBuffs, "singleBuffs", "Shellra")
        if shellra then table.insert(displayedSingleBuffs, shellra) end
        for i, sp in ipairs(singleBuffs) do
            if not sp.name:find("Protectra") and not sp.name:find("Shellra") then
                local uniqueKey = string.format("singleBuffs_%d_%s", i, sp.name)
                if configButtonState[uniqueKey] then
                    table.insert(displayedSingleBuffs, { spell = sp, index = i })
                end
            end
        end

        for _, item in ipairs(displayedSingleBuffs) do
            imgui.PushID(item.spell.label)
            local sp = item.spell
            local highlightColor = GetHighlightColor(sp.bg_color)
            imgui.PushStyleColor(IMGUI_COL_Button, sp.bg_color)
            imgui.PushStyleColor(IMGUI_COL_ButtonHovered, highlightColor)
            imgui.PushStyleColor(IMGUI_COL_ButtonActive, highlightColor)
            imgui.PushStyleColor(IMGUI_COL_Text, sp.text_color)
            if imgui.Button(sp.label, {btnSize[1], btnSize[2] / 2}) then
                local cmd = string.format('/ma "%s" <me>', sp.name)
                sendCommand(cmd)
            end
            imgui.PopStyleColor(4)
            imgui.PopID()
            imgui.SameLine()
        end

        imgui.Spacing(); imgui.Separator()

        ---------------
        -- 6 Players (Cure Row First, Buffs/Erase Below It)
        ---------------
        for row = 1, 6 do
            imgui.PushID("CureRow_" .. row)

            local pIndex = row - 1
            local targetString = string.format("<p%d>", pIndex)

            -- Cure & Regen (Draw First)
            local displayedCureSpells = GetEnabledSpells(cureSpells, "cureSpells")
            local highestRegen = nil

            for _, item in ipairs(displayedCureSpells) do
                local sp = item.spell
                if sp.name:find("Regen") then
                    highestRegen = sp -- Only the last enabled Regen spell is kept
                end
            end

            -- Draw Cure Spells (skip Regen spells)
            for _, item in ipairs(displayedCureSpells) do
                local sp = item.spell
                if not sp.name:find("Regen") then
                    local highlightColor = GetHighlightColor(sp.bg_color)

                    imgui.PushStyleColor(IMGUI_COL_Button, sp.bg_color)
                    imgui.PushStyleColor(IMGUI_COL_ButtonHovered, highlightColor)
                    imgui.PushStyleColor(IMGUI_COL_ButtonActive, highlightColor)
                    imgui.PushStyleColor(IMGUI_COL_Text, sp.text_color)

                    if imgui.Button(sp.label, {btnSize[1], btnSize[2] / 2}) then
                        local cmd = string.format('/ma "%s" <p%d>', sp.name, pIndex)
                        sendCommand(cmd)
                    end

                    imgui.PopStyleColor(4)
                    imgui.SameLine()
                end
            end

            -- Draw the highest Regen Spell if Available
            if highestRegen then
                local highlightColor = GetHighlightColor(highestRegen.bg_color)

                imgui.PushStyleColor(IMGUI_COL_Button, highestRegen.bg_color)
                imgui.PushStyleColor(IMGUI_COL_ButtonHovered, highlightColor)
                imgui.PushStyleColor(IMGUI_COL_ButtonActive, highlightColor)
                imgui.PushStyleColor(IMGUI_COL_Text, highestRegen.text_color)

                if imgui.Button(highestRegen.label, {btnSize[1], btnSize[2] / 2}) then
                    local cmd = string.format('/ma "%s" <p%d>', highestRegen.name, pIndex)
                    sendCommand(cmd)
                end

                imgui.PopStyleColor(4)
            end

            imgui.PopID()

            imgui.PushID("BuffRow_" .. row)

            -- Buffs & Erase (Draw Below Cures)
            local displayedBuffSpells = GetEnabledSpells(buffSpells, "buffSpells")
            for i, item in ipairs(displayedBuffSpells) do
                imgui.PushID(item.spell.label)
                local sp = item.spell
                local highlightColor = GetHighlightColor(sp.bg_color)
                imgui.PushStyleColor(IMGUI_COL_Button, sp.bg_color)
                imgui.PushStyleColor(IMGUI_COL_ButtonHovered, highlightColor)
                imgui.PushStyleColor(IMGUI_COL_ButtonActive, highlightColor)
                imgui.PushStyleColor(IMGUI_COL_Text, sp.text_color)

                if imgui.Button(sp.label, {btnSize[1], btnSize[2] / 2}) then
                    local cmd = string.format('/ma "%s" %s', sp.name, targetString)
                    sendCommand(cmd)
                end

                imgui.PopStyleColor(4)
                imgui.PopID()
                if i < #displayedBuffSpells then
                    imgui.SameLine()
                end
            end

            imgui.PopID()
        end

        imgui.EndGroup()
    end
    imgui.End()
end
---------------------------------------------------------------------------
-- Packet detection:
--------------------------------------------------------------------------------
-- Zoning detection (based on Nostrum)
ashita.events.register('outgoing_packet', 'zone_detect_out', function(id, size, packet)
    -- When zoning is initiated, packet ID 0x01A is sent.
    if id == 0x01A then
        print("Zone change initiated. Disabling UI...");
        box.Enabled = false;  -- Disable drawing UI
    end
    return false;
end)

ashita.events.register('incoming_packet', 'zone_detect_in', function(id, size, packet)
    -- When the new zone loads, packet ID 0x00B is sent.
    if id == 0x00B then
        print("Zone loaded. Re-enabling UI shortly...");
        ashita.timer.once(5, function()
            box.Enabled = true;  -- Re-enable UI
            if box.Reload then
                box.Reload();    -- Call any reload routine if defined
            end
        end);
    end
    return false;
end)

---------------------------------------------------------------------------
-- d3d_present callback:
--------------------------------------------------------------------------------
ashita.events.register('d3d_present', 'nostrum_d3d_present', function()
    box.DrawWindow()
end)

--------------------------------------------------------------------------------
-- Return our main table:
--------------------------------------------------------------------------------
return box
