local QBCore = exports['qb-core']:GetCoreObject()

-- Configuração do banco de dados
local props = {}

-- Lista de grupos permitidos (usa permissões do QBCore)
local allowedGroups = {
    ['god'] = true,
    ['admin'] = true,
    ['mod'] = true
}

-- Função para verificar se o jogador tem permissão
function hasPermission(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end

    local group = nil
    local data = Player.PlayerData or {}

    -- Tentativas diretas
    if QBCore.Functions.GetPermission then
        local perm = QBCore.Functions.GetPermission(source)
        if type(perm) == "string" then
            group = perm
        elseif type(perm) == "table" then
            for k, v in pairs(perm) do
                if v == true then group = k break end
            end
        end
    end

    -- Se ainda não encontrou, tenta nas estruturas novas do QBX
    if not group then
        local permData = data.permission or data.perms or data.groups
        if type(permData) == "string" then
            group = permData
        elseif type(permData) == "table" then
            for k, v in pairs(permData) do
                if v == true then group = k break end
            end
        elseif data.group and type(data.group) == "string" then
            group = data.group
        end
    end

    -- Caso nada funcione, tenta verificar se tem função de permissão nova
    if not group and QBCore.Functions.HasPermission then
        if QBCore.Functions.HasPermission(source, 'god') then
            group = 'god'
        elseif QBCore.Functions.HasPermission(source, 'admin') then
            group = 'admin'
        elseif QBCore.Functions.HasPermission(source, 'mod') then
            group = 'mod'
        end
    end

    print(("[DEBUG] Jogador %s tem grupo detectado: %s"):format(GetPlayerName(source), tostring(group)))

    return group and allowedGroups[group] == true
end



-- Evento para verificar permissão
RegisterNetEvent('checkPropManagerPermission', function()
    local src = source
    local hasAccess = hasPermission(src)

    TriggerClientEvent('propManagerPermissionResponse', src, hasAccess)

    if not hasAccess then
        print(GetPlayerName(src) .. " tentou acessar o Prop Manager sem permissão")
    end
end)

-- Criar a tabela se não existir
CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS props (
            id INT AUTO_INCREMENT PRIMARY KEY,
            model VARCHAR(255),
            coords_x FLOAT,
            coords_y FLOAT,
            coords_z FLOAT,
            heading FLOAT,
            permanent BOOLEAN DEFAULT TRUE
        )
    ]])
    
    -- Carregar props existentes do banco de dados
    LoadPropsFromDatabase()
end)

-- Função para carregar props do banco de dados
function LoadPropsFromDatabase()
    exports.oxmysql:execute('SELECT * FROM props WHERE permanent = TRUE', {}, function(results)
        if results then
            for _, propData in ipairs(results) do
                table.insert(props, {
                    model = propData.model,
                    coords = {
                        x = propData.coords_x,
                        y = propData.coords_y,
                        z = propData.coords_z
                    },
                    heading = propData.heading
                })
            end
            -- Envia todas as props para todos os jogadores
            TriggerClientEvent('loadExistingProps', -1, props)
        end
    end)
end

-- Evento para salvar uma nova prop
RegisterNetEvent('saveProp', function(propData)
    local src = source
    if not hasPermission(src) then
        print(GetPlayerName(src) .. " tentou salvar uma prop sem permissão")
        return
    end
    
    -- Salva no array local
    table.insert(props, propData)
    
    -- Salva no banco de dados com permanent = true
    exports.oxmysql:execute('INSERT INTO props (model, coords_x, coords_y, coords_z, heading, permanent) VALUES (?, ?, ?, ?, ?, TRUE)', {
        propData.model,
        propData.coords.x,
        propData.coords.y,
        propData.coords.z,
        propData.heading
    })
end)

-- Evento para remover uma prop
RegisterNetEvent('removeProp', function(propData)
    print("Tentando remover prop nas coordenadas:", json.encode(propData.coords)) -- Debug
    
    -- Remove do array local
    for i, prop in ipairs(props) do
        if math.abs(prop.coords.x - propData.coords.x) < 0.1 and 
           math.abs(prop.coords.y - propData.coords.y) < 0.1 and 
           math.abs(prop.coords.z - propData.coords.z) < 0.1 then
            table.remove(props, i)
            break
        end
    end
    
    -- Remove do banco de dados
    local query = [[
        DELETE FROM props 
        WHERE ABS(coords_x - ?) < 0.1 
        AND ABS(coords_y - ?) < 0.1 
        AND ABS(coords_z - ?) < 0.1
    ]]
    
    exports.oxmysql:execute(query, {
        propData.coords.x,
        propData.coords.y,
        propData.coords.z
    }, function(affectedRows)
        print("Linhas afetadas na remoção:", affectedRows) -- Debug
        -- Notifica todos os outros clientes para remover a prop
        TriggerClientEvent('removePropFromGame', -1, propData.coords)
    end)
end)

-- Evento específico para remover prop do SQL
RegisterNetEvent('removePropFromSQL', function(propData)
    local src = source
    if not hasPermission(src) then
        print(GetPlayerName(src) .. " tentou remover uma prop sem permissão")
        return
    end
    
    print("Removendo prop do SQL nas coordenadas:", json.encode(propData.coords))
    
    -- Remove do banco de dados
    local query = [[
        DELETE FROM props 
        WHERE 
        model = ? AND
        coords_x BETWEEN ? - 0.5 AND ? + 0.5
        AND coords_y BETWEEN ? - 0.5 AND ? + 0.5
        AND coords_z BETWEEN ? - 0.5 AND ? + 0.5
    ]]
    
    exports.oxmysql:execute(query, {
        propData.model,
        propData.coords.x, propData.coords.x,
        propData.coords.y, propData.coords.y,
        propData.coords.z, propData.coords.z
    }, function(affectedRows)
        print("Props removidas do SQL:", affectedRows)
        if affectedRows > 0 then
            print("Prop removida com sucesso do banco de dados!")
            TriggerClientEvent('removePropFromGame', -1, propData.coords)
        else
            print("Nenhuma prop encontrada no banco de dados com essas coordenadas!")
            print("Coordenadas procuradas:", json.encode(propData.coords))
        end
    end)
end)

-- Quando um jogador se conecta, enviamos todas as props para ele
AddEventHandler('playerJoining', function(source)
    TriggerClientEvent('loadExistingProps', source, props)
end)
