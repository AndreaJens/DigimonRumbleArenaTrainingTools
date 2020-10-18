	--[[Digimon Rumble Arena Training Mode Script v1.3
	A handy Bizhawk LUA script to add some training functions to the game.
	Code is ugly, but does what is supposed to. Feel free to improve it as you wish.
	The code is released under a MIT license.
	2020 - Andrea "Jens" Demetrio
	]]--

	-- global variables
	local mainIndexes = {}
		mainIndexes["Dummy"] 		= 1
		mainIndexes["Action"] 		= 2
		mainIndexes["Movement"] 	= 3
		mainIndexes["HP"] 			= 6
		mainIndexes["Timer"] 		= 7
		mainIndexes["HUD"] 			= 8
		mainIndexes["AftDmg"]		= 4
		mainIndexes["AftKnd"]		= 5
		mainIndexes["StateAtk"]		= 9

	local trainingOverlayVisible = false
	local inputTableP1={}
	local inputTableP2={}
	local buttonPressedAtLastFrameP1 = {}
	local buttonPressedAtLastFrameP2 = {}

	local trainingOptionIndex = 1

	local optionIndexes = {}
		optionIndexes[mainIndexes["Dummy"]] 		= 2
		optionIndexes[mainIndexes["Action"]] 		= 1
		optionIndexes[mainIndexes["Movement"]] 		= 1
		optionIndexes[mainIndexes["HP"]] 			= 1
		optionIndexes[mainIndexes["Timer"]] 		= 1
		optionIndexes[mainIndexes["HUD"]] 			= 1
		optionIndexes[mainIndexes["AftDmg"]] 		= 2
		optionIndexes[mainIndexes["AftKnd"]] 		= 2
		optionIndexes[mainIndexes["StateAtk"]] 		= 2

	local actionStrings = {"None", "Block", "Crouch Block", "Special1", "Special2", "Jab", "Sweep", "Launcher", "Super"}
	local movementStrings = {"None", "Crouch", "Walk Towards", "Walk Away", "Dash Towards", "Dash Away", "Hop", "Jump", "High Jump"}
	local healthStrings = {"Normal", "Infinite P2", "Infinite P1", "Infinite P1/P2"}
	local timerStrings = {"Normal", "Infinite"}
	local yesnoString = {"Yes", "No"}
	local dummyStrings = {"Player 1", "Player 2"}
	local hpDigiValues = {"No", "Percentage", "Absolute Pixel Bar Size", "Scaled using Defence Value"}

	-- menu labels
	local labels = {}
		labels[mainIndexes["Dummy"]] 		= "Dummy Player"
		labels[mainIndexes["Action"]] 		= "Dummy Action"
		labels[mainIndexes["Movement"]] 	= "Dummy Movement"
		labels[mainIndexes["HP"]] 			= "Health Bars"
		labels[mainIndexes["Timer"]] 		= "Timer"
		labels[mainIndexes["HUD"]] 			= "Show HP/Digi"
		labels[mainIndexes["AftDmg"]] 		= "Act after Damage"
		labels[mainIndexes["AftKnd"]] 		= "Act after Knockdown"
		labels[mainIndexes["StateAtk"]] 	= "Show State/Action"

	-- menu values
	local optionValueslists = {}
		optionValueslists[mainIndexes["Dummy"]] 		= dummyStrings
		optionValueslists[mainIndexes["Action"]] 		= actionStrings
		optionValueslists[mainIndexes["Movement"]] 		= movementStrings
		optionValueslists[mainIndexes["HP"]] 			= healthStrings
		optionValueslists[mainIndexes["Timer"]] 		= timerStrings
		optionValueslists[mainIndexes["HUD"]] 			= hpDigiValues
		optionValueslists[mainIndexes["AftDmg"]] 		= yesnoString
		optionValueslists[mainIndexes["AftKnd"]] 		= yesnoString
		optionValueslists[mainIndexes["StateAtk"]] 		= yesnoString

	-- menu sizes
	local optionSizes = {}
		optionSizes[mainIndexes["Dummy"]] 		= table.getn(dummyStrings)
		optionSizes[mainIndexes["Action"]] 		= table.getn(actionStrings)
		optionSizes[mainIndexes["Movement"]] 	= table.getn(movementStrings)
		optionSizes[mainIndexes["HP"]] 			= table.getn(healthStrings)
		optionSizes[mainIndexes["Timer"]] 		= table.getn(timerStrings)
		optionSizes[mainIndexes["HUD"]] 		= table.getn(hpDigiValues)
		optionSizes[mainIndexes["AftDmg"]] 		= table.getn(yesnoString)
		optionSizes[mainIndexes["AftKnd"]] 		= table.getn(yesnoString)
		optionSizes[mainIndexes["StateAtk"]] 	= table.getn(yesnoString)

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
	local actOnlyAfterKnockdown = false
	local isPerformingAfterDamageAction = false
	local prepareAfterDamageActionCheck = false
	local afterDamageActionTimer = 0

	local player1IsEvo = false
	local player2IsEvo = false
	local gameIsPaused = false
	local isInBattleScreen = false
	local player1DigiNoDecreaseFrameCounter = 0
	local player2DigiNoDecreaseFrameCounter = 0

	local player1State = 1
	local player2State = 1
	local player1StateLastFrame = 1
	local player2StateLastFrame = 1
	local player1Move = 1
	local player2Move = 1
	local player1MoveFrames = 0
	local player2MoveFrames = 0
	
	local dummyPlayer = 2
	local activePlayer = 1

	-- actually, this memory address just stops the sound effects in the background, still it's a nice canary for the pause menu being up
	local pauseMemoryAddress = 0x05F880

	-- I don't have ANY idea of what this memory address controls, only that it is always 0 in chara select screen and always 1 in battleScreenCanary
	-- probably an asset loading flag, as it is set only once during the loading screen and never touched again
	local characterSelectionScreenCanary = 0x065048 --0x0641B4

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
		p2PositionMemoryValues[17] = 0x107F80  -- P1 Seraphimon
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
		characterByteSizeForHealthBars[10]		= 541972	-- Guilmon
		characterByteSizeForHealthBars[11]		= 542044	-- Renamon
		characterByteSizeForHealthBars[12]		= 541976	-- Wormon
		characterByteSizeForHealthBars[13]		= 542048	-- Veemon
		characterByteSizeForHealthBars[14]		= 541980	-- Gatomon
		characterByteSizeForHealthBars[15]		= 540812	-- MetalGarurumon
		characterByteSizeForHealthBars[16]		= 540800	-- WarGreymon
		characterByteSizeForHealthBars[17]		= 540776	-- Seraphimon
		characterByteSizeForHealthBars[18]		= 540776	-- MegaGargomon
		characterByteSizeForHealthBars[19]		= 540772	-- Gallantmon
		characterByteSizeForHealthBars[20]		= 540796	-- Sakuyamon
		characterByteSizeForHealthBars[21]		= 540772	-- Stingmon
		characterByteSizeForHealthBars[22]		= 540848	-- Imperialdramon
		characterByteSizeForHealthBars[23]		= 540776	-- Magnadramon
	
	-- defence multiplier, as labbed by Teseo (Digimon Rumble Arena Discord)
	-- indexes as above
	local healthMultiplier = {}
		healthMultiplier[18]		= 1.58	-- MegaGargomon
		healthMultiplier[15]		= 1.53	-- MetalGarurumon
		healthMultiplier[0]			= 1.44	-- Reapermon
		healthMultiplier[16]		= 1.44	-- WarGreymon
		healthMultiplier[17]		= 1.44	-- Seraphimon
		healthMultiplier[19]		= 1.44	-- Gallantmon
		healthMultiplier[2]			= 1.42	-- Omnimon
		healthMultiplier[20]		= 1.36	-- Sakuyamon
		healthMultiplier[22]		= 1.36	-- Imperialdramon
		healthMultiplier[23]		= 1.36	-- Magnadramon
		healthMultiplier[4]			= 1.36	-- Beelzemon
		healthMultiplier[5]			= 1.33	-- Imperialdramon Paladin Mode
		healthMultiplier[6]			= 1.33	-- Gabumon
		healthMultiplier[1]			= 1.31	-- BlackWarGreymon
		healthMultiplier[21]		= 1.31	-- Stingmon
		healthMultiplier[7]			= 1.31	-- Agumon
		healthMultiplier[10]		= 1.31	-- Guilmon
		healthMultiplier[14]		= 1.31	-- Gatomon
		healthMultiplier[9]			= 1.19	-- Terriermon
		healthMultiplier[13]		= 1.19	-- Veemon
		healthMultiplier[3]			= 1.14	-- Impmon
		healthMultiplier[8]			= 1.08	-- Patamon
		healthMultiplier[11]		= 1.05	-- Renamon
		healthMultiplier[12]		= 1.00	-- Wormon

	-- Digivolution marker - used for applying the correct defence value multiplier if the character is in a Evo form
	-- indexes as above
	local evoFormIndex = {}
		evoFormIndex[3]		=  4	-- Impmon
		evoFormIndex[6]		= 15	-- Gabumon
		evoFormIndex[7]		= 16	-- Agumon
		evoFormIndex[8]		= 17	-- Patamon
		evoFormIndex[9]		= 18	-- Terriermon
		evoFormIndex[10]	= 19	-- Guilmon
		evoFormIndex[11]	= 20	-- Renamon
		evoFormIndex[12]	= 21	-- Wormon
		evoFormIndex[13]	= 22	-- Veemon
		evoFormIndex[14]	= 23	-- Gatomon

	-- status variables for player 1. To get the addresses for player 2, calculate the offset between  p2PositionMemoryValues[p1Index] - 0x107AC8 and
	-- add it to the below value
	local statusP1Address 		 		= 0x107994
	local moveIdP1Address 		 		= 0x10785C
	local moveFrameNumberP1Address		= 0x107860

	-- states recogized so far
	local characterStatus = {}
		characterStatus[0]  = "idle"
		characterStatus[1]  = "walking"
		characterStatus[2]  = "dash"
		characterStatus[3]  = "jump"
		characterStatus[4]  = "free-fall"
		characterStatus[12] = "block"
		characterStatus[13] = "hitstun"
		characterStatus[14] = "air juggle"
		characterStatus[15] = "stun"
		characterStatus[16] = "knockdown"
		characterStatus[17] = "air knockdown"
		characterStatus[18] = "wake up"
		characterStatus[19] = "crouching"
		characterStatus[21] = "crouch block"
		characterStatus[28] = "victory"
		characterStatus[30] = "intro"

	-- moves recogized so far
	local characterMoves = {}
		characterMoves[20] = "melee 1"
		characterMoves[21] = "melee 2"
		characterMoves[22] = "melee 3"
		characterMoves[23] = "launcher"
		characterMoves[24] = "grab"
		characterMoves[25] = "sweep"
		characterMoves[26] = "dash attack"
		characterMoves[27] = "jump launcher"
		characterMoves[28] = "jump attack"
		characterMoves[29] = "special 1"
		characterMoves[30] = "air special 1"
		characterMoves[31] = "special 2"
		characterMoves[32] = "air special 2"
		characterMoves[33] = "super"
		characterMoves[34] = "air super"

	-- calculate offsetted address
	function calculatePlayer2OffsetAddress(originalAddress, player1Index)
		return (originalAddress + p2PositionMemoryValues[player1Index] - 0x107AC8)
	end
	
	-- check if character is in hitstun
	function isHitstun(playerState)
		return (playerState == 13 or playerState == 14)
	end
	
	-- check if character is knocked down
	function isKnockedDown(playerState)
		return (playerState >= 16 and playerState <= 18)
	end
	
	-- check if the dummy has to perform a triggered action
	function hasStateTriggeredAction()
		return (actOnlyAfterKnockdown or actOnlyAfterDamage)
	end

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
	
	-- draw GUI scalable
	function drawTrainingGuiScalable()
		local fontSize = 18
		local outlineColor = 0xffff333333
		gui.drawBox(0, 0, 960, 480, null, 0xaaaaaaaa)
		gui.drawText(400, 20, 'Digimon Rumble Arena - Training Helper', 0xffaaaa00, outlineColor, fontSize + 4, null, null, "center")
		gui.drawText(400, 40, 'Scroll between options with L2/R2. Scroll between values with L1/R1.', 0xffaaaa00, outlineColor, fontSize - 2, null, null, "center")
		for index=1,labelsSize,1 do
			color1 = inactiveColorLabel
			color2 = inactiveColorItem
			if index == trainingOptionIndex then
				color1 = activeColorLabel
				color2 = activeColorItem
			end
			gui.drawText(50, 40 + index * 30, labels[index], color1, outlineColor, fontSize)
			gui.drawText(300, 40 + index * 30, optionValueslists[index][optionIndexes[index]], color2, outlineColor, fontSize)
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

	-- draw character action & frame
	function drawStateAndFrame()
		if characterStatus[player1State] ~= nil then
			gui.drawText(356, 360, characterStatus[player1State], 0xffffffff, 0xff000000, 16, null, null, "right")
		end
		if characterStatus[player2State] ~= nil then
			gui.drawText(454, 360, characterStatus[player2State], 0xffffffff, 0xff000000, 16, null, null, "left")
		end
		if characterMoves[player1Move] ~= nil then
			gui.drawText(110, 460, characterMoves[player1Move], 0xffffffff, 0xff000000, 16, null, null, "left")
			gui.drawText(356, 460, "frame:" .. tostring(player1MoveFrames), 0xffffffff, 0xff000000, 16, null, null, "right")
		end
		if characterMoves[player2Move] ~= nil then
			gui.drawText(690, 460, characterMoves[player2Move], 0xffffffff, 0xff000000, 16, null, null, "right")
			gui.drawText(454, 460, "frame:" .. tostring(player2MoveFrames), 0xffffffff, 0xff000000, 16, null, null, "left")
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
			if evoFormIndex[player1CharacterIndex] ~= nil then
				if player1DigiLastFrame > player1Digi then
					player1DigiNoDecreaseFrameCounter = 0
					player1IsEvo = true
				end
			else
				player1IsEvo = false
			end
			if evoFormIndex[player2CharacterIndex] ~= nil then
				if player2DigiLastFrame > player2Digi then
					player2DigiNoDecreaseFrameCounter = 0
					player2IsEvo = true
				end
			else
				player2IsEvo = false
			end
			-- restore Evo status when Digi reaches 0 - doesn't work when a new round starts
			if player1Digi == 0 then
				player1IsEvo = false
				player1DigiNoDecreaseFrameCounter = 0
			end
			if player2Digi == 0 then
				player2IsEvo = false
				player2DigiNoDecreaseFrameCounter = 0
			end
			-- if the Digi didn't go down in the last 6 frames, then consider the digimon in a base state
			if player1DigiLastFrame <= player1Digi then
				player1DigiNoDecreaseFrameCounter = player1DigiNoDecreaseFrameCounter + 1
				if (player1DigiNoDecreaseFrameCounter > 60) then
					player1IsEvo = false
					player1DigiNoDecreaseFrameCounter = 0
				end
			end
			
			if player2DigiLastFrame <= player2Digi then
				player2DigiNoDecreaseFrameCounter = player2DigiNoDecreaseFrameCounter + 1
				if (player2DigiNoDecreaseFrameCounter > 60) then
					player2IsEvo = false
					player2DigiNoDecreaseFrameCounter = 0
				end
			end
		end
	end

	-- update state and action for each character. Useful for calculating when a character gets out of hitstun
	function updateStateAndAction()
		player1StateLastFrame = player1State
		player2StateLastFrame = player2State
		player1State = memory.read_u32_le(statusP1Address)
		player2State = memory.read_u32_le(calculatePlayer2OffsetAddress(statusP1Address, player1CharacterIndex))
		player1Move = memory.read_u32_le(moveIdP1Address)
		player2Move = memory.read_u32_le(calculatePlayer2OffsetAddress(moveIdP1Address, player1CharacterIndex))
		player1MoveFrames = memory.read_u32_le(moveFrameNumberP1Address)
		player2MoveFrames = memory.read_u32_le(calculatePlayer2OffsetAddress(moveFrameNumberP1Address, player1CharacterIndex))
		local dummyState = player2State
		local dummyStateLastFrame = player2StateLastFrame
		if activePlayer == 2 then
			dummyState = player1State
			dummyStateLastFrame = player1StateLastFrame
		end
		
		-- after hit-stun reaction
		if (not isHitstun(dummyStateLastFrame) and isHitstun(dummyState)) then
			if (actOnlyAfterDamage) then
				prepareAfterDamageActionCheck = true
				afterDamageActionTimer = 0
			end
		elseif (isHitstun(dummyStateLastFrame) and not isHitstun(dummyState)) then
			actionTimer = 0
			afterDamageActionTimer = 0
			movementTimer = 0
			delayMovementTimer = 0
			delayTimer = 0
			if prepareAfterDamageActionCheck then
				prepareAfterDamageActionCheck = false
				isPerformingAfterDamageAction = true
			end
			--console.log(tostring(emu.framecount()) .. " - Exit hitstun")
		end
		
		-- knock down wake up reaction
		if (not isKnockedDown(dummyStateLastFrame) and isKnockedDown(dummyState)) then
			if (actOnlyAfterKnockdown) then
				prepareAfterDamageActionCheck = true
				afterDamageActionTimer = 0
			end
		elseif (isKnockedDown(dummyStateLastFrame) and not isKnockedDown(dummyState)) then
			actionTimer = 0
			afterDamageActionTimer = 0
			movementTimer = 0
			delayMovementTimer = 0
			delayTimer = 0
			if prepareAfterDamageActionCheck then
				prepareAfterDamageActionCheck = false
				isPerformingAfterDamageAction = true
			end
			--console.log(tostring(emu.framecount()) .. " - Exit hitstun")
		end
	end

	-- update score values
	-- we use the score increase as a canary to get when one character is hit by the opponent, to trigger "block after first hit" actions
	function updateScoreValues() 
		player1ScoreLastFrame = player1Score
		player2ScoreLastFrame = player2Score
		player1Score = memory.read_u32_le(scorePlayer1Address)
		player2Score = memory.read_u32_le(scorePlayer2Address)
		--[[
		-- with the hitstun indication, probably we can get rid of the score now
		-- player 1 score increase = player 2 was hit
		if (actOnlyAfterDamage and player1Score > player1ScoreLastFrame) then
			prepareAfterDamageActionCheck = true
			--isPerformingAfterDamageAction = true
			afterDamageActionTimer = 0
		end
		if (player1Score >= 999999) then
			memory.write_u32_le(scorePlayer1Address, 0)
			memory.write_u32_le(scorePlayer2Address, 0)
		end 
		]]--
	end

	-- handle "act after damage"
	function handleActAfterDamage()
		if optionIndexes[mainIndexes["AftDmg"]] == 1 then
			actOnlyAfterDamage = true
		else
			actOnlyAfterDamage = false
		end
		if optionIndexes[mainIndexes["AftKnd"]] == 1 then
			actOnlyAfterKnockdown = true
		else
			actOnlyAfterKnockdown = false
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
	
	-- handle new action (reset variables)
	function handleDummyPlayer()
		if optionIndexes[mainIndexes["Dummy"]] == 1 then
			activePlayer = 2
			dummyPlayer = 1
		else
			activePlayer = 1
			dummyPlayer = 2
		end
	end

	-- handle menu exit (sets all new values in memory)
	function handleSelection()
		handleActAfterDamage()
		handleNewAction()
		handleHealthBars()
		handleTimer()
		handleDummyPlayer()
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
			joypad.set(inputTableOn, dummyPlayer)
			delayTimer = 0
		elseif actionTimer == 4 then
			joypad.set(inputTableOff, dummyPlayer)
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
			joypad.set({Cross=true}, dummyPlayer)
			delayMovementTimer = 0
		elseif movementTimer == frameOfPressure then
			joypad.set({Cross=false}, dummyPlayer)
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
			joypad.set({Right=true}, dummyPlayer)
			delayMovementTimer = 0
		elseif movementTimer < 6 then
			joypad.set({Right=false}, dummyPlayer)
		elseif movementTimer < 10 then
			joypad.set({Right=true}, dummyPlayer)
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
			joypad.set({Left=true}, dummyPlayer)
			delayMovementTimer = 0
		elseif movementTimer < 6 then
			joypad.set({Left=false}, dummyPlayer)
		elseif movementTimer < 10 then
			joypad.set({Left=true}, dummyPlayer)
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
			joypad.set({Down=true}, dummyPlayer)
			delayTimer = 0
		elseif actionTimer < 9 then
			joypad.set({Down=true, Square=true}, dummyPlayer)
		elseif actionTimer == 10 then
			joypad.set({Down=false, Square=false}, dummyPlayer)
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
		if actionTimer < 2 then
			joypad.set({Up=true}, dummyPlayer)
			delayTimer = 0
		elseif actionTimer < 9 then
			joypad.set({Up=true, Square=true}, dummyPlayer)
		elseif actionTimer == 10 then
			joypad.set({Up=false, Square=false}, dummyPlayer)
		elseif actionTimer > 10 then
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
		-- use variables for abstracting which player to control
		local activePlayerX = player1X
		local dummyPlayerX = player2X
		if activePlayer == 2 then
			activePlayerX = player2X
			dummyPlayerX = player1X
		end
		if movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Walk Towards" then
			if (activePlayerX > dummyPlayerX) then
				joypad.set({Right=true}, dummyPlayer)
			elseif (activePlayerX < dummyPlayerX) then
				joypad.set({Left=true}, dummyPlayer)
			end
		elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Walk Away" then
			if (activePlayerX > dummyPlayerX) then
				joypad.set({Left=true}, dummyPlayer)
			elseif (activePlayerX < dummyPlayerX) then
				joypad.set({Right=true}, dummyPlayer)
			end
		elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Dash Towards" then
			if (activePlayerX > dummyPlayerX) then
				dashRight()
			elseif (activePlayerX < dummyPlayerX) then
				dashLeft()
			end
		elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Dash Away" then
			if (activePlayerX > dummyPlayerX) then
				dashLeft()
			elseif (activePlayerX < dummyPlayerX) then
				dashRight()
			end
		elseif movementStrings[optionIndexes[mainIndexes["Movement"]]] == "Crouch" then
			joypad.set({Down=true}, dummyPlayer)
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
		if hasStateTriggeredAction() then 
			if (isPerformingAfterDamageAction) then
				afterDamageActionTimer = afterDamageActionTimer + 1
				local limit = 30
				if player2State == 12 or player2State == 21 then
					limit = 100
					-- keep block up until the move is being performed
					if (player1Move > 1) then
						limit = afterDamageActionTimer + 1
					end
				end
				if afterDamageActionTimer > limit then
					afterDamageActionTimer = 0
					isPerformingAfterDamageAction = false
				end
			--else
				--handleDummyMovement()
			end
		end
		if ((not hasStateTriggeredAction()) or (hasStateTriggeredAction() and isPerformingAfterDamageAction)) then
			actionTimer = actionTimer + 1
			if (delayTimer > 0 or actionStrings[optionIndexes[mainIndexes["Action"]]] == "None") then
				handleDummyMovement()
			else
				movementTimer = 0
			end
			if actionStrings[optionIndexes[mainIndexes["Action"]]] == "Block" then
				joypad.set({L1=true}, dummyPlayer)
			elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Crouch Block" then
				joypad.set({L1=true, Down=true}, dummyPlayer)
			elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Special1" then
				singleActionSet({Circle=true}, {Circle=false})
			elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Special2" then
				singleActionSet({Triangle=true}, {Triangle=false})
			elseif actionStrings[optionIndexes[mainIndexes["Action"]]] == "Jab" then
				singleActionSet({Square=true}, {Square=false})
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
			if player1HP > 0 and player2HP > 0 then
				drawHPValues()
			end
		end
		if (optionIndexes[mainIndexes["StateAtk"]] ~= 2) then
			if player1HP > 0 and player2HP > 0 then
				drawStateAndFrame()
			end
		end
		if trainingOverlayVisible then
			drawTrainingGui()
		end
	end

	-- main routine
	while true do
		-- check if we are in the character selection screen or in the normal battle menu
		local battleScreenCanary = memory.read_u32_le(characterSelectionScreenCanary)
		if battleScreenCanary == 1 then
			isInBattleScreen = true
		else
			isInBattleScreen = false
		end
		player1CharacterIndex = memory.read_u16_le(0x12AA4C)
		player2CharacterIndex = memory.read_u16_le(0x12AA84)
		stageIndex = memory.read_u16_le(0x12AB20)
		if isInBattleScreen then
			-- check if the game is paused
			local pauseMenuCanary = memory.read_u32_le(pauseMemoryAddress)
			if pauseMenuCanary == 1 then
				gameIsPaused = true
			else
				gameIsPaused = false
			end
			-- get input
			inputTableP1=joypad.get(1)
			inputTableP2=joypad.get(2)
			handleTrainingGui(inputTableP1, buttonPressedAtLastFrameP1)
			handleTrainingGui(inputTableP2, buttonPressedAtLastFrameP2)
			if not gameIsPaused then
				updateScoreValues()
				updateHPValues()
				updateStateAndAction()
				if not trainingOverlayVisible then
					handleDummy()
				end
			end
			buttonPressedAtLastFrameP1 = inputTableP1;
			buttonPressedAtLastFrameP2 = inputTableP2;
			handleGeneralGraphics()
		end
		emu.frameadvance()
	end