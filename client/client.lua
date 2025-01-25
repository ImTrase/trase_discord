-----------------------------------------------------
---- For more scripts and updates, visit ------------
--------- https://discord.gg/trase ------------------
-----------------------------------------------------

local function openPedMenu()
    local options = {}

    for _, ped in ipairs(Config.Peds) do
        options[#options +1] = {
            label = ped.Name,
            description = ped.Description,
        }
    end

    lib.registerMenu({
        id = 'ped_menu',
        title = 'Ped Menu',
        position = 'top-right',
        options = options,
    }, function(selected, scrollIndex, args)
        local ped = Config.Peds[selected]
            local model = ped.Model
            if model then
                lib.requestModel(model)

                SetPlayerModel(cache.playerId, model)
                SetModelAsNoLongerNeeded(model)

                print(("%s model set successfully!"):format(ped.Name))
            else
                print("Error: Invalid ped model.")
            end
    end)

    lib.showMenu('ped_menu')
end

RegisterNetEvent('trase:pedmenu:open', openPedMenu)