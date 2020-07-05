RDX = nil

Citizen.CreateThread(function()
	while RDX == nil do
		TriggerEvent('rdx:getSharedObject', function(obj) RDX = obj end)
		Citizen.Wait(0)
	end
end)

local jobs = {
    { x=-240.7, y=769.8, z=118.09}, 
}

local blips = {
    { x=-240.07, y=769.08, z=118.9}, 	
}

--------------------------------INICIO--------------------------------

local active = false
local JobsPrompt
local hasAlreadyEnteredMarker, lastZone
local currentZone = nil

function SetupJobsPrompt()
    Citizen.CreateThread(function()
        local str = 'Usar'
        JobsPrompt = PromptRegisterBegin()
        PromptSetControlAction(JobsPrompt, 0xE8342FF2)
        str = CreateVarString(10, 'LITERAL_STRING', str)
        PromptSetText(JobsPrompt, str)
        PromptSetEnabled(JobsPrompt, false)
        PromptSetVisible(JobsPrompt, false)
        PromptSetHoldMode(JobsPrompt, true)
        PromptRegisterEnd(JobsPrompt)
    end)
end

Citizen.CreateThread(function()
	for _, info in pairs(blips) do
        local blip = N_0x554d9d53f696d002(1664425300, info.x, info.y, info.z)
        SetBlipSprite(blip, -758970771, 1)
		SetBlipScale(blip, 0.2)
		Citizen.InvokeNative(0x9CB1A1623062F402, blip, "Trabalhos")
    end  
end)

AddEventHandler('rdx:dentro', function(zone)
	currentZone     = zone
end)

AddEventHandler('rdx:fora', function(zone)
    if active == true then
        PromptSetEnabled(JobsPrompt, false)
        PromptSetVisible(JobsPrompt, false)
        active = false
    end
	currentZone = nil
end)

Citizen.CreateThread(function()
    SetupJobsPrompt()
    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        local coords = GetEntityCoords(player)
        local isInMarker, currentZone = false

        for k,v in ipairs(jobs) do
            local distance = Vdist(coords.x, coords.y, coords.z, v.x, v.y, v.z)
            if distance < 1.0 then
                isInMarker  = true
                currentZone = 'jobs'
                lastZone    = 'jobs'
            end
        end

		if isInMarker and not hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = true
			TriggerEvent('rdx:dentro', currentZone)
		end

		if not isInMarker and hasAlreadyEnteredMarker then
			hasAlreadyEnteredMarker = false
			TriggerEvent('rdx:fora', lastZone)
		end

    end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
        if currentZone then
            if active == false then
                PromptSetEnabled(JobsPrompt, true)
                PromptSetVisible(JobsPrompt, true)
                active = true
            end
            if PromptHasHoldModeCompleted(JobsPrompt) then
                ShowJobListingMenu()
                PromptSetEnabled(JobsPrompt, false)
                PromptSetVisible(JobsPrompt, false)
                active = false

				currentZone = nil
			end
        else
			Citizen.Wait(500)
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local coords = GetEntityCoords(PlayerPedId())
        Citizen.InvokeNative(0x2A32FAA57B937173, -1795314153, Config.Zonas['jobs'].x, Config.Zonas['jobs'].y, Config.Zonas['jobs'].z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 0.9, 255, 255, 0, 155, 0, 0, 2, 0, 0, 0, 0)
	end
end)

------------------------------FIM------------------------------

function ShowJobListingMenu()
	RDX.TriggerServerCallback('rdx_joblisting:getJobsList', function(jobs)
		local elements = {}

		for i=1, #jobs, 1 do
			table.insert(elements, {
				label = jobs[i].label,
				job   = jobs[i].job
			})
		end

		RDX.UI.Menu.Open('default', GetCurrentResourceName(), 'joblisting', {
			title    = _U('job_center'),
			align    = 'center',
			elements = elements
		}, function(data, menu)
			TriggerServerEvent('rdx_joblisting:setJob', data.current.job)
			RDX.ShowNotification(_U('new_job'))
			menu.close()
		end, function(data, menu)
			menu.close()
		end)

	end)
end