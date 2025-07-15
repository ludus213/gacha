#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#Include JSON.ahk

; Install Python Dependencies
RunWait, pip install -r requirements.txt, , Hide

; Start Python Server
Run, python main.py, , Hide
Sleep, 5000 ; Wait for server to start

; GUI
Gui, Font, s10
Gui, Add, Button, x12 y10 w100 h40 gStart, Start
Gui, Add, Button, x122 y10 w100 h40 gStop, Stop
Gui, Add, Button, x232 y10 w40 h40 gSettings, ⚙️
Gui, Show, h60 w285, Auto Clicker

; Settings GUI
Gui, Settings:Font, s10
Gui, Settings:Add, Tab3, x10 y10 w380 h280, General|Coordinates|Scrolls
Gui, Settings:Tab, General
Gui, Settings:Add, Text, x20 y50, Start Key:
Gui, Settings:Add, Hotkey, x120 y50 vStartKey, F1
Gui, Settings:Add, Text, x20 y90, Stop Key:
Gui, Settings:Add, Hotkey, x120 y90 vStopKey, F2
Gui, Settings:Add, Text, x20 y130, Webhook URL:
Gui, Settings:Add, Edit, x120 y130 w250 vWebhookURL
Gui, Settings:Tab, Coordinates
Gui, Settings:Add, Text, x20 y50, Day Top Left:
Gui, Settings:Add, Edit, x150 y50 w100 vDayTopLeft, 1416, 931
Gui, Settings:Add, Button, x260 y50 w100 h20 gPickDayTopLeft, Pick
; ... (add more coordinate settings here)
Gui, Settings:Tab, Scrolls
Gui, Settings:Add, CheckBox, x20 y50 vHoppa, Hoppa
Gui, Settings:Add, CheckBox, x120 y50 vSnarvindur, Snarvindur
Gui, Settings:Add, CheckBox, x220 y50 vPercutiens, Percutiens
Gui, Settings:Add, Button, x20 y250 w100 h30 gSaveSettings, Save
return

Start:
    SetTimer, MainLoop, 1000
    return

Stop:
    SetTimer, MainLoop, Off
    return

Settings:
    Gui, Settings:Show, h140 w300, Settings
    return

SaveSettings:
    Gui, Settings:Submit, NoHide
    enabled_scrolls := ""
    if (Hoppa)
        enabled_scrolls .= "hoppa,"
    if (Snarvindur)
        enabled_scrolls .= "snarvindur,"
    if (Percutiens)
        enabled_scrolls .= "percutiens,"

    IniWrite, %StartKey%, config.ini, Settings, start_key
    IniWrite, %StopKey%, config.ini, Settings, stop_key
    IniWrite, %WebhookURL%, config.ini, Settings, webhook_url
    IniWrite, %enabled_scrolls%, config.ini, Settings, enabled_scrolls
    return

PointPicker:
    CoordMode, Mouse, Screen
    MouseGetPos, xpos, ypos
    MsgBox, The current mouse position is X%xpos% Y%ypos%
    return

FocusRoblox()
{
    IfWinExist, Roblox
    {
        WinActivate, Roblox
    }
}

MainLoop:
    FocusRoblox()
    ; Every 1 minute and 30 seconds
    if (A_TickCount - last_menu_click > 90000)
    {
        ; Click Menu Button (ImageSearch)
        ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 images/menu.png
        if (ErrorLevel = 0)
        {
            Click, %FoundX%, %FoundY%
        }
        last_menu_click := A_TickCount

        ; Wait 10 seconds
        Sleep, 10000

        ; Click Play Button (ImageSearch)
        ImageSearch, FoundX, FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 images/play.png
        if (ErrorLevel = 0)
        {
            Click, %FoundX%, %FoundY%
        }
    }

    ; Check day
    current_day := GetDay()
    if (current_day != last_day)
    {
        if (last_day != "")
        {
            ; Perform gacha action
            PerformGachaAction()
            SendWebhook("Day changed to " . current_day . ". Performing gacha action.")
        }
        last_day := current_day
    }

    ; Check lives
    current_lives := GetLives()
    if (current_lives != last_lives)
    {
        if (last_lives != "" and current_lives < last_lives)
        {
            SendWebhook("Lives changed to " . current_lives . ". Stopping script.")
            ExitApp
        }
        last_lives := current_lives
    }
    return

GetDay()
{
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", "http://127.0.0.1:5000/get_day", true)
    whr.Send()
    whr.WaitForResponse()
    response := whr.ResponseText
    json_response := JSON.Load(response)
    return json_response.day
}

GetLives()
{
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", "http://127.0.0.1:5000/get_lives", true)
    whr.Send()
    whr.WaitForResponse()
    response := whr.ResponseText
    json_response := JSON.Load(response)
    return json_response.lives
}

PerformGachaAction()
{
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST", "http://127.0.0.1:5000/gacha_action", true)
    whr.Send()
    whr.WaitForResponse()
}

SendWebhook(message)
{
    IniRead, webhook_url, config.ini, Settings, webhook_url
    if (webhook_url)
    {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", webhook_url, true)
        whr.SetRequestHeader("Content-Type", "application/json")
        payload := JSON.Dump({content: message})
        whr.Send(payload)
        whr.WaitForResponse()
    }
}

GuiClose:
ExitApp
