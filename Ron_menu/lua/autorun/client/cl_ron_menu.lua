-- === СИСТЕМА СОХРАНЕНИЯ ===
if not file.Exists("ron_loadouts", "DATA") then file.CreateDir("ron_loadouts") end

-- Функция сбора оружия (теперь она более надежная)
local function BuildWeaponDB()
    local db = {}
    local blacklist = { ["weapon_flechette"] = true, ["weapon_manhack"] = true, ["weapon_physgun"] = true, ["gmod_tool"] = true, ["gmod_camera"] = true, ["weapon_physcannon"] = true, ["weapon_medkit"] = true }

    for _, wep in ipairs(weapons.GetList()) do
        if not wep.Spawnable or blacklist[wep.ClassName] then continue end
        
        table.insert(db, { 
            class = wep.ClassName, 
            name = string.upper(wep.PrintName or wep.ClassName), 
            model = wep.WorldModel or "models/weapons/w_pistol.mdl" 
        })
    end
    table.sort(db, function(a, b) return a.name < b.name end)
    return db
end

-- === РЕГИСТРАЦИЯ ШРИФТОВ ===
surface.CreateFont("RON_Header", { font = "Arial", size = 64, weight = 800, extended = true })
surface.CreateFont("RON_Tab", { font = "Arial", size = 16, weight = 800, extended = true })
surface.CreateFont("RON_Label", { font = "Arial", size = 14, weight = 600, extended = true })
surface.CreateFont("RON_Small", { font = "Arial", size = 12, weight = 400, extended = true })

local function OpenCommanderMenu()
    local weaponDB = BuildWeaponDB() -- Собираем актуальный список при открытии
    local selectedPlayer = LocalPlayer()
    local squadLoadouts = {} 
    local lastWeaponModel = "models/weapons/w_pistol.mdl"

    local function CheckPly(ply)
        if IsValid(ply) and not squadLoadouts[ply] then squadLoadouts[ply] = {} end
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(1200, 800); frame:Center(); frame:MakePopup(); frame:SetTitle(""); frame:ShowCloseButton(false)
    frame.Paint = function(self, w, h)
        surface.SetDrawColor(15, 15, 15, 250); surface.DrawRect(0, 0, w, h)
        draw.SimpleText("EQUIPMENT", "RON_Header", 30, 20, Color(255, 255, 255))
    end

    -- Кнопка закрытия
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(80, 25); closeBtn:SetPos(1090, 15); closeBtn:SetText("QUIT  X"); closeBtn:SetFont("RON_Label"); closeBtn:SetTextColor(Color(255, 255, 255))
    closeBtn.Paint = function(self, w, h) surface.SetDrawColor(255, 255, 255); surface.DrawOutlinedRect(0, 0, w, h) end
    closeBtn.DoClick = function() frame:Close() end

    -- Панель игроков
    local playerScroll = vgui.Create("DHorizontalScroller", frame)
    playerScroll:SetPos(30, 100); playerScroll:SetSize(650, 120)

    local function RefreshUI() end

    local function RefreshPlayers()
        playerScroll:Clear()
        for _, ply in ipairs(player.GetAll()) do
            CheckPly(ply)
            local pnl = vgui.Create("DButton")
            pnl:SetWide(90); pnl:SetText("")
            pnl.DoClick = function() selectedPlayer = ply; RefreshUI(); surface.PlaySound("UI/buttonrollover.wav") end
            pnl.Paint = function(self, w, h)
                if not IsValid(ply) then return end
                local isSelected = (selectedPlayer == ply)
                surface.SetDrawColor(255, 255, 255, isSelected and 200 or 50)
                surface.DrawOutlinedRect(5, 15, 80, 80)
            end
            local ava = vgui.Create("AvatarImage", pnl); ava:SetSize(78, 78); ava:SetPos(6, 16); ava:SetPlayer(ply, 128)
            local name = vgui.Create("DLabel", pnl); name:SetText(string.upper(ply:Nick())); name:SetFont("RON_Label"); name:SetPos(0, 100); name:SetWide(90); name:SetContentAlignment(5); name:SetTextColor(Color(255, 255, 255))
            playerScroll:AddPanel(pnl)
        end
    end
    RefreshPlayers()

    -- Трапеции пресетов
-- Трапеции пресетов
    for i = 1, 6 do
        local t = vgui.Create("DButton", frame)
        t:SetSize(95, 30); t:SetPos(30 + (i-1)*100, 250); t:SetText("")
        t.Paint = function(self, w, h)
            local hover = self:IsHovered()
            
            -- Точки для построения трапеции
            local poly = {{x=0,y=h}, {x=8,y=0}, {x=w-8,y=0}, {x=w,y=h}}
            
            -- Заливка слегка заметным серым фоном (при наведении становится ярче)
            surface.SetDrawColor(255, 255, 255, hover and 20 or 5)
            surface.DrawPoly(poly)
            
            -- Белый тактический контур рамки
            surface.SetDrawColor(255, 255, 255, hover and 150 or 60)
            -- Отрисовка линий по точкам полигона, чтобы была рамка-трапеция
            for k = 1, #poly do
                local p1 = poly[k]
                local p2 = poly[k == #poly and 1 or k + 1]
                surface.DrawLine(p1.x, p1.y, p2.x, p2.y)
            end
            
            -- Белый или серый текст (в зависимости от наведения мыши)
            local textColor = hover and Color(255, 255, 255) or Color(180, 180, 180)
            draw.SimpleText("PRESET " .. i, "RON_Tab", w / 2, h / 2, textColor, 1, 1)
        end
        t.DoClick = function()
            local path = "ron_loadouts/preset_" .. i .. ".txt"
            if file.Exists(path, "DATA") then
                squadLoadouts[selectedPlayer] = util.JSONToTable(file.Read(path, "DATA"))
                RefreshUI()
            end
        end
        t.DoRightClick = function()
            file.Write("ron_loadouts/preset_" .. i .. ".txt", util.TableToJSON(squadLoadouts[selectedPlayer]))
            surface.PlaySound("garrysmod/save_load1.wav")
        end
    end

    -- Список выбранного оружия
    local listScroll = vgui.Create("DScrollPanel", frame)
    listScroll:SetPos(30, 300); listScroll:SetSize(450, 400)
    
    RefreshUI = function()
        listScroll:Clear()
        CheckPly(selectedPlayer)
        for i, class in ipairs(squadLoadouts[selectedPlayer]) do
            local item = listScroll:Add("DPanel")
            item:Dock(TOP); item:SetHeight(40); item:DockMargin(0, 0, 0, 5)
            item.Paint = function(self, w, h)
                surface.SetDrawColor(255, 255, 255, 20); surface.DrawRect(0, 0, w, h)
                draw.SimpleText(string.upper(class), "RON_Label", 10, h/2, Color(255, 255, 255), 0, 1)
            end
            local del = vgui.Create("DButton", item)
            del:SetText("X"); del:Dock(RIGHT); del:SetWide(40); del:SetTextColor(Color(255, 50, 50)); del.Paint = nil
            del.DoClick = function() table.remove(squadLoadouts[selectedPlayer], i); RefreshUI() end
        end
    end

    -- === СТИЛИЗОВАННОЕ ОКНО ВЫБОРА ОРУЖИЯ ===
    local function OpenSelector()
        local selFrame = vgui.Create("DFrame")
        selFrame:SetSize(400, 600); selFrame:Center(); selFrame:SetTitle(""); selFrame:MakePopup(); selFrame:ShowCloseButton(false)
        selFrame.Paint = function(self, w, h)
            surface.SetDrawColor(10, 10, 10, 253); surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 255, 255, 100); surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText("SELECT ARMAMENT", "RON_Tab", 10, 10, Color(255, 255, 255))
        end

        local cBtn = vgui.Create("DButton", selFrame)
        cBtn:SetSize(40, 20); cBtn:SetPos(355, 10); cBtn:SetText("X"); cBtn:SetTextColor(Color(255,255,255)); cBtn.Paint = nil
        cBtn.DoClick = function() selFrame:Close() end

        local search = vgui.Create("DTextEntry", selFrame)
        search:Dock(TOP); search:SetHeight(30); search:DockMargin(10, 40, 10, 10)
        search:SetPlaceholderText("SEARCH WEAPON...")
        search:SetFont("RON_Small")
        search.Paint = function(self, w, h)
            surface.SetDrawColor(255, 255, 255, 10); surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(255, 255, 255, 50); surface.DrawOutlinedRect(0, 0, w, h)
            self:DrawTextEntryText(Color(255, 255, 255), Color(100, 100, 255), Color(255, 255, 255))
        end

        local sScroll = vgui.Create("DScrollPanel", selFrame)
        sScroll:Dock(FILL); sScroll:DockMargin(10, 0, 10, 10)

        local function Populate(filter)
            sScroll:Clear()
            for _, wep in ipairs(weaponDB) do
                if filter and filter ~= "" and not string.find(string.lower(wep.name), string.lower(filter)) then continue end
                
                local b = sScroll:Add("DButton")
                b:SetText(""); b:Dock(TOP); b:SetHeight(35); b:DockMargin(0, 0, 0, 2)
                b.Paint = function(self, w, h)
                    local hover = self:IsHovered()
                    surface.SetDrawColor(255, 255, 255, hover and 30 or 10)
                    surface.DrawRect(0, 0, w, h)
                    draw.SimpleText(wep.name, "RON_Label", 10, h/2, Color(255, 255, 255), 0, 1)
                    if hover then surface.SetDrawColor(255, 255, 255, 100); surface.DrawOutlinedRect(0, 0, w, h) end
                end
                b.DoClick = function()
                    table.insert(squadLoadouts[selectedPlayer], wep.class)
                    lastWeaponModel = wep.model
                    RefreshUI(); selFrame:Close(); surface.PlaySound("UI/buttonrollover.wav")
                end
            end
        end
        search.OnChange = function(s) Populate(s:GetValue()) end
        Populate()
    end

    local addBtn = vgui.Create("DButton", frame)
    addBtn:SetPos(30, 710); addBtn:SetSize(450, 40); addBtn:SetText("+ ADD WEAPON"); addBtn:SetFont("RON_Tab"); addBtn:SetTextColor(Color(255, 255, 255))
    addBtn.Paint = function(s, w, h) 
        surface.SetDrawColor(255, 255, 255, s:IsHovered() and 150 or 100)
        surface.DrawOutlinedRect(0, 0, w, h) 
    end
    addBtn.DoClick = function() OpenSelector() end

    -- Правая панель
    local rightPanel = vgui.Create("DPanel", frame)
    rightPanel:SetPos(700, 100); rightPanel:SetSize(470, 550)
    local img = vgui.Create("SpawnIcon", rightPanel); img:SetSize(128, 128); img:SetPos(170, 40)

    rightPanel.Paint = function(self, w, h)
        surface.SetDrawColor(255, 255, 255, 50); surface.DrawOutlinedRect(0, 0, w, 220)
        surface.DrawOutlinedRect(0, 230, w, 320)
        if IsValid(selectedPlayer) then
            img:SetModel(lastWeaponModel)
            draw.SimpleText("SELECTED: " .. string.upper(selectedPlayer:Nick()), "RON_Tab", 20, 245, Color(255, 255, 255))
            local list = squadLoadouts[selectedPlayer] or {}
            for i = 1, math.min(#list, 10) do
                draw.SimpleText(i .. ". " .. string.upper(list[i]), "RON_Small", 20, 275 + (i*22), Color(200, 200, 200))
            end
        end
    end

    -- Кнопка применения
    local btnApply = vgui.Create("DButton", frame)
    btnApply:SetSize(250, 40); btnApply:SetPos(920, 710); btnApply:SetText("ASSIGN TO ALL"); btnApply:SetFont("RON_Tab"); btnApply:SetTextColor(Color(255,255,255))
    btnApply.Paint = function(s, w, h) surface.SetDrawColor(255, 255, 255); surface.DrawOutlinedRect(0, 0, w, h) end
    btnApply.DoClick = function()
    local data = {}
        for _, p in ipairs(player.GetAll()) do 
            -- Берем снаряжение конкретного игрока (p), а не выбранного (selectedPlayer)
            if squadLoadouts[p] then
                data[p:EntIndex()] = squadLoadouts[p] 
            end
        end
        net.Start("RON_SaveSquadLoadout"); net.WriteTable(data); net.SendToServer()
        surface.PlaySound("buttons/lightswitch2.wav")
    end

    RefreshUI()
end

concommand.Add("CapitanMenu", OpenCommanderMenu)
