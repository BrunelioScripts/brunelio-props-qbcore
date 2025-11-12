local QBCore = exports['qb-core']:GetCoreObject()

local spawnedProps = {} -- Tabela para armazenar os props spawnados com suas informações
local isNUIOpen = false
local hasPermission = false

-- Função para spawnar um prop de forma genérica e fixá-lo no chão
function spawnProp(propName, coords, heading)
    local propHash = GetHashKey(propName)
    
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do
        Wait(500)
    end
    
    local prop = CreateObject(propHash, coords.x, coords.y, coords.z, false, false, true)
    SetEntityHeading(prop, heading)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetModelAsNoLongerNeeded(propHash)
    
    -- Impede que a prop seja deletada automaticamente
    SetEntityAsMissionEntity(prop, true, true)
    
    -- Armazena o prop com suas informações completas
    table.insert(spawnedProps, {
        entity = prop,
        model = propName,
        coords = coords,
        heading = heading
    })
    
    -- Envia os dados do prop para o servidor salvar no banco de dados
    TriggerServerEvent('saveProp', {
        model = propName,
        coords = coords,
        heading = heading
    })
    
    return prop
end

-- Evento para carregar props existentes quando o jogador entrar no servidor
RegisterNetEvent('loadExistingProps', function(props)
    -- Limpa props existentes
    for _, propData in ipairs(spawnedProps) do
        if DoesEntityExist(propData.entity) then
            DeleteEntity(propData.entity)
        end
    end
    spawnedProps = {}
    
    -- Carrega as props do servidor
    for _, propData in ipairs(props) do
        spawnProp(propData.model, propData.coords, propData.heading)
    end
end)

-- Verificar permissão antes de abrir a NUI
function CheckPermission()
    TriggerServerEvent('checkPropManagerPermission')
end

-- Receber resposta da verificação de permissão
RegisterNetEvent('propManagerPermissionResponse', function(allowed)
    hasPermission = allowed
end)

-- Modificar a função ToggleNUI
function ToggleNUI(show)
    if show and not hasPermission then
        -- Notificar o jogador que não tem permissão
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"SISTEMA", "Você não tem permissão para usar o Gerenciador de Props!"}
        })
        return
    end
    
    isNUIOpen = show
    SetNuiFocus(show, show)
    SendNUIMessage({
        type = show and 'show' or 'hide'
    })
end

-- Modificar o comando para verificar permissão primeiro
RegisterCommand('propmanager', function()
    if not hasPermission then
        CheckPermission()
        Wait(100) -- Pequeno delay para receber a resposta do servidor
    end
    ToggleNUI(true)
end, false)

-- Registrar a tecla de atalho (opcional)
RegisterKeyMapping('propmanager', 'Abrir Gerenciador de Props', 'keyboard', 'F5')

-- Callbacks da NUI
RegisterNUICallback('closeNUI', function(data, cb)
    print("Fechando NUI") -- Debug print
    ToggleNUI(false)
    cb('ok')
end)

RegisterNUICallback('getCurrentPosition', function(data, cb)
    print("Callback getCurrentPosition chamado") -- Debug
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local response = {
        position = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        heading = heading
    }
    
    print("Enviando coordenadas:", json.encode(response)) -- Debug
    cb(response)
end)

RegisterNUICallback('spawnProp', function(data, cb)
    if data.propName and data.coords then
        spawnProp(data.propName, data.coords, data.heading)
    end
    cb('ok')
end)

-- Evento para remover prop do jogo quando for removida do banco de dados
RegisterNetEvent('removePropFromGame', function(coords)
    for i, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop.entity) then
            local propCoords = GetEntityCoords(prop.entity)
            if math.abs(propCoords.x - coords.x) < 0.1 and 
               math.abs(propCoords.y - coords.y) < 0.1 and 
               math.abs(propCoords.z - coords.z) < 0.1 then
                DeleteEntity(prop.entity)
                table.remove(spawnedProps, i)
                print("Prop removida do jogo nas coordenadas:", json.encode(coords))
                break
            end
        end
    end
end)

-- Modificar o callback removeNearestProp para esperar a confirmação do servidor
RegisterNUICallback('removeNearestProp', function(data, cb)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local closestDistance = 1000.0
    local closestProp = nil
    local closestIndex = nil
    
    for i, propData in ipairs(spawnedProps) do
        if DoesEntityExist(propData.entity) then
            local distance = #(coords - GetEntityCoords(propData.entity))
            if distance < closestDistance then
                closestDistance = distance
                closestProp = propData
                closestIndex = i
            end
        end
    end
    
    if closestProp and closestDistance < 5.0 then
        print("Removendo prop nas coordenadas:", json.encode(closestProp.coords))
        
        -- Remove a entidade do jogo
        DeleteEntity(closestProp.entity)
        table.remove(spawnedProps, closestIndex)
        
        -- Envia para o servidor remover do banco de dados
        TriggerServerEvent('removePropFromSQL', {
            coords = closestProp.coords,
            model = closestProp.model
        })
        
        cb({success = true, message = "Prop removida com sucesso!"})
    else
        cb({success = false, message = "Nenhuma prop encontrada próxima."})
    end
end)

-- Comando: /spawnprop
RegisterCommand('spawnprop', function(source, args, rawCommand)
    if not hasPermission then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"SISTEMA", "Você não tem permissão para usar este comando!"}
        })
        return
    end
    
    if #args < 1 then
        print("Use: /spawnprop [nome_do_prop]")
        return
    end
    
    local propName = args[1]
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    spawnProp(propName, coords, heading)
end, false)

-- Comando: /removeprop
RegisterCommand('removeprop', function(source, args, rawCommand)
    if not hasPermission then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"SISTEMA", "Você não tem permissão para usar este comando!"}
        })
        return
    end
    
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local closestDistance = 1000.0
    local closestProp = nil
    local closestIndex = nil
    
    for i, prop in ipairs(spawnedProps) do
        if DoesEntityExist(prop.entity) then
            local distance = #(coords - GetEntityCoords(prop.entity))
            if distance < closestDistance then
                closestDistance = distance
                closestProp = prop
                closestIndex = i
            end
        end
    end
    
    if closestProp and closestDistance < 5.0 then
        local propCoords = GetEntityCoords(closestProp.entity)
        DeleteEntity(closestProp.entity)
        table.remove(spawnedProps, closestIndex)
        
        TriggerServerEvent('removeProp', {
            coords = {
                x = propCoords.x,
                y = propCoords.y,
                z = propCoords.z
            }
        })
        print("Prop removido com sucesso! (Distância: " .. closestDistance .. ")")
    else
        print("Nenhum prop próximo encontrado para remover. Distância mínima: " .. closestDistance)
    end
end, false)

-- Atualiza coordenadas constantemente para a NUI
local function UpdateNUICoords()
    if isNUIOpen then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)
        
        SendNUIMessage({
            type = 'updatePosition',
            position = coords,
            heading = heading
        })
    end
end
