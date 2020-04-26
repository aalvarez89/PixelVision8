function SettingsTool:CreateControllerPanel()

    self.buttonSpriteMap = {
        Up = {spriteData = dpadup, x = 96, y = 72},
        Down = {spriteData = dpaddown, x = 96, y = 72},
        Left = {spriteData = dpadleft, x = 96, y = 72},
        Right = {spriteData = dpadright, x = 96, y = 72},
        A = {spriteData = actionbtndown, x = 154, y = 82},
        B = {spriteData = actionbtndown, x = 170, y = 82},
        Select = {spriteData = startbtndown, x = 124, y = 90},
        Start = {spriteData = startbtndown, x = 136, y = 90}
    }

    self.totalButtons = #ButtonTypes
    self.usedKeysInvalid = true
    self.blinkTime = 0
    self.blinkDelay = .1
    self.blinkActive = false

    self.playerButtonGroupData = editorUI:CreateToggleGroup(true)
    self.playerButtonGroupData.onAction = function(value) self:TriggerPlayerSelection(value) end 

    editorUI:ToggleGroupButton(self.playerButtonGroupData, {x = 208, y = 24, w = 8, h = 8}, "radiobutton", "Select player 1's controller map.")
    editorUI:ToggleGroupButton(self.playerButtonGroupData, {x = 208, y = 32, w = 8, h = 8}, "radiobutton", "Select player 2's controller map.")

    self.inputButtonGroupData = editorUI:CreateToggleGroup(true)
    self.inputButtonGroupData.onAction = 
    function(value) 
        if(value == 2 and ControllerConnected(self.selectedPlayerID-1) == false) then 
            pixelVisionOS:ShowMessageModal("No Controller", "It doesn't look like Player " .. self.selectedPlayerID .. "'s controller was detected.", 160, false, 
            function()
                self:OnTriggerInputSelection(value)
            end
        )
        else
            self:OnTriggerInputSelection(value)
        end
    end

    editorUI:ToggleGroupButton(self.inputButtonGroupData, {x = 96, y = 152, w = 8, h = 8}, "radiobutton", "This is radio button 1.")
    editorUI:ToggleGroupButton(self.inputButtonGroupData, {x = 144, y = 152, w = 8, h = 8}, "radiobutton", "This is radio button 2.")


    self.inputFields = {
        editorUI:CreateInputField({x = 56, y = 80, w = 8}, "", "Up"),
        editorUI:CreateInputField({x = 56, y = 96, w = 8}, "", "Down"),
        editorUI:CreateInputField({x = 56, y = 112, w = 8}, "", "Left"),
        editorUI:CreateInputField({x = 56, y = 128, w = 8}, "", "Right"),
        editorUI:CreateInputField({x = 120, y = 120, w = 8}, "", "Select"),
        editorUI:CreateInputField({x = 144, y = 120, w = 8}, "", "Start"),
        editorUI:CreateInputField({x = 184, y = 120, w = 8}, "", "A"),
        editorUI:CreateInputField({x = 208, y = 120, w = 8}, "", "B")
    }

    -- -- TODO need to create a map for player 1 & 2 controller

    -- self.usedControllerButtons = {}

    for i = 1, #self.inputFields do
        
        local field = self.inputFields[i]
        field.type = field.toolTip

        field.toolTip = "Remap the " .. field.type .. " key."
        field.captureInput = function()

            self.showBlinker = true

            local usedKeys = self.selectedInputID == 1 and self:GetUsedKeys() or self:GetUsedButtons()

            local inputValue = self.selectedInputID == 1 and self:GetUsedKeys() or self:OnCaptureKey()
            
            -- TODO need to see what mode we are in and pass the correct used keys
            -- local usedKeys = usedControllerKeys

            return self:ValidateInput(inputValue, field, usedKeys)

        end

        field.onAction = function(value)
 
            self.showBlinker = false
            local inputLabel = self.selectedInputID == 1 and "Key" and "Buttons"

            self:RemapKey("Player" ..tostring(self.selectedPlayerID) .. field.type .. inputLabel, self:ConvertKeyToKeyCode(value))
            

            self.usedKeysInvalid = true


            -- self:DrawInputSprite(field.type)

            -- InvalidateData()

        end

    end

    editorUI:SelectToggleButton(self.inputButtonGroupData, 1)

    editorUI:SelectToggleButton(self.playerButtonGroupData, 1)

    pixelVisionOS:RegisterUI({name = "UpdateControllerPanel"}, "UpdateControllerPanel", self)

end

function SettingsTool:DrawInputSprite(type)

    local data = self.buttonSpriteMap[type]

    if(data ~= nil) then
        local spriteData = data.spriteData
        DrawSprites(spriteData.spriteIDs, data.x, data.y, spriteData.width)
    end

    if(type == "Select" or type == "Start") then
        DrawSprites(startinputon.spriteIDs, type == "Select" and 126 or 138, 99, startinputon.width)
    else
        self:DrawBlinkSprite()
    end

end

function SettingsTool:UpdateControllerPanel()

    editorUI:UpdateToggleGroup(self.playerButtonGroupData)
    editorUI:UpdateToggleGroup(self.inputButtonGroupData)

    -- Check to see if the input fields need to be refreshed
    if(self.invalidInputFields ~= false) then
        
        if(self.selectedInputID == 1) then 
            local inputMap = _G["player"..self.selectedPlayerID.."Keys"]
            
            for i = 1, #inputMap do
                local field = self.inputFields[i]
                editorUI:ChangeInputField(field, self:ConvertKeyCodeToChar(tonumber(ReadMetadata(inputMap[i]))), false)
            end

        else

            for i = 1, #ButtonCodes do
                local field = self.inputFields[i]
                editorUI:ChangeInputField(field, ButtonCodes[i].char, false)
            end

        end

        self.invalidInputFields = false
    end

    for i = 1, #self.inputFields do
        editorUI:UpdateInputField(self.inputFields[i])
    end

    -- Loop through all of the inputs and see if a controller button should be pressed

    -- See if we are in keyboard mode
    if(self.selectedInputID == 1) then

        -- Loop through each of the input fields
        for i = 1, #self.inputFields do

            -- Get the field and its value
            local field = self.inputFields[i]
            local value = field.text

            -- Test if the input field's map value is down
            if(Key(self:ConvertKeyToKeyCode(value), InputState.Down)) then

            -- Update the sprite
            self:DrawInputSprite(field.type)

            end

        end

    -- If we are not in keyboard mode, it will switch to the controller mode
    else

        -- Loop through each of the buttons
        for i = 1, self.totalButtons do

            -- Go through each button and see if it is down for the selected player
            if(Button(i - 1, InputState.Down, self.selectedPlayerID - 1)) then

            -- Draw the correct sprite
            self:DrawInputSprite(ButtonTypes[i])

            end

        end

    end

    if(self.showBlinker == true) then

        self.blinkTime = self.blinkTime + editorUI.timeDelta

        if(self.blinkTime > self.blinkDelay) then
            self.blinkTime = 0
            self.blinkActive = not self.blinkActive
        end

        if(self.blinkActive) then
            self:DrawBlinkSprite()
        end

    end
    
end

function SettingsTool:DrawBlinkSprite()
  DrawSprites(inputbuttonon.spriteIDs, 154, 62, inputbuttonon.width)
end

-- function SettingsTool:OnPlayerSelection(value)

--   if(self.invalid == true) then

--     pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have not saved your changes for this controller. Do you want to save them before switching to a different player?", 160, true,
--       function()
--         if(pixelVisionOS.messageModal.selectionValue == true) then
--           -- Save changes
--           self:OnSave()

--         end

--         -- Quit the tool
--         self:TriggerPlayerSelection(value)

--       end
--     )

--   else
    -- Quit the tool
    -- self:TriggerPlayerSelection(value)
--   end

-- end

function SettingsTool:TriggerPlayerSelection(value)
    self.selectedPlayerID = value

    -- local message = "Player " .. value .. " was selected."

    -- Display the correct highlight state for the player label
    for i = 1, 2 do

        local spriteData = _G["player"..i..(i == value and "selected" or "up")]

        DrawSprites(spriteData.spriteIDs, 27, 2 + i, spriteData.width, false, false, DrawMode.Tile)
    end

    -- Update the controller number
    local spriteData = _G["controller"..value]

    DrawSprites(spriteData.spriteIDs, 16, 7, spriteData.width, false, false, DrawMode.Tile)

    -- Reset the input selection
    editorUI:SelectToggleButton(self.inputButtonGroupData, self.selectedInputID, false)

    -- Manually force the input selection to redraw all the input fields
    self:OnTriggerInputSelection(self.selectedInputID)

end

-- function SettingsTool:OnInputSelection(value)

-- --   if(self.invalid == true) then

-- --     pixelVisionOS:ShowMessageModal("Unsaved Changes", "You have not saved your changes for this controller. Do you want to save them before switching to a different input mode?", 160, true,
-- --       function()
-- --         if(pixelVisionOS.messageModal.selectionValue == true) then
-- --           -- Save changes
-- --           OnSave()

-- --         end

-- --         -- TODO looks like there may be a race condition when switching between players here and selection is not displayed correctly from tilemap cache

-- --         -- Quit the tool
-- --         self:OnTriggerInputSelection(value)

-- --       end
-- --     )

-- --   else
--     -- Quit the tool
--     self:OnTriggerInputSelection(value)
-- --   end

-- end

function SettingsTool:OnTriggerInputSelection(value)

    -- make sure the controller is connected first
    if(value == 2 and ControllerConnected(self.selectedPlayerID-1) == false) then 
        pixelVisionOS:ShowMessageModal("No Controller", "It doesn't look like Player " .. self.selectedPlayerID .. "'s controller was detected.", 160, false, 
        function()
            self:TriggerInputSelection(value)
        end
    )
    else
        self:TriggerInputSelection(value)
    end

end

function SettingsTool:TriggerInputSelection(value)

    self.selectedInputID = value

    local pos = {13, 19}
    -- Display the correct highlight state for the player label
    for i = 1, 2 do

    local spriteName = i == 1 and "keyboard" or "controller"
    local spriteData = _G[spriteName..(i == value and "selected" or "up")]

    DrawSprites(spriteData.spriteIDs, pos[i], 19, spriteData.width, false, false, DrawMode.Tile)
    end

    for i = 1, #self.inputFields do
        editorUI:Enable(self.inputFields[i], value == 1)
    end

    --   local message = "Input mode " .. value .. " was selected."
    self:InvalidateInputFields()


end

function SettingsTool:ResetControllers()

    for key, value in pairs(DefaultKeys) do
        print("revert", key, value)
    end

    self:InvalidateInputFields()
end

function SettingsTool:InvalidateInputFields()
    self.invalidInputFields = true
end

function SettingsTool:GetUsedKeys()

  if(self.usedKeysInvalid ~= false) then

    

    self.usedControllerKeys = {}

    -- Player 1 Keys
    for i = 1, #player1Keys do

      local key = player1Keys[i]

      self.usedControllerKeys[key] = self:ConvertKeyCodeToChar(tonumber(ReadMetadata(key)))

    end

    -- Player 2 Keys
    for i = 1, #player2Keys do

      local key = player2Keys[i]

      self.usedControllerKeys[key] = self:ConvertKeyCodeToChar(tonumber(ReadMetadata(key)))

    end

    self.usedKeysInvalid = false

    print("rebuild used keys", self.selectedInputID, dump(self.usedControllerKeys))

  end

  return self.usedControllerKeys

end

function SettingsTool:GetUsedButtons()

    if(self.usedButtonsInvalid ~= false) then

        self.usedControllerButtons = {}

        self.usedButtonsInvalid = false

    end

end
