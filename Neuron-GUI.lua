--Neuron GUI, a World of Warcraft® user interface addon.

local addonName = ...

local NEURON = Neuron

NEURON.NeuronGUI = Neuron:NewModule("GUI", "AceEvent-3.0", "AceHook-3.0")
local NeuronGUI = NEURON.NeuronGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local AceGUI = LibStub("AceGUI-3.0")

local editorFrame = {}
NeuronGUI.editorFrame = editorFrame
local barListFrame = {}
NeuronGUI.barListFrame = barListFrame

-----------------------------------------------------------------------------
--------------------------INIT FUNCTIONS-------------------------------------
-----------------------------------------------------------------------------

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function NeuronGUI:OnInitialize()

    ---This loads the Neuron interface panel
    LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(NeuronGUI.interfaceOptions, addonName)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, NeuronGUI.interfaceOptions)
    NeuronGUI.interfaceOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(NEURON.db)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)


end

--- **OnEnable** which gets called during the PLAYER_LOGIN event, when most of the data provided by the game is already present.
--- Do more initialization here, that really enables the use of your addon.
--- Register Events, Hook functions, Create Frames, Get information from
--- the game that wasn't available in OnInitialize
function NeuronGUI:OnEnable()

    NeuronGUI:CreateBarEditor()
    editorFrame:Hide()
    editorFrame.isHidden = true
    NeuronGUI.GUILoaded = true

end


--- **OnDisable**, which is only called when your addon is manually being disabled.
--- Unhook, Unregister Events, Hide frames that you created.
--- You would probably only use an OnDisable if you want to
--- build a "standby" mode, or be able to toggle modules on/off.
function NeuronGUI:OnDisable()

end

-------------------------------------------------



-----------------------------------------------------------------------------
--------------------------Helper Functions-----------------------------------
-----------------------------------------------------------------------------

local function round(num, idp)
    local mult = 10^(idp or 0)
    return math.floor(num * mult + 0.5) / mult
end


----------------------------------------------------------------



-----------------------------------------------------------------------------
--------------------------GUI Code-------------------------------------------
-----------------------------------------------------------------------------


function NeuronGUI:ToggleEditor()
    if editorFrame.isHidden == true then
        editorFrame:Show()
        editorFrame.isHidden = false
    else
        editorFrame:Hide()
        editorFrame.isHidden = true
    end
end


function NeuronGUI:CreateBarEditor()

    editorFrame = AceGUI:Create("Frame")
    editorFrame:SetTitle("Neuron Editor")
    editorFrame:SetWidth("900")
    editorFrame:SetHeight("600")
    if NEURON.CurrentBar then
        editorFrame:SetStatusText("The Currently Selected Bar is: " .. NEURON.CurrentBar.gdata.name)
    else
        editorFrame:SetStatusText("Welcome to the Neuron editor, please select a bar to begin")
    end
    editorFrame:SetCallback("OnClose", function() NeuronGUI:ToggleEditor() end)
    editorFrame:SetLayout("Flow")

    local barListContainer = AceGUI:Create("InlineGroup")
    barListContainer:SetTitle("Bar List")
    barListContainer:SetWidth(200)
    barListContainer:SetFullHeight(true)
    barListContainer:SetLayout("Fill")
    editorFrame:AddChild(barListContainer)

    barListFrame = AceGUI:Create("ScrollFrame")
    barListFrame:SetLayout("Flow")
    barListFrame:SetFullHeight(true)
    barListFrame:SetFullWidth(true)
    barListContainer:AddChild(barListFrame)

    NeuronGUI:PopulateBarList(barListFrame)
end

function NeuronGUI:PopulateBarList()

    local barNames = {}

    for _,bar in pairs(NEURON.BARIndex) do
        if (bar.gdata.name) then
            barNames[bar.gdata.name] = bar
        end
    end

    --table.sort(barNames)


    for name, bar in pairs(barNames) do
        local barLabel = AceGUI:Create("InteractiveLabel")
        barLabel:SetText(name)
        barLabel:SetFont("Fonts\\FRIZQT__.TTF", 18)
        barLabel:SetFullWidth(true)
        barLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        barLabel.bar = bar
        barLabel:SetCallback("OnEnter", function(self) NEURON.NeuronBar:OnEnter(self.bar) end)
        barLabel:SetCallback("OnLeave", function(self) NEURON.NeuronBar:OnLeave(self.bar) end)
        barLabel:SetCallback("OnClick", function(self)
            NEURON.NeuronBar:ChangeBar(self.bar)
            self.parent.parent.parent:SetStatusText("The Currently Selected Bar is: " .. name)
        end)
        barListFrame:AddChild(barLabel)
    end

end

function NeuronGUI:RefreshEditor()

    barListFrame:ReleaseChildren()
    NeuronGUI:PopulateBarList(barListFrame)

    if NEURON.CurrentBar then
        editorFrame:SetStatusText("The Currently Selected Bar is: " .. NEURON.CurrentBar.gdata.name)
    else
        editorFrame:SetStatusText("Welcome to the Neuron editor, please select a bar to begin")
    end

end






-----------------------------------------------------------------------------
--------------------------Interface Menu-------------------------------------
-----------------------------------------------------------------------------

--ACE GUI OPTION TABLE
NeuronGUI.interfaceOptions = {
    name = "Neuron",
    type = 'group',
    args = {
        moreoptions={
            name = L["Options"],
            type = "group",
            order = 0,
            args={
                BlizzardBar = {
                    order = 1,
                    name = L["Display the Blizzard Bar"],
                    desc = L["Shows / Hides the Default Blizzard Bar"],
                    type = "toggle",
                    set = function() NEURON:BlizzBar() end,
                    get = function() return NeuronGDB.mainbar end,
                    width = "full",
                },
                NeuronMinimapButton = {
                    order = 2,
                    name = L["Display Minimap Button"],
                    desc = L["Toggles the minimap button."],
                    type = "toggle",
                    set =  function() NEURON.NeuronMinimapIcon:ToggleIcon() end,
                    get = function() return not NeuronGDB.NeuronIcon.hide end,
                    width = "full"
                },
            },
        },

        changelog = {
            name = L["Changelog"],
            type = "group",
            order = 1000,
            args = {
                line1 = {
                    type = "description",
                    name = L["Changelog_Latest_Version"],
                },
            },
        },

        faq = {
            name = L["F.A.Q."],
            desc = L["Frequently Asked Questions"],
            type = "group",
            order = 1001,
            args = {

                line1 = {
                    type = "description",
                    name = L["FAQ_Intro"],
                },

                g1 = {
                    type = "group",
                    name = L["Bar Configuration"],
                    order = 1,
                    args = {

                        line1 = {
                            type = "description",
                            name = L["Bar_Configuration_FAQ"],
                            order = 1,
                        },

                        g1 = {
                            type = "group",
                            name = L["General Options"],
                            order = 1,
                            args = {
                                line1 = {
                                    type = "description",
                                    name = L["General_Bar_Configuration_Option_FAQ"] ,
                                    order = 1,
                                },
                            },
                        },

                        g2 = {
                            type = "group",
                            name = L["Bar States"],
                            order = 2,
                            args = {
                                line1 = {
                                    type = "description",
                                    name = L["Bar_State_Configuration_FAQ"],
                                    order = 1,
                                },
                            },
                        },

                        g3 = {
                            type = "group",
                            name = L["Spell Target Options"],
                            order = 3,
                            args = {
                                line1 = {
                                    type = "description",
                                    name = L["Spell_Target_Options_FAQ"],
                                    order = 1,
                                },
                            },
                        },
                    },
                },

                g2 = {
                    type = "group",
                    name = L["Flyout"],
                    order = 3,
                    args = {
                        line1a = {
                            type = "description",
                            name = L["Flyout_FAQ"],
                            order = 1,
                        },
                    },
                },

            },
        },
    },
}