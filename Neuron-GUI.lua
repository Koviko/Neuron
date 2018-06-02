--Neuron GUI, a World of Warcraft® user interface addon.

local addonName = ...

local NEURON = Neuron

NEURON.NeuronGUI = Neuron:NewModule("GUI", "AceEvent-3.0", "AceHook-3.0")
local NeuronGUI = NEURON.NeuronGUI

local L = LibStub("AceLocale-3.0"):GetLocale("Neuron")
local AceGUI = LibStub("AceGUI-3.0")


---Class level handles for frame elements that need to be refreshed often
local editorFrame = {} --outer frame for our editor window
local barListFrame = {} --the frame containing just the bar list
local renameBox = {} --the rename bar Box
local barEditOptionsContainer = {} --The container that houses the add/remove bar buttons


-----------------------------------------------------------------------------
--------------------------INIT FUNCTIONS-------------------------------------
-----------------------------------------------------------------------------

--- **OnInitialize**, which is called directly after the addon is fully loaded.
--- do init tasks here, like loading the Saved Variables
--- or setting up slash commands.
function NeuronGUI:OnInitialize()

    NeuronGUI:LoadInterfaceOptions()

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

-----------------------------------------------------------------------------
--------------------------Main Window----------------------------------------
-----------------------------------------------------------------------------


function NeuronGUI:ToggleEditor(hideorshow)
    if hideorshow == "show" then
        NeuronGUI:RefreshEditor()
        editorFrame:Show()
    elseif hideorshow == "hide" then
        editorFrame:Hide()
    end
end

function NeuronGUI:RefreshEditor()

    if NEURON.CurrentBar then
        renameBox:SetText(NEURON.CurrentBar.gdata.name)
        editorFrame:SetStatusText("The currently selected bar is: " .. NEURON.CurrentBar.gdata.name)
    else
        renameBox:SetText("")
        editorFrame:SetStatusText("Please select a bar from the right to begin")
    end

    barListFrame:ReleaseChildren()
    NeuronGUI:PopulateBarList(barListFrame)

    barEditOptionsContainer:ReleaseChildren()
    NeuronGUI:PopulateEditOptions(barEditOptionsContainer)
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

    ---Container for the Rename box in the right column
    local barRenameContainer = AceGUI:Create("SimpleGroup")
    barRenameContainer:SetHeight(20)
    barRenameContainer:SetLayout("Flow")
    rightContainer:AddChild(barRenameContainer)
    NeuronGUI:PopulateRenameBar(barRenameContainer) --this is to make the Rename/Create/Delete Bars group


    ---Container for the Bar List scroll frame
    local barListContainer = AceGUI:Create("InlineGroup")
    barListContainer:SetTitle("Select an available bar  ")
    barListContainer:SetHeight(480)
    barListContainer:SetLayout("Fill")
    rightContainer:AddChild(barListContainer)


    ---Scroll frame that will contain the Bar List
    barListFrame = AceGUI:Create("ScrollFrame")
    barListFrame:SetLayout("Flow")
    barListContainer:AddChild(barListFrame)
    NeuronGUI:PopulateBarList(barListFrame) --fill the bar list frame with the actual list of the bars

    ---Container for the Add/Delete bars buttons
    barEditOptionsContainer = AceGUI:Create("SimpleGroup")
    barEditOptionsContainer:SetHeight(110)
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

function NeuronGUI:PopulateBarList()

    for _, bar in pairs(NEURON.BARIndex) do
        local barLabel = AceGUI:Create("InteractiveLabel")
        barLabel:SetText(bar.gdata.name)
        barLabel:SetFont("Fonts\\FRIZQT__.TTF", 18)
        barLabel:SetFullWidth(true)
        barLabel:SetHighlight("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        if NEURON.CurrentBar == bar then
            barLabel:SetColor(1,.9,0)
        end
        barLabel.bar = bar
        barLabel:SetCallback("OnEnter", function(self) NEURON.NeuronBar:OnEnter(self.bar) end)
        barLabel:SetCallback("OnLeave", function(self) NEURON.NeuronBar:OnLeave(self.bar) end)
        barLabel:SetCallback("OnClick", function(self)
            NEURON.NeuronBar:ChangeBar(self.bar)
            NeuronGUI:RefreshEditor()
            self:SetColor(1,.9,0)
        end)
        barListFrame:AddChild(barLabel)
    end

end

function NeuronGUI:PopulateEditOptions(container)

    local barTypeDropdown = AceGUI:Create("Dropdown")
    barTypeDropdown:SetText("Select a Bar Type")
    container:AddChild(barTypeDropdown)

    local newBarButton = AceGUI:Create("Button")
    newBarButton:SetText("Create New Bar")
    newBarButton:SetDisabled(true) --we want to disable it until they chose a bar type in the dropdown
    container:AddChild(newBarButton)

    local deleteBarButton = AceGUI:Create("Button")
    deleteBarButton:SetText("Delete Current Bar")
    if not NEURON.CurrentBar then
        deleteBarButton:SetDisabled(true)
    end
    container:AddChild(deleteBarButton)


    ---populate the dropdown menu with available bar types
    local barTypes = {}

    for class, info in pairs(NEURON.RegisteredBarData) do
        if (info.barCreateMore or NeuronGUI:MissingBarCheck(class)) then
            barTypes[class] = info.barLabel
        end
    end

    local selectedBarType

    barTypeDropdown:SetList(barTypes) --assign the bar type table to the dropdown menu
    barTypeDropdown:SetCallback("OnValueChanged", function(self, key) selectedBarType = key; newBarButton:SetDisabled(false) end)



end

function NeuronGUI:PopulateRenameBar(container)

    renameBox = AceGUI:Create("EditBox")
    if NEURON.CurrentBar then
        renameBox:SetText(NEURON.CurrentBar.gdata.name)
    end
    renameBox:SetLabel("Rename selected bar")

    renameBox:SetCallback("OnEnterPressed", function(self) NeuronGUI:updateBarName(self) end)

    container:AddChild(renameBox)

end

--TODO: rework this Missing Bar Check code to be smarter
function NeuronGUI:MissingBarCheck(class)
    local allow = true
    if (class == "extrabar" and NeuronCDB.xbars[1])
            or (class == "zoneabilitybar" and NeuronCDB.zoneabilitybars[1])
            or (class == "pet" and NeuronCDB.petbars[1])
            or (class == "bag" and NeuronCDB.bagbars[1])
            or (class == "menu" and NeuronCDB.menubars[1]) then
        allow = false
    end
    return allow
end

function NeuronGUI:updateBarName(editBox)

    local bar = NEURON.CurrentBar

    if (bar) then
        bar.gdata.name = editBox:GetText()
        bar.text:SetText(bar.gdata.name)

        NEURON.NeuronBar:SaveData(bar)

        editBox:ClearFocus()
        NeuronGUI:RefreshEditor()
    end
end

-----------------------------------------------------------------------------
--------------------------Inner WIndow---------------------------------------
-----------------------------------------------------------------------------


function NeuronGUI:SelectTab(tabContainer, event, tab)

    tabContainer:ReleaseChildren()

    if tab == "tab1" then
        NeuronGUI:BarEditWindow(tabContainer)
    elseif tab == "tab2" then
        NeuronGUI:ButtonEditWindow(tabContainer)
    end

end


function NeuronGUI:BarEditWindow(tabContainer)

    local settingContainer = AceGUI:Create("SimpleGroup")
    settingContainer:SetFullWidth(true)
    settingContainer:SetLayout("Flow")
    tabContainer:AddChild(settingContainer)

    local desc = AceGUI:Create("Label")
    desc:SetText("This is Tab 1")
    desc:SetFullWidth(true)
    settingContainer:AddChild(desc)

end


function NeuronGUI:ButtonEditWindow(tabContainer)
    local settingContainer = AceGUI:Create("SimpleGroup")
    settingContainer:SetFullWidth(true)
    settingContainer:SetLayout("Flow")
    tabContainer:AddChild(settingContainer)

    local desc = AceGUI:Create("Label")
    desc:SetText("This is Tab 2")
    desc:SetFullWidth(true)
    settingContainer:AddChild(desc)
end








-----------------------------------------------------------------------------
--------------------------Interface Menu-------------------------------------
-----------------------------------------------------------------------------

---This loads the Neuron interface panel
function NeuronGUI:LoadInterfaceOptions()
    --ACE GUI OPTION TABLE
    local interfaceOptions = {
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

    LibStub("AceConfigRegistry-3.0"):ValidateOptionsTable(interfaceOptions, addonName)
    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, interfaceOptions)
    interfaceOptions.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(NEURON.db)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addonName)
end
