---------------------------------------------------
------- For more support, scripts, and more -------
-------     https://discord.gg/trase     ----------
---------------------------------------------------

CreateThread(function()
	while (true) do
        Wait(0)

		if NetworkIsPlayerActive(PlayerId()) then
			Wait(500)
			TriggerServerEvent('trase_discord:server:player_connected')
			break
		end
    end
end)