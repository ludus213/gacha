#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#Include JSON.ahk

; GUI
Gui, Add, Button, x12 y10 w80 h30 gStart, Start
Gui, Add, Button, x102 y10 w80 h30 gStop, Stop
Gui, Add, Picture, x192 y10 w30 h30 gSettings, settings_icon.png
Gui, Show, h50 w230, Auto Clicker

; Settings GUI
Gui, Settings:Add, Text, x10 y10, Start Key:
Gui, Settings:Add, Hotkey, x80 y10 vStartKey, F1
Gui, Settings:Add, Text, x10 y40, Stop Key:
Gui, Settings:Add, Hotkey, x80 y40 vStopKey, F2
Gui, Settings:Add, Text, x10 y70, Webhook URL:
Gui, Settings:Add, Edit, x80 y70 w200 vWebhookURL
Gui, Settings:Add, Text, x10 y100, Enabled Scrolls:
Gui, Settings:Add, CheckBox, x10 y120 vHoppa, Hoppa
Gui, Settings:Add, CheckBox, x80 y120 vSnarvindur, Snarvindur
Gui, Settings:Add, CheckBox, x170 y120 vPercutiens, Percutiens
Gui, Settings:Add, Button, x10 y150 w100 h30 gSaveSettings, Save
Gui, Settings:Add, Button, x120 y150 w100 h30 gPointPicker, Point Picker
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

MainLoop:
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
