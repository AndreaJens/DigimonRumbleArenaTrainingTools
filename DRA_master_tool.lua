  -- global variables
  local trainingOverlayVisible = false
  local inputTable={}
  local buttonPressedAtLastFrame = {}
  local trainingOptionIndex = 1
  local optionIndexes = {1, 1, 4, 2}
  local actionStrings = {"None", "Block", "Crouch Block", "Special1", "Special2", "Jab", "Sweep", "Launcher", "Super"}
  local movementStrings = {"None", "Crouch", "Walk Right", "Walk Left", "Dash Right", "Dash Left", "Hop", "Jump", "High Jump"}
  local healthStrings = {"Normal", "Infinite P2", "Infinite P1", "Infinite P1/P2"}
  local timerStrings = {"Normal", "Infinite"}
  local optionValueslists = {actionStrings, movementStrings, healthStrings, timerStrings}
  local labels = {"Dummy Action", "Dummy Movement", "Health Bars", "Timer"}
  local labelsSize = table.getn(labels)
  local actionTimer = 0
  local delayTimer = 0
  local movementTimer = 0
  local delayMovementTimer = 0
  local actionIndex = 0
  local optionSizes = {table.getn(actionStrings), table.getn(movementStrings), table.getn(healthStrings), table.getn(timerStrings)}
  local activeColorLabel = 0xffaaaa00
  local activeColorItem = 0xffffffff
  local inactiveColorLabel = 0xff444400
  local inactiveColorItem  = 0xff444444
  
  -- draw GUI
  function drawTrainingGui()
	gui.drawBox(0, 0, 960, 480, null, 0xaaaaaaaa)
    gui.text(240, 20, 'Digimon Rumble Arena - Training Helper', 0xffaaaa00)
	gui.text(50, 40, 'Scroll between options with L2/R2. Scroll between values with L1/R1.', 0xffaaaa00)
	for index=1,labelsSize,1 do
		color1 = inactiveColorLabel
		color2 = inactiveColorItem
		if index == trainingOptionIndex then
			color1 = activeColorLabel
			color2 = activeColorItem
		end
		gui.text(50, 40 + index * 30, labels[index], color1)
		gui.text(200, 40 + index * 30, optionValueslists[index][optionIndexes[index]], color2)
	end
  end
  
  -- handle new action (reset variables)
  function handleNewAction()
	actionIndex = 0
	delayTimer = 0
	actionTimer = 0
	movementTimer = 0
	delayMovementTimer = 0
  end
  
  -- handle menu exit (sets all new values in memory)
  function handleSelection()
	handleNewAction()
	handleHealthBars()
	handleTimer()
  end
  
  -- update GUI and selection from Menu
  function handleTrainingGui(newInputTable, lastFrameInputTable)
	if ((not newInputTable.L3) and (lastFrameInputTable.L3)) then
		trainingOverlayVisible = not trainingOverlayVisible
		if (not trainingOverlayVisible) then
			handleSelection()
		end
	end
	
	if trainingOverlayVisible then
		if ((not newInputTable.R2) and (lastFrameInputTable.R2)) then
			trainingOptionIndex = trainingOptionIndex + 1
			if(trainingOptionIndex > labelsSize) then
				trainingOptionIndex = 1
			end
		elseif ((not newInputTable.L2) and (lastFrameInputTable.L2)) then
			trainingOptionIndex = trainingOptionIndex - 1
			if(trainingOptionIndex < 1) then
				trainingOptionIndex = labelsSize
			end
		end
		if ((not newInputTable.R1) and (lastFrameInputTable.R1)) then
			optionIndexes[trainingOptionIndex] = optionIndexes[trainingOptionIndex] + 1
			if(optionIndexes[trainingOptionIndex] > optionSizes[trainingOptionIndex]) then
				optionIndexes[trainingOptionIndex] = 1
			end
			if (trainingOptionIndex <= 2) then
				handleNewAction()
			end
		elseif ((not newInputTable.L1) and (lastFrameInputTable.L1)) then
			optionIndexes[trainingOptionIndex] = optionIndexes[trainingOptionIndex] - 1
			if(optionIndexes[trainingOptionIndex] < 1) then
				optionIndexes[trainingOptionIndex] = optionSizes[trainingOptionIndex]
			end
			if (trainingOptionIndex <= 2) then
				handleNewAction()
			end
		end
	end
  end
  
  -- process action which requires one single input
  function singleActionSet(inputTableOn, inputTableOff)
	if actionTimer < 3 then
		joypad.set(inputTableOn, 2)
		delayTimer = 0
	elseif actionTimer == 4 then
		joypad.set(inputTableOff, 2)
	elseif actionTimer > 3 then
		delayTimer = delayTimer + 1
	end
	if delayTimer > 60 then
		delayTimer = 0
		actionTimer = 0
	end
  end
  
  -- process jump
  function jumpSet(frameOfPressure)
	if movementTimer < frameOfPressure then
		joypad.set({Cross=true}, 2)
		delayMovementTimer = 0
	elseif movementTimer == frameOfPressure then
		joypad.set({Cross=false}, 2)
	elseif movementTimer > frameOfPressure then
		delayMovementTimer = delayMovementTimer + 1
	end
	if delayMovementTimer > 50 then
		delayMovementTimer = 0
		movementTimer = 0
	end
  end
  
  -- process dash
  function dashRight()
	if movementTimer < 4 then
		joypad.set({Right=true}, 2)
		delayMovementTimer = 0
	elseif movementTimer < 6 then
		joypad.set({Right=false}, 2)
	elseif movementTimer < 10 then
		joypad.set({Right=true}, 2)
	elseif movementTimer > 10 then
		delayMovementTimer = delayMovementTimer + 1
	end
	if delayMovementTimer > 50 then
		delayMovementTimer = 0
		movementTimer = 0
	end
  end
  
  function dashLeft()
	if movementTimer < 4 then
		joypad.set({Left=true}, 2)
		delayMovementTimer = 0
	elseif movementTimer < 6 then
		joypad.set({Left=false}, 2)
	elseif movementTimer < 10 then
		joypad.set({Left=true}, 2)
	elseif movementTimer > 10 then
		delayMovementTimer = delayMovementTimer + 1
	end
	if delayMovementTimer > 50 then
		delayMovementTimer = 0
		movementTimer = 0
	end
  end
  
  -- process sweep
  function performSweep()
	if actionTimer < 3 then
		joypad.set({Down=true}, 2)
		delayTimer = 0
	elseif actionTimer < 9 then
		joypad.set({Down=true, Square=true}, 2)
	elseif actionTimer == 10 then
		joypad.set({Down=false, Square=false}, 2)
	elseif actionTimer > 10 then
		delayTimer = delayTimer + 1
	end
	if delayTimer > 50 then
		delayTimer = 0
		actionTimer = 0
	end
  end
  
  -- process up jab
  function performLauncher()
	if actionTimer == 1 then
		joypad.set({Up=true}, 2)
		delayTimer = 0
	elseif actionTimer == 2 then
		joypad.set({Up=true, Square=true}, 2)
	elseif actionTimer == 10 then
		joypad.set({Up=false, Square=false}, 2)
	elseif actionTimer > 10 then
		delayTimer = delayTimer + 1
	end
	if delayTimer > 50 then
		delayTimer = 0
		actionTimer = 0
	end
  end  
  
   -- process jab 2 combo
  function performJab2Combo()
	if actionTimer < 13 then
		joypad.set({Square=true}, 2)
		delayTimer = 0
	elseif actionTimer < 25 then
		joypad.set({Square=false}, 2)
	elseif actionTimer < 30 then
		joypad.set({Square=true}, 2)
	elseif actionTimer < 32 then
		joypad.set({Square=false}, 2)
	else
		delayTimer = delayTimer + 1
	end
	if delayTimer > 50 then
		delayTimer = 0
		actionTimer = 0
	end
  end
  
   -- process jab 3 combo
  function performJab3Combo()
	if actionTimer < 13 then
		joypad.set({Square=true}, 2)
		delayTimer = 0
	elseif actionTimer < 25 then
		joypad.set({Square=false}, 2)
	elseif actionTimer < 30 then
		joypad.set({Square=true}, 2)
	elseif actionTimer < 38 then
		joypad.set({Square=false}, 2)
	elseif actionTimer < 50 then
		joypad.set({Square=true}, 2)
	else
		delayTimer = delayTimer + 1
	end
	if delayTimer > 50 then
		delayTimer = 0
		actionTimer = 0
	end
  end
  
  -- handle dummy actions
  function handleDummyMovement()
	movementTimer = movementTimer + 1
	if movementStrings[optionIndexes[2]] == "Walk Right" then
		joypad.set({Right=true}, 2)
	elseif movementStrings[optionIndexes[2]] == "Walk Left" then
		joypad.set({Left=true}, 2)
	elseif movementStrings[optionIndexes[2]] == "Dash Right" then
		dashRight()
	elseif movementStrings[optionIndexes[2]] == "Dash Left" then
		dashLeft()
	elseif movementStrings[optionIndexes[2]] == "Crouch" then
		joypad.set({Down=true}, 2)
	elseif movementStrings[optionIndexes[2]] == "Hop" then
		jumpSet(5)
	elseif movementStrings[optionIndexes[2]] == "Jump" then
		jumpSet(15)
	elseif movementStrings[optionIndexes[2]] == "High Jump" then
		jumpSet(35)
	end
  end
  
  -- handle dummy actions
  function handleDummy()
    actionTimer = actionTimer + 1
	if (delayTimer > 0 or actionStrings[optionIndexes[1]] == "None") then
		handleDummyMovement()
	else
		movementTimer = 0
	end
	if actionStrings[optionIndexes[1]] == "Block" then
		joypad.set({L1=true}, 2)
	elseif actionStrings[optionIndexes[1]] == "Crouch Block" then
		joypad.set({L1=true, Down=true}, 2)
	elseif actionStrings[optionIndexes[1]] == "Special1" then
		singleActionSet({Circle=true}, {Circle=false})
	elseif actionStrings[optionIndexes[1]] == "Special2" then
		singleActionSet({Triangle=true}, {Triangle=false})
	elseif actionStrings[optionIndexes[1]] == "Jab" then
		singleActionSet({Square=true}, {Square=false})
	elseif actionStrings[optionIndexes[1]] == "Double Jab" then
		performJab2Combo()
	elseif actionStrings[optionIndexes[1]] == "Triple Jab" then
		performJab3Combo()
	elseif actionStrings[optionIndexes[1]] == "Sweep" then
		performSweep()
	elseif actionStrings[optionIndexes[1]] == "Launcher" then
		performLauncher()
	elseif actionStrings[optionIndexes[1]] == "Super" then
		singleActionSet({R1=true}, {R1=false})
	end
  end
  
  -- handle health bars
  function handleHealthBars()
	if healthStrings[optionIndexes[3]] ==  "Infinite P1" then
		memory.write_u16_le(0x7F36C, 0x0800)
		memory.write_u16_le(0x7F36E, 0x3121)
		memory.write_u16_le(0x7F3A0, 0x0005)
		memory.write_u16_le(0x7F3A2, 0x1020)
	elseif healthStrings[optionIndexes[3]] == "Infinite P2" then
		memory.write_u16_le(0x7F36C, 0x0800)
		memory.write_u16_le(0x7F36E, 0x3121)
		memory.write_u16_le(0x7F3A0, 0x0005)
		memory.write_u16_le(0x7F3A2, 0x1420)
	elseif healthStrings[optionIndexes[3]] == "Infinite P1/P2" then
		memory.write_u16_le(0x7F36C, 0x0)
		memory.write_u16_le(0x7F36E, 0x0)
		memory.write_u16_le(0x7F3A0, 0x0005)
		memory.write_u16_le(0x7F3A2, 0x1000)
	else
		memory.write_u16_le(0x7F36C, 0x0)
		memory.write_u16_le(0x7F36E, 0x0)
		memory.write_u16_le(0x7F3A0, 0x0)
		memory.write_u16_le(0x7F3A2, 0x0)
	end
  end
  
  -- handle timer
  function handleTimer()
	if timerStrings[optionIndexes[4]] ==  "Infinite" then
		memory.write_u16_le(0x717BA, 0x2400)
	else
		memory.write_u16_le(0x717BA, 0xAE22)
	end	
  end
  
  -- draw everything
  function handleGeneralGraphics()
	if trainingOverlayVisible then
		drawTrainingGui()
    end
  end
  
  -- main routine
  while true do
   inputTable=joypad.get(1)
   handleTrainingGui(inputTable, buttonPressedAtLastFrame)
   if not trainingOverlayVisible then
	handleDummy()
   end
   buttonPressedAtLastFrame = inputTable;
   handleGeneralGraphics()
   emu.frameadvance()
  end