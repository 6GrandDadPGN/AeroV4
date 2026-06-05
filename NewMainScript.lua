local EXPECTED_REPO_OWNER = "poopparty"
local EXPECTED_REPO_NAME = "poopparty"
local ACCOUNT_SYSTEM_URL = "https://raw.githubusercontent.com/poopparty/whitelistcheck/main/AccountSystem.lua"
if not shared.VapeLoaded then
    shared.VapeLoaded = true
else
    return
end

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        shared.VapeLoaded = nil 
    end
end)

local function createNotification(title, text, duration)
    duration = duration or 3
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end)
end

local function clearSecurityFolder()
    if not isfolder('newvape/security') then
        makefolder('newvape/security')
        return
    end
    local files = listfiles('newvape/security')
    for _, file in pairs(files) do
        if isfile(file) then
            delfile(file)
        end
    end
end

local function createValidationFile(username, accountType)
    if not isfolder('newvape/security') then
        makefolder('newvape/security')
    end

    if accountType == "premium" then
        local validationData = {
            username = username,
            timestamp = os.time(),
            account_type = "premium"
        }
        local encoded = game:GetService("HttpService"):JSONEncode(validationData)
        writefile('newvape/security/validated', encoded)
    end
end

local function checkExistingValidation()
    if isfile('newvape/security/validated') then
        local validationContent = readfile('newvape/security/validated')
        local success, validationData = pcall(function()
            return game:GetService("HttpService"):JSONDecode(validationContent)
        end)
        if success and validationData and validationData.account_type == "premium" then
            return true, validationData.username, "premium"
        end
    end
    return false, nil, nil
end

local function fetchAccounts()
    local success, response = pcall(function()
        return game:HttpGet(ACCOUNT_SYSTEM_URL)
    end)
    if success and response then
        local accountsTable = loadstring(response)()
        if accountsTable and accountsTable.Accounts then
            return accountsTable.Accounts
        end
    end
    return nil
end

local function SecurityCheck(loginData)
    if not loginData or type(loginData) ~= "table" then
        createNotification("error", "wrong loadstring bro. dm aero", 3)
        return false
    end

    local inputUsername = loginData.Username
    local inputPassword = loginData.Password

    if not inputUsername or not inputPassword then
        createNotification("error", "missing credentials bro wtf. dm aero", 3)
        return false
    end

    clearSecurityFolder()

    local accounts = fetchAccounts()

    if not accounts then
        createNotification("error", "couldn't fetch accounts. check ur wifi it might be ass. dm aero", 3)
        return false
    end

    local accountFound = false
    local correctPassword = false
    local accountActive = false

    for _, account in pairs(accounts) do
        if account.Username == inputUsername then
            accountFound = true
            if account.Password == inputPassword then
                correctPassword = true
                accountActive = account.IsActive == true
            end
            break
        end
    end

    if not accountFound then
        createNotification("access denied", "username not found. dm 5qvx for access", 3)
        return false
    end

    if not correctPassword then
        createNotification("access denied", "wrong password for " .. inputUsername, 3)
        return false
    end

    if not accountActive then
        createNotification("account inactive", "ur account is currently inactive", 3)
        return false
    end

    createValidationFile(inputUsername, "premium")
    return true
end

local passedArgs = {}
local rawArgs = ...
if type(rawArgs) == "table" then
    passedArgs = rawArgs
end

local isPremiumLogin = type(passedArgs.Username) == "string" and #passedArgs.Username > 0
                    and type(passedArgs.Password) == "string" and #passedArgs.Password > 0

if isPremiumLogin then
    local success = SecurityCheck(passedArgs)
    if not success then return end

    local isfile = isfile or function(file)
        local suc, res = pcall(function() return readfile(file) end)
        return suc and res ~= nil and res ~= ''
    end
    local delfile = delfile or function(file) writefile(file, '') end

    local function downloadFile(path, func)
        if not isfile(path) then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
            end)
            if not suc or res == '404: Not Found' then error(res) end
            if path:find('.lua') then
                res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
            end
            writefile(path, res)
        end
        return (func or readfile)(path)
    end

    local function wipeFolder(path)
        if not isfolder(path) then return end
        for _, file in listfiles(path) do
            if file:find('loader') then continue end
            if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
                delfile(file)
            end
        end
    end

    local function downloadPremadeProfiles(commit)
        local httpService = game:GetService('HttpService')
        if not isfolder('newvape/profiles/premade') then makefolder('newvape/profiles/premade') end
        local success, response = pcall(function()
            return game:HttpGet('https://api.github.com/repos/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/contents/profiles/premade?ref=' .. commit)
        end)
        if success and response then
            local ok, files = pcall(function() return httpService:JSONDecode(response) end)
            if ok and type(files) == 'table' then
                for _, file in pairs(files) do
                    if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                        local filePath = 'newvape/profiles/premade/' .. file.name
                        if not isfile(filePath) then
                            local dl = file.download_url or ('https://raw.githubusercontent.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/' .. commit .. '/profiles/premade/' .. file.name)
                            local ds, dc = pcall(function() return game:HttpGet(dl, true) end)
                            if ds and dc and dc ~= '404: Not Found' then writefile(filePath, dc) end
                        end
                    end
                end
            end
        else
            for _, profileName in ipairs({'aero6872274481.txt', 'aero6872265039.txt'}) do
                local filePath = 'newvape/profiles/premade/' .. profileName
                if not isfile(filePath) then
                    local ds, dc = pcall(function() return game:HttpGet('https://raw.githubusercontent.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/' .. commit .. '/profiles/premade/' .. profileName, true) end)
                    if ds and dc ~= '404: Not Found' then writefile(filePath, dc) end
                end
            end
        end
    end

    for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/profiles/premade', 'newvape/assets', 'newvape/libraries', 'newvape/guis', 'newvape/security'} do
        if not isfolder(folder) then makefolder(folder) end
    end

    if not shared.VapeDeveloper then
        local _, subbed = pcall(function() return game:HttpGet('https://github.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME) end)
        local commit = subbed:find('currentOid')
        commit = commit and subbed:sub(commit + 13, commit + 52) or nil
        commit = commit and #commit == 40 and commit or 'main'

        local needsUpdate = commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit
        if needsUpdate then
            wipeFolder('newvape')
            wipeFolder('newvape/games')
            wipeFolder('newvape/guis')
            wipeFolder('newvape/libraries')
        end

        downloadPremadeProfiles(commit)
        writefile('newvape/profiles/commit.txt', commit)
    end

    shared.ValidatedUsername = passedArgs.Username
    shared.VapeAccountType = "premium"
    return loadstring(downloadFile('newvape/main.lua'), 'main')()
end

local hasValidation, validatedUsername, accountType = checkExistingValidation()
if hasValidation then
    shared.ValidatedUsername = validatedUsername
    shared.VapeAccountType = accountType

    local isfile = isfile or function(file)
        local suc, res = pcall(function() return readfile(file) end)
        return suc and res ~= nil and res ~= ''
    end
    local delfile = delfile or function(file) writefile(file, '') end

    local function downloadFile(path, func)
        if not isfile(path) then
            local suc, res = pcall(function()
                return game:HttpGet('https://raw.githubusercontent.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/' .. readfile('newvape/profiles/commit.txt') .. '/' .. select(1, path:gsub('newvape/', '')), true)
            end)
            if not suc or res == '404: Not Found' then error(res) end
            if path:find('.lua') then
                res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n' .. res
            end
            writefile(path, res)
        end
        return (func or readfile)(path)
    end

    local function wipeFolder(path)
        if not isfolder(path) then return end
        for _, file in listfiles(path) do
            if file:find('loader') then continue end
            if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
                delfile(file)
            end
        end
    end

    local function downloadPremadeProfiles(commit)
        local httpService = game:GetService('HttpService')
        if not isfolder('newvape/profiles/premade') then makefolder('newvape/profiles/premade') end
        local success, response = pcall(function()
            return game:HttpGet('https://api.github.com/repos/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/contents/profiles/premade?ref=' .. commit)
        end)
        if success and response then
            local ok, files = pcall(function() return httpService:JSONDecode(response) end)
            if ok and type(files) == 'table' then
                for _, file in pairs(files) do
                    if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
                        local filePath = 'newvape/profiles/premade/' .. file.name
                        if not isfile(filePath) then
                            local dl = file.download_url or ('https://raw.githubusercontent.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/' .. commit .. '/profiles/premade/' .. file.name)
                            local ds, dc = pcall(function() return game:HttpGet(dl, true) end)
                            if ds and dc and dc ~= '404: Not Found' then writefile(filePath, dc) end
                        end
                    end
                end
            end
        else
            for _, profileName in ipairs({'aero6872274481.txt', 'aero6872265039.txt'}) do
                local filePath = 'newvape/profiles/premade/' .. profileName
                if not isfile(filePath) then
                    local ds, dc = pcall(function() return game:HttpGet('https://raw.githubusercontent.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME .. '/' .. commit .. '/profiles/premade/' .. profileName, true) end)
                    if ds and dc ~= '404: Not Found' then writefile(filePath, dc) end
                end
            end
        end
    end

    for _, folder in {'newvape', 'newvape/games', 'newvape/profiles', 'newvape/profiles/premade', 'newvape/assets', 'newvape/libraries', 'newvape/guis', 'newvape/security'} do
        if not isfolder(folder) then makefolder(folder) end
    end

    if not shared.VapeDeveloper then
        local _, subbed = pcall(function() return game:HttpGet('https://github.com/' .. EXPECTED_REPO_OWNER .. '/' .. EXPECTED_REPO_NAME) end)
        local commit = subbed:find('currentOid')
        commit = commit and subbed:sub(commit + 13, commit + 52) or nil
        commit = commit and #commit == 40 and commit or 'main'

        local needsUpdate = commit == 'main' or (isfile('newvape/profiles/commit.txt') and readfile('newvape/profiles/commit.txt') or '') ~= commit
        if needsUpdate then
            wipeFolder('newvape')
            wipeFolder('newvape/games')
            wipeFolder('newvape/guis')
            wipeFolder('newvape/libraries')
        end

        downloadPremadeProfiles(commit)
        writefile('newvape/profiles/commit.txt', commit)
    end

    return loadstring(downloadFile('newvape/main.lua'), 'main')()
end
