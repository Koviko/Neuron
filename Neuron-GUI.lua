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
    NeuronGUI.GUILoaded = true

    editorFrame:DoLayout() ---we need to keep this here to recomupute the layout, as it doesn't get it right the first time

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


function NeuronGUI:ToggleEditor(hideorshow)
    if hideorshow == "show" then
        editorFrame:Show()
    elseif hideorshow == "hide" then
        editorFrame:Hide()
    end
end


function NeuronGUI:CreateBarEditor()


    ---Outer Window
    editorFrame = AceGUI:Create("Frame")
    editorFrame:SetTitle("Neuron Editor")
    editorFrame:SetWidth("1000")
    editorFrame:SetHeight("700")
    editorFrame:EnableResize(false)
    if NEURON.CurrentBar then
        editorFrame:SetStatusText("The Currently Selected Bar is: " .. NEURON.CurrentBar.gdata.name)
    else
        editorFrame:SetStatusText("Welcome to the Neuron editor, please select a bar to begin")
    end
    editorFrame:SetCallback("OnClose", function() NeuronGUI:ToggleEditor("hide") end)
    editorFrame:SetLayout("Flow")


    ---Container for the Right Column
    local rightContainer = AceGUI:Create("SimpleGroup")
    rightContainer:SetRelativeWidth(.20)
    rightContainer:SetFullHeight(true)
    rightContainer:SetLayout("Flow")
    editorFrame:AddChild(rightContainer)


    ---Container for the Bar List scroll frame
    local barListContainer = AceGUI:Create("InlineGroup")
    --barListContainer:SetFullWidth(true)
    barListContainer:SetHeight(507)
    barListContainer:SetLayout("Fill")
    rightContainer:AddChild(barListContainer)


    ---Scroll frame that will contain the Bar List
    barListFrame = AceGUI:Create("ScrollFrame")
    barListFrame:SetLayout("Flow")
    barListContainer:AddChild(barListFrame)
    NeuronGUI:PopulateBarList(barListFrame) --fill the bar list frame with the actual list of the bars

    ---Container for the Bar List scroll frame
    local barEditOptionsContainer = AceGUI:Create("SimpleGroup")
    --barListContainer:SetFullWidth(true)
    barEditOptionsContainer:SetHeight(130)
    barEditOptionsContainer:SetLayout("Flow")
    rightContainer:AddChild(barEditOptionsContainer)
    NeuronGUI:PopulateEditOptions(barEditOptionsContainer) --this is to make the Rename/Create/Delete Bars group


    ---Container for the tab frame
    local tabFrameContainer = AceGUI:Create("SimpleGroup")
    tabFrameContainer:SetRelativeWidth(.80)
    tabFrameContainer:SetFullHeight(true)
    tabFrameContainer:SetLayout("Fill")
    editorFrame:AddChild(tabFrameContainer, rightContainer)

    ---Tab group that will contain all of our settings to configure
    local tabFrame = AceGUI:Create("TabGroup")
    tabFrame:SetLayout("Flow")
    tabFrame:SetTabs({{text="Bar Settings", value="tab1"}, {text="Button Settings", value="tab2"}})
    tabFrame:SetCallback("OnGroupSelected", function(self, event, tab) NeuronGUI:SelectTab(self, event, tab) end)
    tabFrame:SelectTab("tab1")

    tabFrameContainer:AddChild(tabFrame)

end

function NeuronGUI:SelectTab(tabContainer, event, tab)

    tabContainer:ReleaseChildren()

    if tab == "tab1" then
        NeuronGUI:BarEditor(tabContainer)
    elseif tab == "tab2" then
        NeuronGUI:ButtonEditor(tabContainer)
    end

end


function NeuronGUI:BarEditor(tabContainer)

    local settingContainer = AceGUI:Create("SimpleGroup")
    settingContainer:SetFullWidth(true)
    settingContainer:SetLayout("Flow")
    tabContainer:AddChild(settingContainer)

    local desc = AceGUI:Create("Label")
    desc:SetText("This is Tab 1")
    desc:SetFullWidth(true)
    settingContainer:AddChild(desc)

end


function NeuronGUI:ButtonEditor(tabContainer)
    local settingContainer = AceGUI:Create("SimpleGroup")
    settingContainer:SetFullWidth(true)
    settingContainer:SetLayout("Flow")
    tabContainer:AddChild(settingContainer)

    local desc = AceGUI:Create("Label")
    desc:SetText("This is Tab 2")
    desc:SetFullWidth(true)
    settingContainer:AddChild(desc)
end

function NeuronGUI:PopulateBarList()

    for _, bar in pairs(NEURON.BARIndex) do
        local barLabel = AceGUI:Create("InteractiveLabel")
        barLabel:SetText(bar.gdata.name)
        barLabel:SetFont("Fonts\\FRIZQT__.TTF", 18)
        barLabel:SetFullWidth(true)
        barLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        barLabel.bar = bar
        barLabel:SetCallback("OnEnter", function(self) NEURON.NeuronBar:OnEnter(self.bar) end)
        barLabel:SetCallback("OnLeave", function(self) NEURON.NeuronBar:OnLeave(self.bar) end)
        barLabel:SetCallback("OnClick", function(self)
            NEURON.NeuronBar:ChangeBar(self.bar)
            editorFrame:SetStatusText("The Currently Selected Bar is: " .. bar.gdata.name)
        end)
        barListFrame:AddChild(barLabel)
    end

end

function NeuronGUI:PopulateEditOptions(container)

    local renameBox = AceGUI:Create("EditBox")
    renameBox:SetLabel("Rename Selected Bar")
    container:AddChild(renameBox)

    local newBarButton = AceGUI:Create("Button")
    newBarButton:SetText("Create a New Bar")
    container:AddChild(newBarButton)

    local delBarButton = AceGUI:Create("Button")
    delBarButton:SetText("Delete Current Bar")
    container:AddChild(delBarButton)


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