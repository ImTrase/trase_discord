---------------------------------------------------
------- For more support, scripts, and more -------
-------     https://discord.gg/trase     ----------
---------------------------------------------------

local CreateThread = CreateThread
local loaded = false
local cache = {}

local function getIdentifiers(target)
    if (not target or not GetPlayerName(target)) then return end
    local t = {}

    local identifiers = GetPlayerIdentifiers(target)

    for i=1, #identifiers do
        local prefix, identifier = string.strsplit(':', identifiers[i])
        t[prefix] = identifier
    end

    return t
end

-- Do not run this function more then once for a user, all it will do is over-use the discord API resulting in rate limiting
-- All the users roles & data are stored in the "cache" table automatically upon connection to the server.
local function getDiscordInfo(target, onlyRoles)
    local identifiers = getIdentifiers(target)
    if (not identifiers) then return end

    local p = promise.new()
    local discordID <const> = identifiers.discord
    local url <const> = ('https://discordapp.com/api/guilds/%s/members/%s'):format(Config.Guild, discordID)
    local headers <const> = {['Content-Type'] = 'application/json', ['Authorization'] = ('Bot %s'):format(Config.Token)}

    PerformHttpRequest(url, function(errorCode, resultData, resultHeaders)
        local d, inGuild = {}, resultData and true or false

        resultData = json.decode(resultData)

        if (resultData) then
            local roles = {}
            
            for i = 1, (type(resultData?.roles) == 'table' and #resultData?.roles or 0) do
                roles[i] = tonumber(resultData?.roles[i])
            end

            if (onlyRoles) then
                d = roles
            else
                if (resultData?.user) then
                    if (resultData?.user?.username and resultData?.user?.discriminator) then
                        d.name = ('%s#%s'):format(resultData.user.username, resultData.user.discriminator)
                    end

                    if (resultData?.user?.avatar) then   
                        d.avatar = ('https://cdn.discordapp.com/avatars/%s/%s.%s'):format(id, resultData.user.avatar, resultData.user.avatar:sub(1, 1) and resultData.user.avatar:sub(2, 2) == '_' and 'gif' or 'png')
                    end
                end

                d.roles = roles
            end
        end

        if (inGuild) then
            p:resolve({d})
        else
            p:resolve({false})
        end
    end, 'GET', '', headers)

    return table?.unpack(Citizen.Await(p))
end

local function remove_emojis(str)
    local emoji <const> = "[%z\1-\127\194-\244][\128-\191]*"
    return string.gsub(str, emoji, function(char)
        if char:byte() > 127 and char:byte() <= 244 then
            return ''
        else
            return char
        end
    end)
end

RegisterNetEvent('trase_discord:server:player_connected', function()
    if (not loaded) then return end

    local src = source
    local discordData = getDiscordInfo(src)

    if (not discordData) then
        local message = ('^4[DISCORD API] ^3[INFO]^0: %s (ID: %s) just connected into the server, but they are not in the discord.'):format(GetPlayerName(src), src)
        print(message)
    else
        cache[src] = discordData
        local message = ('^4[DISCORD API] ^3[INFO]^0: %s (ID: %s) just connected into the server, they have ^2%s^0 authenticated discord roles.'):format(GetPlayerName(src), src, #discordData.roles)
        print(message)
    end
end)

local function valid_string(str)
    return string.match(str, "%S") ~= nil
end

local function valid_info(guild, token, cb)
    local url <const> = ('https://discordapp.com/api/guilds/%s'):format(guild)
    local headers <const> = {['Content-Type'] = 'application/json', ['Authorization'] = ('Bot %s'):format(token)}

    PerformHttpRequest(url, function(errorCode, data, resultHeaders)
        if (errorCode == 200) then
            data = json.decode(data)
            loaded = true
            cb(data.name)
        else
           cb(false)
        end
    end, 'GET', '', headers)
end

local function getRoles(target)
    if (not cache[target]) then return false end

    return cache[target].roles
end

local function hasValue(table, value)
    for k, v in pairs(table) do
        if (tonumber(k) == tonumber(value)) then
            return true
        elseif (tonumber(v) == tonumber(value)) then
            return true
        end
    end

    return false
end

local function hasRole(target, role, stack)
    local roles = getRoles(target)
    if (not roles) then return false end
    local foundRoles = {}
    
    if (type(role) == 'table') then
        for k, v in pairs(roles) do
            if (hasValue(role, tonumber(v))) then
                if (stack) then
                    foundRoles[#foundRoles +1] = v
                else
                    return true, v
                end
            end
        end
    else
        for k, v in pairs(roles) do
            if (tonumber(v) == tonumber(role)) then
                return true
            end
        end
    end

    if (stack and next(foundRoles)) then
        return foundRoles
    end

    return false
end

local function getUsername(target)
    if (not cache[target]) then return false end

    return cache[target].name
end

local function getAvatar(target)
    if (not cache[target]) then return false end

    return cache[target].avatar
end

local function getUser(target)
    if (not cache[target]) then return false end

    return cache[target]
end

CreateThread(function()
    if (not Config.Token or type(Config.Token) ~= 'string' or not valid_string(Config.Token)) then
        return print('^4[DISCORD API] ^1[ERROR]^0: Token specified in the config file does not exist, for support visit: ^3Discord.gg/trase^0.')
    end

    if (not Config.Guild or type(Config.Guild) ~= 'string' or not valid_string(Config.Guild)) then
        return print('^4[DISCORD API] ^1[ERROR]^0: Guild specified in the config file does not exist, for support visit: ^3Discord.gg/trase^0.')
    end

    valid_info(Config.Guild, Config.Token, function(valid)
        if (valid) then
            print(('^4[DISCORD API] ^2[SUCCESS]^0: Discord Autenticated To: %s.'):format(remove_emojis(valid)))
        else
            print('^4[DISCORD API] ^1[ERROR]^0: Guild or Token specified in the config file is invalid, for support visit: ^3Discord.gg/trase^0.')
        end
    end)
end)


exports('getRoles', getRoles)
exports('hasRole', hasRole)
exports('getUsername', getUsername)
exports('getAvatar', getAvatar)
exports('getUser', getUser)
