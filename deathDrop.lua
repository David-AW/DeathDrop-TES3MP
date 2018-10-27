local Methods = {}
local corpses = {}
local resetInv = {}

local function placeCorpse(pid)
	resetInv[pid] = true
    local mpNum = WorldInstance:GetCurrentMpNum() + 1
	local cell = tes3mp.GetCell(pid)
    local location = {
        posX = tes3mp.GetPosX(pid), posY = tes3mp.GetPosY(pid), posZ = tes3mp.GetPosZ(pid),
        rotX = 0, rotY = 0, rotZ = 0
    }
    local refIndex =  0 .. "-" .. mpNum
    
    if not LoadedCells[cell] then
        --TODO: Should ideally be temporary
        myMod.LoadCell(cell)
    end

    LoadedCells[cell]:InitializeObjectData(refIndex, "dead_skeleton")
    LoadedCells[cell].data.objectData[refIndex].location = location
	LoadedCells[cell].data.objectData[refIndex].inventory = {}
	
	WorldInstance:SetCurrentMpNum(mpNum)
    tes3mp.SetCurrentMpNum(mpNum)
    
    table.insert(LoadedCells[cell].data.packets.place, refIndex)
	table.insert(LoadedCells[cell].data.packets.container, refIndex)
	
	for index,item in pairs(Players[pid].data.equipment) do
		tes3mp.UnequipItem(pid, index) -- creates unequipItem packet
		tes3mp.SendEquipment(pid) -- sends packet to pid
	end
	
	local temp = Players[pid].data.inventory
	Players[pid].data.inventory = {} -- clear inventory data in the files
	Players[pid].data.equipment = {}
	
	Players[pid]:LoadInventory()
	
	if not corpses[cell] then
		corpses[cell] = {}
	end
	
	table.insert(corpses[cell], {timeOfDeath = os.time(), corpseRefIndex = refIndex})

    for onlinePid, player in pairs(Players) do
        if player:IsLoggedIn() then
            tes3mp.InitializeEvent(onlinePid)
            tes3mp.SetEventCell(cell)
            tes3mp.SetObjectRefId("dead_skeleton")
            tes3mp.SetObjectRefNumIndex(0)
            tes3mp.SetObjectMpNum(mpNum)
            tes3mp.SetObjectPosition(tes3mp.GetPosX(pid), tes3mp.GetPosY(pid), tes3mp.GetPosZ(pid))
            tes3mp.SetObjectRotation(tes3mp.GetRotX(pid), 0, tes3mp.GetRotZ(pid))
			for index,item in pairs(temp) do
				tes3mp.SetContainerItemRefId(item.refId)
				tes3mp.SetContainerItemCount(item.count)
				tes3mp.SetContainerItemCharge(item.charge)
				tes3mp.SetContainerItemEnchantmentCharge(item.enchantmentCharge)
				tes3mp.AddContainerItem()
				LoadedCells[cell].data.objectData[refIndex].inventory[index] = {}
				LoadedCells[cell].data.objectData[refIndex].inventory[index].count = item.count
				LoadedCells[cell].data.objectData[refIndex].inventory[index].charge = item.charge
				LoadedCells[cell].data.objectData[refIndex].inventory[index].enchantmentCharge = item.enchantmentCharge
				LoadedCells[cell].data.objectData[refIndex].inventory[index].refId = item.refId
			end
            tes3mp.AddWorldObject()
            tes3mp.SendObjectPlace()
			tes3mp.SendContainer()
        end
    end
    
    LoadedCells[cell]:Save()
    
    return refIndex
end

Methods.OnDeathTimerExpire = function(pid)

	placeCorpse(pid)

end

Methods.OnPlayerResurrected = function(pid)
	
	if resetInv[pid] then
		Players[pid].data.equipment = {nil,nil,nil,nil,nil,nil,{enchantmentCharge = -1,refId = "common_shoes_01",count = 1, charge = -1},{enchantmentCharge = -1,refId = "common_shirt_01",count = 1,charge = -1},{enchantmentCharge = -1,refId = "common_pants_01",count = 1,charge = -1}}
		
		Players[pid]:LoadEquipment()
		resetInv[pid] = nil
	end

end

return Methods