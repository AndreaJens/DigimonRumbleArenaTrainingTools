    --[[Digimon Rumble Arena Training Mode Script v1.2
	A handy Bizhawk LUA script to add some training functions to the game.
	Code is ugly, but does what is supposed to. Feel free to improve it as you wish.
	The code is released under a MIT license.
	2020 - Andrea "Jens" Demetrio
  ]]--
  
  -- global variables
  local mainIndexes = {}
  mainIndexes["Action"] 	= 1
  mainIndexes["Movement"] 	= 2
  mainIndexes["HP"] 		= 4
  mainIndexes["Timer"] 		= 5
  mainIndexes["HUD"] 		= 6
  mainIndexes["AftDmg"]		= 3
  
  local trainingOverlayVisible = false
  local inputTable={}
  local buttonPressedAtLastFrame = {}
  
  local trainingOptionIndex = 1
  
  local optionIndexes = {}
  optionIndexes[mainIndexes["Action"]] 		= 1
  optionIndexes[mainIndexes["Movement"]] 	= 1
  optionIndexes[mainIndexes["HP"]] 			= 1
  optionIndexes[mainIndexes["Timer"]] 		= 1
  optionIndexes[mainIndexes["HUD"]] 		= 1
  optionIndexes[mainIndexes["AftDmg"]] 		= 2
  
  local actionStrings = {"None", "Block", "Crouch Block", "Special1", "Special2", "Jab", "Sweep", "Launcher", "Super"}
  local movementStrings = {"None", "Crouch", "Walk Towards", "Walk Away", "Dash Towards", "Dash Away", "Hop", "Jump", "High Jump"}
  local healthStrings = {"Normal", "Infinite P2", "Infinite P1", "Infinite P1/P2"}
  local timerStrings = {"Normal", "Infinite"}
  local yesnoString = {"Yes", "No"}
  local hpDigiValues = {"No", "Percentage", "Absolute Pixel Bar Size", "Scaled using Defence Value"}
  
  -- menu labels
  local labels = {}
  labels[mainIndexes["Action"]] 	= "Dummy Action"
  labels[mainIndexes["Movement"]] 	= "Dummy Movement"
  labels[mainIndexes["HP"]] 		= "Health Bars"
  labels[mainIndexes["Timer"]] 		= "Timer"
  labels[mainIndexes["HUD"]] 		= "Show HP/Digi"
  labels[mainIndexes["AftDmg"]] 	= "Act only after Damage"
  
  -- menu values
  local optionValueslists = {}
  optionValueslists[mainIndexes["Action"]] 		= actionStrings
  optionValueslists[mainIndexes["Movement"]] 	= movementStrings
  optionValueslists[mainIndexes["HP"]] 			= healthStrings
  optionValueslists[mainIndexes["Timer"]] 		= timerStrings
  optionValueslists[mainIndexes["HUD"]] 		= hpDigiValues
  optionValueslists[mainIndexes["AftDmg"]] 		= yesnoString
  
  -- menu sizes
  local optionSizes = {}
  optionSizes[mainIndexes["Action"]] 	= table.getn(actionStrings)
  optionSizes[mainIndexes["Movement"]] 	= table.getn(movementStrings)
  optionSizes[mainIndexes["HP"]] 		= table.getn(healthStrings)
  optionSizes[mainIndexes["Timer"]] 	= table.getn(timerStrings)
  optionSizes[mainIndexes["HUD"]] 		= table.getn(hpDigiValues)
  optionSizes[mainIndexes["AftDmg"]] 	= table.getn(yesnoString)
   
  local labelsSize = table.getn(labels)
  local actionTimer = 0
  local delayTimer = 0
  local movementTimer = 0
  local delayMovementTimer = 0
  local actionIndex = 0
  local activeColorLabel = 0xffaaaa00
  local activeColorItem = 0xffffffff
  local inactiveColorLabel = 0xff444400
  local inactiveColorItem  = 0xff444444
  local player1CharacterIndex = 0
  local player2CharacterIndex = 0
  local stageIndex = 0
  
  local player1HP = 0
  local player1HPLastFrame = 0
  local player2HP = 0
  local player2HPLastFrame = 0
  local defaultHPValue = 120
  local player1Digi = 0
  local player1DigiLastFrame = 0
  local player2Digi = 0
  local player2DigiLastFrame = 0
  local defaultDigiValue = 70
  
  local scorePlayer1Address = 0x05FBEC
  local scorePlayer2Address = 0x05FC04
  local player1Score = 0
  local player2Score = 0
  local player1ScoreLastFrame = 0
  local player2ScoreLastFrame = 0
  
  local actOnlyAfterDamage = false
  local isPerformingAfterDamageAction = false
  local afterDamageActionTimer = 0
  
  local player1IsEvo = false
  local player2IsEvo = false
  
  -- matchup tables for extra values --
  -- the character selected by Player 1 is stored at the memory address 0x12AA4C
  -- the character selected by Player 2 is stored at the memory address 0x12AA84
  
  -- 00 - Reapermon, 01 - Black WarGreymon, 02 - Omnimon, 03 - Impmon, 04 - Beelzemon, 05 - Imperialdramon Paladin Mode, 06 - Gabumon, 07 - Agumon, 08 - Patamon, 09 - Terriermon, 10 - Guilmon, 11 - Renamon, 12 - Wormmon, 13 - Veemon, 14 - Gatomon, 15 - Metal Garurumon, 16 - WarGreymon, 17 - Seraphimon, 18 - MegaGargomon, 19 - Gallantmon, 20 - Sakuyamon, 21 - Stingmon, 22 - Imperialdramon, 23 - Magnadramon 
  
  -- the stage index is stored at the memory address 0x12AB20
  -- 1=Wilderness, 2=Revolution, 3=Sanctuary, 4=Glacier, 5=Volcano, 6=Reapermon's Stage(Final Stage), 7=Basketball Game, 8=Digivolve Race, 9=Target Games
  
  -- the X position of player 1 is always stored at the address 0x107AC8, independent on stage and match-up
  -- as a reference: the starting point for P2 at Volcano has X = 327680. Use it to fill the missing values
  local p2PositionMemoryValues = {}
  p2PositionMemoryValues[0]  = 0x107F78  -- P1 Reapermon
  p2PositionMemoryValues[1]  = 0x107F9C  -- P1 BlackWarGreymon
  p2PositionMemoryValues[2]  = 0x107F84  -- P1 Omnimon
  p2PositionMemoryValues[3]  = 0x107F94  -- P1 Impmon
  p2PositionMemoryValues[4]  = 0x107F88  -- P1 Beelzemon
  p2PositionMemoryValues[5]  = 0x107FC8  -- P1 Imperialdramon Paladin Mode
  p2PositionMemoryValues[6]  = 0x107F7C  -- P1 Gabumon
  p2PositionMemoryValues[7]  = 0x107F78  -- P1 Agumon
  p2PositionMemoryValues[8]  = 0x107FC0  -- P1 Patamon
  p2PositionMemoryValues[9]  = 0x107F80  -- P1 Terriermon
  p2PositionMemoryValues[10] = 0x107F78  -- P1 Guilmon
  p2PositionMemoryValues[11] = 0x107FA8  -- P1 Renamon
  p2PositionMemoryValues[12] = 0x107F7C  -- P1 Wormon
  p2PositionMemoryValues[13] = 0x107F78  -- P1 Veemon
  p2PositionMemoryValues[14] = 0x107F7C  -- P1 Gatomon
  p2PositionMemoryValues[15] = 0x107FA4  -- P1 MetalGarurumon
  p2PositionMemoryValues[16] = 0x107F98  -- P1 WarGreymon
  p2PositionMemoryValues[16] = 0x107F80  -- P1 Seraphimon
  p2PositionMemoryValues[18] = 0x107F80  -- P1 MegaGargomon
  p2PositionMemoryValues[19] = 0x107F7C  -- P1 Gallantmon
  p2PositionMemoryValues[20] = 0x107F94  -- P1 Sakuyamon
  p2PositionMemoryValues[21] = 0x107F7C  -- P1 Stingmon
  p2PositionMemoryValues[22] = 0x107FC8  -- P1 Imperialdramon
  p2PositionMemoryValues[23] = 0x107F80  -- P1 Magnadramon
  
  -- there is a reproducible way to get the health bars pixel values, using character mirror matches to gather data
  -- indexes as above
  local characterByteSizeForHealthBars = {}
  characterByteSizeForHealthBars[0]		= 540768	-- Reapermon
  characterByteSizeForHealthBars[1]		= 540804	-- BlackWarGreymon
  characterByteSizeForHealthBars[2]		= 540780	-- Omnimon
  characterByteSizeForHealthBars[3]		= 542012	-- Impmon
  characterByteSizeForHealthBars[4]		= 540784	-- Beelzemon
  characterByteSizeForHealthBars[5]		= 540848	-- Imperialdramon Paladin Mode
  characterByteSizeForHealthBars[6]		= 542016	-- Gabumon
  characterByteSizeForHealthBars[7]		= 542000	-- Agumon
  characterByteSizeForHealthBars[8]		= 542048	-- Patamon
  characterByteSizeForHealthBars[9]		= 541984	-- Terriermon
  characterByteSizeForHealthBars[10]	= 541972	-- Guilmon
  characterByteSizeForHealthBars[11]	= 542044	-- Renamon
  characterByteSizeForHealthBars[12]	= 541976	-- Wormon
  characterByteSizeForHealthBars[13]	= 542048	-- Veemon
  characterByteSizeForHealthBars[14]	= 541980	-- Gatomon
  characterByteSizeForHealthBars[15]	= 540812	-- MetalGarurumon
  characterByteSizeForHealthBars[16]	= 540800	-- WarGreymon
  characterByteSizeForHealthBars[17]	= 540776	-- Seraphimon
  characterByteSizeForHealthBars[18]	= 540776	-- MegaGargomon
  characterByteSizeForHealthBars[19]	= 540772	-- Gallantmon
  characterByteSizeForHealthBars[20]	= 540796	-- Sakuyamon
  characterByteSizeForHealthBars[21]	= 540772	-- Stingmon
  characterByteSizeForHealthBars[22]	= 540848	-- Imperialdramon
  characterByteSizeForHealthBars[23]	= 540776	-- Magnadramon
  
  -- defence multiplier, as labbed by Teseo (Digimon Rumble Arena Discord)
  -- indexes as above
  local healthMultiplier = {}
  healthMultiplier[18]		= 1.58	-- MegaGargomon
  healthMultiplier[15]		= 1.53	-- MetalGarurumon
  healthMultiplier[0]		= 1.44	-- Reapermon
  healthMultiplier[16]		= 1.44	-- WarGreymon
  healthMultiplier[17]		= 1.44	-- Seraphimon
  healthMultiplier[19]		= 1.44	-- Gallantmon
  healthMultiplier[2]		= 1.42	-- Omnimon
  healthMultiplier[20]		= 1.36	-- Sakuyamon
  healthMultiplier[22]		= 1.36	-- Imperialdramon
  healthMultiplier[23]		= 1.36	-- Magnadramon
  healthMultiplier[4]		= 1.36	-- Beelzemon
  healthMultiplier[5]		= 1.33	-- Imperialdramon Paladin Mode
  healthMultiplier[6]		= 1.33	-- Gabumon
  healthMultiplier[1]		= 1.31	-- BlackWarGreymon
  healthMultiplier[21]		= 1.31	-- Stingmon
  healthMultiplier[7]		= 1.31	-- Agumon
  healthMultiplier[10]		= 1.31	-- Guilmon
  healthMultiplier[14]		= 1.31	-- Gatomon
  healthMultiplier[9]		= 1.19	-- Terriermon
  healthMultiplier[13]		= 1.19	-- Veemon
  healthMultiplier[3]		= 1.14	-- Impmon
  healthMultiplier[8]		= 1.08	-- Patamon
  healthMultiplier[11]		= 1.05	-- Renamon
  healthMultiplier[12]		= 1.00	-- Wormon
  
  -- Digivolution marker - used for applying the correct defence value multiplier if the character is in a Evo form
  -- indexes as above
  local evoFormIndex = {}
  evoFormIndex[0]	=  0	-- Reapermon
  evoFormIndex[1]	=  1	-- BlackWarGreymon
  evoFormIndex[2]	=  2	-- Omnimon
  evoFormIndex[3]	=  4	-- Impmon
  evoFormIndex[4]	=  4	-- Beelzemon
  evoFormIndex[5]	=  5	-- Imperialdramon Paladin Mode
  evoFormIndex[6]	= 15	-- Gabumon
  evoFormIndex[7]	= 16	-- Agumon
  evoFormIndex[8]	= 17	-- Patamon
  evoFormIndex[9]	= 18	-- Terriermon
  evoFormIndex[10]	= 19	-- Guilmon
  evoFormIndex[11]	= 20	-- Renamon
  evoFormIndex[12]	= 21	-- Wormon
  evoFormIndex[13]	= 22	-- Veemon
  evoFormIndex[14]	= 23	-- Gatomon
  evoFormIndex[15]	= 15	-- MetalGarurumon
  evoFormIndex[16]	= 16	-- WarGreymon
  evoFormIndex[17]	= 17	-- Seraphimon
  evoFormIndex[18]	= 18	-- MegaGargomon
  evoFormIndex[19]	= 19	-- Gallantmon
  evoFormIndex[20]	= 20	-- Sakuyamon
  evoFormIndex[21]	= 21	-- Stingmon
  evoFormIndex[22]	= 22	-- Imperialdramon
  evoFormIndex[23]	= 23	-- Magnadramon
  
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
		gui.text(300, 40 + index * 30, optionValueslists[index][optionIndexes[index]], color2)
	end
  end
  
  -- draw HP values
  function drawHPValues()
	  if optionIndexes[mainIndexes["HUD"]] == 2 then
	    gui.drawText(596, 409, tostring(math.floor(player2Digi * 100 / defaultDigiValue) .. "%"), 0xffffffff, 0xff000000, 16, null, null, "right")
		gui.drawText(356, 430, tostring(math.floor(player1HP * 100 / defaultHPValue) .. "%"), 0xffffffff, 0xff000000, 16, null, null, "right")
		gui.drawText(454, 430, tostring(math.floor(player2HP * 100 / defaultHPValue) .. "%"), 0xffffffff, 0xff000000, 16, null, null, "left")
		gui.drawText(210, 409, tostring(math.floor(player1Digi * 100 / defaultDigiValue) .. "%"), 0xffffffff, 0xff000000, 16, null, null, "left")
	  elseif optionIndexes[mainIndexes["HUD"]] == 3 then
		gui.drawText(356, 430, tostring(player1HP), 0xffffffff, 0xff000000, 16, null, null, "right")
		gui.drawText(454, 430, tostring(player2HP), 0xffffffff, 0xff000000, 16, null, null, "left")
		gui.drawText(210, 409, tostring(player1Digi), 0xffffffff, 0xff000000, 16, null, null, "left")
		gui.drawText(596, 409, tostring(player2Digi), 0xffffffff, 0xff000000, 16, null, null, "right")
	  elseif optionIndexes[mainIndexes["HUD"]] == 4 then
		healthMultiplierPlayer1 = healthMultiplier[player1CharacterIndex]
		healthMultiplierPlayer2 = healthMultiplier[player2CharacterIndex]
		if player1IsEvo then
			healthMultiplierPlayer1 = healthMultiplier[evoFormIndex[player1CharacterIndex]]
		end
		if player2IsEvo then
			healthMultiplierPlayer2 = healthMultiplier[evoFormIndex[player2CharacterIndex]]
		end
		gui.drawText(356, 430, tostring(math.floor(healthMultiplierPlayer1 * player1HP * 100 / defaultHPValue)), 0xffffffff, 0xff000000, 16, null, null, "right")
		gui.drawText(454, 430, tostring(math.floor(healthMultiplierPlayer2 * player2HP * 100 / defaultHPValue)), 0xffffffff, 0xff000000, 16, null, null, "left")
		gui.drawText(210, 409, tostring(math.floor(player1Digi * 100 / defaultDigiValue) .. "%"), 0xffffffff, 0xff000000, 16, null, null, "left")
		gui.drawText(596, 409, tostring(math.floor(player2Digi * 100 / defaultDigiValue) .. "%"), 0xffffffff, 0xff000000, 16, null, null, "right")
	end
  end
  
  -- update HP values
  function updateHPValues()
	if (characterByteSizeForHealthBars[player1CharacterIndex] ~= nil and characterByteSizeForHealthBars[player2CharacterIndex] ~= nil) then
		local addressHPPlayer1 = characterByteSizeForHealthBars[player1CharacterIndex] + characterByteSizeForHealthBars[player2CharacterIndex]
		local addressHPPlayer2 = addressHPPlayer1 + 132
		player1HPLastFrame = player1HP
		player2HPLastFrame = player2HP
		player1DigiLastFrame = player1Digi
		player2DigiLastFrame = player2Digi
		player1HP = memory.read_u16_le(addressHPPlayer1)
		player2HP = memory.read_u16_le(addressHPPlayer2)
		player1Digi = memory.read_u16_le(addressHPPlayer1 + 16)
		player2Digi = memory.read_u16_le(addressHPPlayer2 + 16)
		-- easiest marker to determine DigiEvolution: if Digi is going down, it's most likely an Evo (or the game got paused)
		if player1DigiLastFrame > player1Digi then
			player1IsEvo = true
		end
		
		if player2DigiLastFrame > player2Digi then
			player2IsEvo = true
		end
		-- restore Evo status when Digi reaches 0 - doesn't work when a new round starts
		if player1Digi == 0 then
			player1IsEvo = false
		end
		if player2Digi == 0 then
			player2IsEvo = false
		end
	end
  end
  
  -- update score values
  -- we use the score increase as a canary to get when one character is hit by the opponent, to trigger "block after first hit" actions
  function updateScoreValues() 
	player1ScoreLastFrame = player1Score
	player2ScoreLastFrame = player2Score
	player1Score = memory.read_u32_le(scorePlayer1Address)
	player2Score = memory.read_u32_le(scorePlayer2Address)
	-- player 1 score increase = player 2 was hit
	if (actOnlyAfterDamage and player1Score > player1ScoreLastFrame) then
		isPerformingAfterDamageAction = true
		afterDamageActionTimer = 0
	end
	if (player1Score >= 999999) then
		memory.write_u32_le(scorePlayer1Address, 0)
		memory.write_u32_le(scorePlayer2Address, 0)
	end 
  end
  
  -- handle "act after damage"
  function handleActAfterDamage()
	if optionIndexes[mainIndexes["AftDmg"]] == 1 then
		actOnlyAfterDamage = true
	else
		actOnlyAfterDamage = false
	end
	isPerformingAfterDamageAction = false
	afterDamageActionTimer = 0
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
	handleActAfterDamage()
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
	if p2PositionMemoryValues[player1CharacterIndex] ~= nil then
		player1X = memory.read_s32_le(0x107AC8)
		player2X = memory.read_s32_le(p2PositionMemoryValues[player1CharacterIndex])
	else
		player1X = 0
		player2X = 1
	end
	if movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Walk Towards" then
		if (player1X > player2X) then
			joypad.set({Right=true}, 2)
		elseif (player1X < player2X) then
			joypad.set({Left=true}, 2)
		end
	elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Walk Away" then
		if (player1X > player2X) then
			joypad.set({Left=true}, 2)
		elseif (player1X < player2X) then
			joypad.set({Right=true}, 2)
		end
	elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Dash Towards" then
		if (player1X > player2X) then
			dashRight()
		elseif (player1X < player2X) then
			dashLeft()
		end
	elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Dash Away" then
		if (player1X > player2X) then
			dashLeft()
		elseif (player1X < player2X) then
			dashRight()
		end
	elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Crouch" then
		joypad.set({Down=true}, 2)
	elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Hop" then
		jumpSet(5)
	elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Jump" then
		jumpSet(15)
	elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "High Jump" then
		jumpSet(35)
	end
  end
  
  -- handle dummy actions
  function handleDummy()
	if (isPerformingAfterDamageAction) then
		afterDamageActionTimer = afterDamageActionTimer + 1
		if afterDamageActionTimer > 120 then
			afterDamageActionTimer = 0
			isPerformingAfterDamageAction = false
		end
	end
	if ((not actOnlyAfterDamage) or (actOnlyAfterDamage and isPerformingAfterDamageAction)) then
		actionTimer = actionTimer + 1
		if (delayTimer > 0 or actionStrings[optionIndexes[mainIndexes["Action"]]] == "None") then
			handleDummyMovement()
		else
			movementTimer = 0
		end
		if actionStrings[optionIndexes[mainIndexes["Action"]]] == "Block" then
			joypad.set({L1=true}, 2)
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Crouch Block" then
			joypad.set({L1=true, Down=true}, 2)
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Special1" then
			singleActionSet({Circle=true}, {Circle=false})
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Special2" then
			singleActionSet({Triangle=true}, {Triangle=false})
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Jab" then
			singleActionSet({Square=true}, {Square=false})
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Double Jab" then
			performJab2Combo()
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Triple Jab" then
			performJab3Combo()
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Sweep" then
			performSweep()
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Launcher" then
			performLauncher()
		elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Super" then
			singleActionSet({R1=true}, {R1=false})
		end
	end
  end
  
  -- handle health bars
  function handleHealthBars()
	if healthStrings[optionIndexes[mainIndexes["HP"]]] ==  "Infinite P1" then
		memory.write_u16_le(0x7F36C, 0x0800)
		memory.write_u16_le(0x7F36E, 0x3121)
		memory.write_u16_le(0x7F3A0, 0x0005)
		memory.write_u16_le(0x7F3A2, 0x1020)
	elseif healthStrings[optionIndexes[mainIndexes["HP"]]] == "Infinite P2" then
		memory.write_u16_le(0x7F36C, 0x0800)
		memory.write_u16_le(0x7F36E, 0x3121)
		memory.write_u16_le(0x7F3A0, 0x0005)
		memory.write_u16_le(0x7F3A2, 0x1420)
	elseif healthStrings[optionIndexes[mainIndexes["HP"]]] == "Infinite P1/P2" then
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
	if timerStrings[optionIndexes[mainIndexes["Timer"]]] ==  "Infinite" then
		memory.write_u16_le(0x717BA, 0x2400)
	else
		memory.write_u16_le(0x717BA, 0xAE22)
	end	
  end
  
  -- draw everything
  function handleGeneralGraphics()
	if (optionIndexes[mainIndexes["HUD"]] ~= 1) then
		drawHPValues()
	end
	if trainingOverlayVisible then
		drawTrainingGui()
    end
  end
  
  -- main routine
  while true do
	player1CharacterIndex = memory.read_u16_le(0x12AA4C)
	player2CharacterIndex = memory.read_u16_le(0x12AA84)
	stageIndex = memory.read_u16_le(0x12AB20)
	inputTable=joypad.get(1)
	handleTrainingGui(inputTable, buttonPressedAtLastFrame)
	updateScoreValues()
	updateHPValues()
	if not trainingOverlayVisible then
		handleDummy()
	end
	buttonPressedAtLastFrame = inputTable;
	handleGeneralGraphics()
	emu.frameadvance()
  end