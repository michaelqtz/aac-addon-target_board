local api = require("api")

local target_board_addon = {
    name = "Target Board",
    author = "Sheoix",
    version = "1.0",
    desc = "Auto-fill chat with preset /target text."
}

local targetBoardWnd = nil
local editPromptWnd = nil
local settings = nil


local function saveSettings()
    api.File:Write("target_board/settings.txt", settings)
end 

local function saveTargetsAndSettings()
    for i = 1, 10 do
        local textbox = targetBoardWnd["textbox"..i]
        -- api.Log:Info(targetBoardWnd)
        if textbox then
            settings.targets[i] = textbox:GetText()
            -- api.Log:Info("Saved target "..i..": "..settings.targets[i])
        end
    end
    saveSettings()
end

local function showPromptForEditing(i)
    editPromptWnd:SetTitle("Edit Target "..i)
    editPromptWnd:Show(true)
    editPromptWnd.editTextbox:ReleaseHandler("OnKeyDown")
    function editPromptWnd.editTextbox:OnKeyDown(arg)
        if arg == "enter" then 
            local newText = editPromptWnd.editTextbox:GetText()
            targetBoardWnd["textbox"..i]:SetText(newText)
            settings.targets[i] = newText
            saveTargetsAndSettings()
            editPromptWnd.editTextbox:SetText("")
            editPromptWnd:Show(false)
        end 
    end
    editPromptWnd.editTextbox:SetHandler("OnKeyDown", editPromptWnd.editTextbox.OnKeyDown)
end 

function OnLoad()
    api.Log:Info("[Target Board] loaded! Michael hopes you have an amazing day.")
    settings = api.File:Read("target_board/settings.txt")
    if settings == nil then
        settings = {}
        settings.targets = {}
        for i = 1, 10 do
            settings.targets[i] = ""
        end
        settings.x = 800
        settings.y = 800
        
        api.File:Write("target_board/settings.txt", settings)
    end

    

    targetBoardWnd = api.Interface:CreateEmptyWindow("TargetBoardFrame", "UIParent")
    targetBoardWnd:SetExtent(220, 350)
    targetBoardWnd:AddAnchor("TOPLEFT", "UIParent", settings.x, settings.y)
    -- targetBoardWnd:EnableDrag(true)

    editPromptWnd = api.Interface:CreateWindow("editPrompt", "Edit Target")
    editPromptWnd:SetExtent(300, 100)
    editPromptWnd:AddAnchor("CENTER", "UIParent", 0, 0)
    local editTextbox = W_CTRL.CreateEdit("editTextbox", editPromptWnd)
    editTextbox:SetExtent(280, 24)
    editTextbox:AddAnchor("TOPLEFT", editPromptWnd, 10, 60)
    editTextbox.style:SetFontSize(FONT_SIZE.LARGE)
    editPromptWnd:Show(false)
    editPromptWnd.editTextbox = editTextbox


    local bg = targetBoardWnd:CreateNinePartDrawable(TEXTURE_PATH.HUD, "background")
    bg:SetColor(ConvertColor(0),ConvertColor(0),ConvertColor(0),0.7)
    bg:SetTextureInfo("bg_quest")
    bg:AddAnchor("TOPLEFT", targetBoardWnd, 0, 0)
    bg:AddAnchor("BOTTOMRIGHT", targetBoardWnd, 0, 0)

    local title = targetBoardWnd:CreateChildWidget("label", "title", 0, true)
    title:SetExtent(220, 30)
    title:AddAnchor("TOPLEFT", targetBoardWnd, 0, 1)
    title:AddAnchor("TOPRIGHT", targetBoardWnd, 0, 31)
    title.style:SetFontSize(FONT_SIZE.XLARGE)
    title.style:SetAlign(ALIGN.CENTER)
    title:SetText("Target Board")

    local targetIcon = targetBoardWnd:CreateChildWidget("button", "targetIcon", 0, true)
    ApplyButtonSkin(
        targetIcon,
        {
            drawableType = "drawable",
            path = TEXTURE_PATH.HUD,
            coordsKey = "result"
        }
    )
    targetIcon:SetExtent(28, 28)
    targetIcon:AddAnchor("TOPLEFT", targetBoardWnd, 30, 2)
    targetIcon:Clickable(false)

    local targetIcon2 = targetBoardWnd:CreateChildWidget("button", "targetIcon2", 0, true)
    ApplyButtonSkin(
        targetIcon2,
        {
            drawableType = "drawable",
            path = TEXTURE_PATH.HUD,
            coordsKey = "result"
        }
    )
    targetIcon2:SetExtent(28, 28)
    targetIcon2:AddAnchor("TOPRIGHT", targetBoardWnd, -25, 2)
    targetIcon2:Clickable(false)
    
    for i = 1, 10 do
        local textbox = W_CTRL.CreateEdit("textbox"..i, targetBoardWnd)
        textbox:AddAnchor("TOPLEFT", targetBoardWnd, 15, 40 + (i - 1) * 30)
        textbox:AddAnchor("TOPRIGHT", targetBoardWnd, -35, 40 + (i - 1) * 30)
        textbox:SetExtent(170, 24)
        textbox:SetReadOnly(true)
        textbox.style:SetAlign(ALIGN.LEFT)
        ApplyTextColor(textbox, FONT_COLOR.DEFAULT)

        function textbox:OnClick()
            -- api.Log:Info("[Target Board] Prefilling chat -> /target " .. self:GetText())
            chatTabWindow[1]:GetChatEdit():SetFocus()
            chatTabWindow[1]:GetChatEdit():SetText("/target " .. self:GetText())
            chatTabWindow[1]:GetChatEdit():Show(true)
        end 
        textbox:SetHandler("OnClick", textbox.OnClick)


        local popupBtn = targetBoardWnd:CreateChildWidget("button", "popupBtn"..i, 0, true)
        -- popupBtn:Enable(true)
        popupBtn:AddAnchor("LEFT", textbox, "RIGHT", 2, 0)
        ApplyButtonSkin(popupBtn, BUTTON_CONTENTS.APPELLATION)
        popupBtn:SetExtent(20, 20)
        
        function popupBtn:OnClick()
            local text = targetBoardWnd["textbox"..i]:GetText()
            showPromptForEditing(i)
        end
        popupBtn:SetHandler("OnClick", popupBtn.OnClick)

        if settings.targets[i] then
            textbox:SetText(settings.targets[i])
        end

        targetBoardWnd["textbox"..i] = textbox
        targetBoardWnd["popupBtn"..i] = popupBtn
    end 
    
    
    function title:OnDragStart()
        if not api.Input:IsShiftKeyDown() then return end
        targetBoardWnd:StartMoving()
        api.Cursor:SetCursorImage(CURSOR_PATH.MOVE, 0, 0)
    end
    title:SetHandler("OnDragStart", title.OnDragStart)
    function title:OnDragStop()
        targetBoardWnd:StopMovingOrSizing()
        api.Cursor:ClearCursor()
        local x, y = targetBoardWnd:GetOffset()
        settings.x = x
        settings.y = y
        saveTargetsAndSettings()
    end
    title:SetHandler("OnDragStop", title.OnDragStop)
    title:EnableDrag(true)
    -- targetBoardWnd:Show(true)
    
end
function OnUnload()
    saveTargetsAndSettings()
    api.Interface:Free(targetBoardWnd)
    api.Interface:Free(editPromptWnd)
    targetBoardWnd = nil
    editPromptWnd = nil
end 

target_board_addon.OnLoad = OnLoad
target_board_addon.OnUnload = OnUnload

return target_board_addon

