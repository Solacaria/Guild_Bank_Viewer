GuildDataExportDB = GuildDataExportDB or {}

local frame = CreateFrame("Frame")

-- Convert time to a single number representing hours ago (for easier sorting/filtering)
local function GetTotalHoursAgo(year, month, day, hour)
    return ( (year or 0) * 12 * 30 * 24 )
         + ( (month or 0) * 30 * 24 )
         + ( (day or 0) * 24 )
         + ( hour or 0 )
end

local function CollectGuildData()

    local data = { 
        items = {},
        gold = {} 
    }

    -- ITEM LOGS
    for tab = 1, GetNumGuildBankTabs() do
        local tabName = GetGuildBankTabInfo(tab)
        QueryGuildBankLog(tab)

        for i = 1, GetNumGuildBankTransactions(tab) do 
            local type, player, itemLink, count, _, _, year, month, day, hour = GetGuildBankTransaction(tab, i)
            local time = GetTotalHoursAgo(year, month, day, hour)

        
        table.insert(data.items, { 
            tab = tabName or ("Tab "..tab), 
            type = type, 
            player = player, 
            item = itemLink, 
            count = count, 
            time = time 
        })
        table.sort(data.items, function(a, b)
            return a.time < b.time
        end)
        end
    end

    -- MONEY LOGS
    QueryGuildBankLog(-1)
    
    for i = 1, GetNumGuildBankMoneyTransactions() do
        local type, player, amount, year, month, day, hour = GetGuildBankMoneyTransaction(i)
        local time = GetTotalHoursAgo(year, month, day, hour)

        table.insert(data.gold, {
             type = type, 
             player = player, 
             amount = amount, 
             time = time 
        })
        table.sort(data.gold, function(a, b)
        return a.time < b.time
        end)
    end
    return data
end






-- Simple JSON serializer (minimal but works for our structure)
local function SerializeTable(tbl)
    local function serialize(value)
        if type(value) == "table" then
            local result = "{"
            local first = true
            for k, v in pairs(value) do
                if not first then result = result .. "," end
                first = false
                result = result .. '"' .. k .. '":' .. serialize(v)
            end
            return result .. "}"
        elseif type(value) == "string" then
            return '"' .. value:gsub('"', '\\"') .. '"'
        else
            return tostring(value)
        end
    end

    return serialize(tbl)
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function Base64Encode(data)
    return ((data:gsub('.', function(x)
        local r,binary='',x:byte()
        for i=8,1,-1 do r=r..(binary%2^i-binary%2^(i-1)>0 and '1' or '0') end
        return r
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if #x < 6 then return '' end
        local c=0
        for i=1,6 do c=c + (x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

local function ShowExportBox(text)

    local f = CreateFrame("Frame", "GuildDataExportFrame", UIParent, "BackdropTemplate")
    f:SetSize((800 * 0.75), (500 * 0.75))
    f:SetPoint("CENTER")
    f:SetBackdrop({ bgFile = "Interface/DialogFrame/UI-DialogBox-Background" })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:Raise()


    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(760)
    editBox:SetAutoFocus(true)
    editBox:SetText(text)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local copyButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    copyButton:SetSize(100, 20)
    copyButton:SetPoint("BOTTOMRIGHT", -10, -10)
    copyButton:SetText("Mark text")
    copyButton:SetScript("OnClick", function()
        editBox:HighlightText()   -- selects all text
        editBox:SetFocus()        -- focuses the EditBox for ctrl+c
    end)

    scroll:SetScrollChild(editBox)
end

SLASH_GUILDDATAEXPORT1 = "/guilddatalist"

SlashCmdList["GUILDDATAEXPORT"] = function()

    if not GuildBankFrame or not GuildBankFrame:IsShown() then
        print("Open the guild bank first.")
        return
    end

    local data = CollectGuildData()

     -- shrink field names
    for _, item in ipairs(data.items) do
        if item.type == "deposit" then item.type = "d"
        elseif item.type == "withdraw" then item.type = "w" end
    end
    for _, g in ipairs(data.gold) do
        if g.type == "deposit" then g.type = "d"
        elseif g.type == "withdraw" then g.type = "w"
        -- elseif g.type == "repair" then g.type = "r"
        end
    end

    local json = SerializeTable(data)
    json = json:gsub("%s+", "") -- remove spaces/newlines

    local encoded = Base64Encode(json)

    ShowExportBox(encoded)

    print("Guild data generated. Copy it.")
end
