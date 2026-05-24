-- === СЕРВЕРНАЯ ЧАСТЬ СИСТЕМЫ СНАРЯЖЕНИЯ ===

-- Регистрируем сетевой канал, чтобы сервер мог получать данные от клиента
util.AddNetworkString("RON_SaveSquadLoadout")

-- Функция, которая срабатывает, когда командир нажимает "ASSIGN TO ALL"
net.Receive("RON_SaveSquadLoadout", function(len, ply)
    local data = net.ReadTable()
    if not data then return end

    for entIndex, loadout in pairs(data) do
        local target = Entity(entIndex)
        
        if IsValid(target) and target:IsPlayer() and target:Alive() then
            -- Строка target:StripWeapons() удалена. 
            -- Теперь старый инвентарь не трогается!
            
            -- Выдаем новое оружие поверх старого
            for _, wepClass in ipairs(loadout) do
                target:Give(wepClass)
            end
        end
    end
    -- Можно вывести сообщение в чат для подтверждения
    PrintMessage(HUD_PRINTTALK, "[КОМАНДОВАНИЕ] " .. ply:Nick() .. " обновил снаряжение отряда.")
end)