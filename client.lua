local inCameraMode = false
local cameraObject = nil
local currentCameraIndex = 1
local currentCameraName = 'Aucun'
local canRotate = false
local cameraConfig = {}

local Config = {

    enterCameraMode = 38,
    exitCameraMode = 194,
    cameraChangeDelay = true,

    cameraAccess = {
        coords = vector3(440.19, -975.72, 30.69),
        color = { red = 0, green = 150, blue = 250 },
        alpha = 255
    },

    cameras = {
        { name = 'Entrée poste de police', position = vector3(433.92, -978.004, 33.04), rotation = vector3(-33.29, -1.7, 137.09), canRotate = true },
        { name = 'Accueil poste de police', position = vector3(449.574, -988.83, 32.21), rotation = vector3(-3.0, 1.6, 44.99), canRotate = true },
        { name = 'Cellules poste de police', position = vector3(465.18, -985.05, 27.67), rotation = vector3(-24.88, -0.0, 128.69), canRotate = false },
        { name = 'Parking poste de police', position = vector3(438.42, -999.68, 33.5), rotation = vector3(-27.57, -0.0, -135.6), canRotate = true }
    }
}

local Button = function(controlButton)
    N_0xe83a3e3557a56640(controlButton)
end

local RegisterButton = function(id, controls, text)
    PushScaleformMovieFunction(scaleformButton, "SET_DATA_SLOT")
    PushScaleformMovieFunctionParameterInt(id)

    for _, control in pairs(controls) do
        Button(GetControlInstructionalButton(2, control, true))
    end

    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
    PopScaleformMovieFunctionVoid()
end

local SetupScaleform = function(scaleformSelected)
    scaleformButton = RequestScaleformMovie(scaleformSelected)
    while not HasScaleformMovieLoaded(scaleformButton) do
        Citizen.Wait(0)
    end

    DrawScaleformMovieFullscreen(scaleformButton, 255, 255, 255, 0, 0)

    PushScaleformMovieFunction(scaleformButton, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()
    
    PushScaleformMovieFunction(scaleformButton, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    RegisterButton(0, { Config.exitCameraMode }, "Arrêter la caméra")
    RegisterButton(1, { 109, 108 }, "Changer de caméra")
    RegisterButton(2, { 172, 173, 174, 175 }, "Bouger la caméra")

    PushScaleformMovieFunction(scaleformButton, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(scaleformButton, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(80)
    PopScaleformMovieFunctionVoid()

    return scaleformButton
end

local ShowHelpText = function(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local EnterCameraMode = function()
    local playerPed = PlayerPedId()
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_COP_IDLES", 0, true)
    FreezeEntityPosition(playerPed, true)
    SetEntityHeading(playerPed, 0.0)
    DisplayRadar(false)

    local cameraCoords = cameraConfig[currentCameraIndex].position
    local cameraRotation = cameraConfig[currentCameraIndex].rotation
    currentCameraName = cameraConfig[currentCameraIndex].name
    canRotate = cameraConfig[currentCameraIndex].canRotate

    cameraObject = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cameraObject, cameraCoords)
    SetCamRot(cameraObject, cameraRotation)
    SetCamActive(cameraObject, true)
    RenderScriptCams(true, false, 0, true, true)
    SetTimecycleModifier('CAMERA_BW')

    inCameraMode = true

    Citizen.CreateThread(function()
        while inCameraMode do

            local form = SetupScaleform("instructional_buttons")
            DrawScaleformMovieFullscreen(form, 255, 255, 255, 255, 0)
            ShowHelpText(("Caméra n°%s/%s (%s)"):format(currentCameraIndex, #cameraConfig, currentCameraName))

            if canRotate then
                local rotationSpeed = 0.3

                if IsControlPressed(0, 173) then
                    local currentRotation = GetCamRot(cameraObject)
                    local newRoation = currentRotation.x - rotationSpeed
                    if newRoation > -60.0 then
                        SetCamRot(cameraObject, newRoation, currentRotation.y, currentRotation.z)
                    end
                elseif IsControlPressed(0, 172) then
                    local currentRotation = GetCamRot(cameraObject)
                    local newRoation = currentRotation.x + rotationSpeed
                    if newRoation < 10.0 then
                        SetCamRot(cameraObject, newRoation, currentRotation.y, currentRotation.z)
                    end
                elseif IsControlPressed(0, 174) then
                    local currentRotation = GetCamRot(cameraObject)
                    SetCamRot(cameraObject, currentRotation.x, currentRotation.y, currentRotation.z + rotationSpeed)
                elseif IsControlPressed(0, 175) then
                    local currentRotation = GetCamRot(cameraObject)
                    SetCamRot(cameraObject, currentRotation.x, currentRotation.y, currentRotation.z - rotationSpeed)
                end
            end

            Citizen.Wait(0)
        end
    end)
end

local ExitCameraMode = function()
    SetTimecycleModifier('default')
    FreezeEntityPosition(PlayerPedId(), false)
    ClearPedTasks(PlayerPedId())
    DisplayRadar(true)

    inCameraMode = false

    if cameraObject ~= nil then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(cameraObject)
        cameraObject = nil
    end
end

Citizen.CreateThread(function()

    cameraConfig = Config.cameras

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local distance = #(playerCoords - Config.cameraAccess.coords)

        DrawMarker(1, Config.cameraAccess.coords.x, Config.cameraAccess.coords.y, Config.cameraAccess.coords.z - 1.0, 0, 0, 0, 0, 0, 0, 1.0, 1.0, 1.0, Config.cameraAccess.color.red, Config.cameraAccess.color.green, Config.cameraAccess.color.blue, Config.cameraAccess.alpha, false, true, 2, false, nil, nil, false)

        if distance < 0.5 and not inCameraMode then
            ShowHelpText("Appuyez sur ~INPUT_CONTEXT~ pour accéder aux caméras.")

            if IsControlJustReleased(0, Config.enterCameraMode) then
                EnterCameraMode()
            end
        end

        if inCameraMode then

            if IsControlJustReleased(0, Config.exitCameraMode) then
                ExitCameraMode()  
            elseif IsControlJustReleased(0, 108) then
                
                if Config.cameraChangeDelay then
                    Citizen.Wait(500)
                end

                currentCameraIndex = currentCameraIndex - 1
                if currentCameraIndex < 1 then
                    currentCameraIndex = #cameraConfig
                end
                ExitCameraMode()
                EnterCameraMode()
            elseif IsControlJustReleased(0, 109) then

                if Config.cameraChangeDelay then
                    Citizen.Wait(500)
                end

                currentCameraIndex = currentCameraIndex + 1
                if currentCameraIndex > #cameraConfig then
                    currentCameraIndex = 1
                end
                ExitCameraMode()
                EnterCameraMode()
            end
        end

        Citizen.Wait(0)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        SetTimecycleModifier('default')
        ClearPedTasks(PlayerPedId())
        DisplayRadar(true)
        FreezeEntityPosition(PlayerPedId(), false)
    end
end)