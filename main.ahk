#SingleInstance, Force
SetBatchLines, -1
SendMode Input
SetWorkingDir, %A_ScriptDir%
#Include JSON.ahk
#Include gdip.ahk

If !FileExist("config.ini")
{
    MsgBox, config.ini not found.
    ExitApp
}

If !IsFunc("Gdip_Startup")
{
    MsgBox, Gdip.ahk is not included or is corrupted.
    ExitApp
}

RunWait, pip install -r requirements.txt, , Hide

Run, python main.py
Sleep, 5000

Loop
{
    try
    {
        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("GET", "http://127.0.0.1:5000/", true)
        whr.Send()
        if whr.WaitForResponse(2) && whr.Status == 200
            break
    }
    catch e
    {
    }
    Sleep, 1000
}

Gui, Font, s12, Segoe UI
Gui, Add, Button, x12 y10 w120 h50 gStart, Start
Gui, Add, Button, x142 y10 w120 h50 gStop, Stop
Gui, Add, Button, x272 y10 w50 h50 gSettings, ⚙️
Gui, Show, h70 w335, Auto Clicker

Gui, Settings:Font, s10, Segoe UI
Gui, Settings:Add, Tab2, x10 y10 w480 h380, General|Coordinates|Scrolls|Webhook
Gui, Settings:Tab, General
Gui, Settings:Add, Text, x20 y50, Start Key:
Gui, Settings:Add, Hotkey, x120 y50 vStartKey, F1
Gui, Settings:Add, Text, x20 y90, Stop Key:
Gui, Settings:Add, Hotkey, x120 y90 vStopKey, F2
Gui, Settings:Add, Text, x20 y130, Webhook URL:
Gui, Settings:Add, Edit, x120 y130 w250 vWebhookURL
Gui, Settings:Tab, Coordinates
Gui, Settings:Add, Text, x20 y50, Day Top Left:
Gui, Settings:Add, Edit, x150 y50 w100 vDayTopLeft
Gui, Settings:Add, Button, x260 y50 w100 h20 gPickDayTopLeft, Choose Location
Gui, Settings:Add, Text, x20 y80, Day Bottom Right:
Gui, Settings:Add, Edit, x150 y80 w100 vDayBottomRight
Gui, Settings:Add, Button, x260 y80 w100 h20 gPickDayBottomRight, Choose Location
Gui, Settings:Add, Text, x20 y110, Lives Top Left:
Gui, Settings:Add, Edit, x150 y110 w100 vLivesTopLeft
Gui, Settings:Add, Button, x260 y110 w100 h20 gPickLivesTopLeft, Choose Location
Gui, Settings:Add, Text, x20 y140, Lives Bottom Right:
Gui, Settings:Add, Edit, x150 y140 w100 vLivesBottomRight
Gui, Settings:Add, Button, x260 y140 w100 h20 gPickLivesBottomRight, Choose Location
Gui, Settings:Add, Text, x20 y170, Option 1 Top Left:
Gui, Settings:Add, Edit, x150 y170 w100 vOption1TopLeft
Gui, Settings:Add, Button, x260 y170 w100 h20 gPickOption1TopLeft, Choose Location
Gui, Settings:Add, Text, x20 y200, Option 1 Bottom Right:
Gui, Settings:Add, Edit, x150 y200 w100 vOption1BottomRight
Gui, Settings:Add, Button, x260 y200 w100 h20 gPickOption1BottomRight, Choose Location
Gui, Settings:Add, Text, x20 y230, Option 1 Click:
Gui, Settings:Add, Edit, x150 y230 w100 vOption1Click
Gui, Settings:Add, Button, x260 y230 w100 h20 gPickOption1Click, Choose Location
Gui, Settings:Tab, Scrolls
Gui, Settings:Add, CheckBox, x20 y50 vScrollHoppa, Hoppa
Gui, Settings:Add, CheckBox, x120 y50 vScrollSnarvindur, Snarvindur
Gui, Settings:Add, CheckBox, x220 y50 vScrollPercutiens, Percutiens
Gui, Settings:Tab, Webhook
Gui, Settings:Add, CheckBox, x20 y50 vWebhookOnStart, On Start
Gui, Settings:Add, CheckBox, x120 y50 vWebhookOnStop, On Stop
Gui, Settings:Add, CheckBox, x220 y50 vWebhookOnCaptcha, On Captcha
Gui, Settings:Add, CheckBox, x20 y80 vWebhookOnMenu, On Menu
Gui, Settings:Add, CheckBox, x120 y80 vWebhookOnPlay, On Play
Gui, Settings:Add, CheckBox, x220 y80 vWebhookOnSilver, On Silver
Gui, Settings:Add, Button, x20 y250 w100 h30 gSaveSettings, Save
return

Start:
    Log("Script started.")
    SetTimer, MainLoop, 1000
    IniRead, play_button, config.ini, Coordinates, play_button
    Click, %play_button%
    SendWebhookWithScreenshot("Clicked play button.", "play")
    SendWebhookWithScreenshot("Script started.", "start")
    return

Stop:
    Log("Script stopped.")
    SendWebhookWithScreenshot("Script stopped.", "stop")
    SetTimer, MainLoop, Off
    return

Settings:
    IniRead, current_start_key, config.ini, Settings, start_key, F1
    IniRead, current_stop_key, config.ini, Settings, stop_key, F2
    IniRead, current_webhook_url, config.ini, Settings, webhook_url,
    IniRead, current_enabled_scrolls, config.ini, Settings, enabled_scrolls,
    GuiControl, Settings:, StartKey, %current_start_key%
    GuiControl, Settings:, StopKey, %current_stop_key%
    GuiControl, Settings:, WebhookURL, %current_webhook_url%
    GuiControl, Settings:, ScrollHoppa, % InStr(current_enabled_scrolls, "hoppa") ? 1 : 0
    GuiControl, Settings:, ScrollSnarvindur, % InStr(current_enabled_scrolls, "snarvindur") ? 1 : 0
    GuiControl, Settings:, ScrollPercutiens, % InStr(current_enabled_scrolls, "percutiens") ? 1 : 0
    Gui, Settings:Show, h300 w400, Settings
    return

SaveSettings:
    Log("Saving settings.")
    Gui, Settings:Submit, NoHide
    enabled_scrolls := ""
    if (ScrollHoppa)
        enabled_scrolls .= "hoppa,"
    if (ScrollSnarvindur)
        enabled_scrolls .= "snarvindur,"
    if (ScrollPercutiens)
        enabled_scrolls .= "percutiens,"
    IniWrite, %StartKey%, config.ini, Settings, start_key
    IniWrite, %StopKey%, config.ini, Settings, stop_key
    IniWrite, %WebhookURL%, config.ini, Settings, webhook_url
    IniWrite, %enabled_scrolls%, config.ini, Settings, enabled_scrolls
    webhook_settings := ""
    if (WebhookOnStart)
        webhook_settings .= "start,"
    if (WebhookOnStop)
        webhook_settings .= "stop,"
    if (WebhookOnCaptcha)
        webhook_settings .= "captcha,"
    if (WebhookOnMenu)
        webhook_settings .= "menu,"
    if (WebhookOnPlay)
        webhook_settings .= "play,"
    if (WebhookOnSilver)
        webhook_settings .= "silver,"
    IniWrite, %webhook_settings%, config.ini, Settings, webhook_settings
    Hotkey, %StartKey%, Start
    Hotkey, %StopKey%, Stop
    if (WebhookURL)
        SendWebhookWithScreenshot("Webhook test successful!", "start")
    MsgBox, 0, Settings, Settings saved successfully!
    return

PickLocation(control)
{
    Gui, Settings: +OwnDialogs
    MsgBox, 4, Pick Location, Click on the desired location.
    IfMsgBox, Cancel
        return
    KeyWait, LButton, D
    MouseGetPos, x, y
    GuiControl, Settings:, %control%, %x%, %y%
    return
}

PickDayTopLeft:
    PickLocation("DayTopLeft")
    return

PickDayBottomRight:
    PickLocation("DayBottomRight")
    return

PickLivesTopLeft:
    PickLocation("LivesTopLeft")
    return

PickLivesBottomRight:
    PickLocation("LivesBottomRight")
    return

PickOption1TopLeft:
    PickLocation("Option1TopLeft")
    return

PickOption1BottomRight:
    PickLocation("Option1BottomRight")
    return

PickOption1Click:
    PickLocation("Option1Click")
    return

FocusRoblox()
{
    IfWinExist, Roblox
    {
        WinActivate, Roblox
    }
}

in_menu_transition := false

OnExit("ExitFunc")

ExitFunc(ExitReason, ExitCode)
{
    Log("Script exited. Reason: " . ExitReason . " Code: " . ExitCode)
}

Log(message)
{
    FileAppend, %A_Now% - %message%`n, log.txt
}

MainLoop:
    try
    {
        FocusRoblox()
        if (A_TickCount - last_menu_click > 90000)
        {
            in_menu_transition := true
            IniRead, menu_button, config.ini, Coordinates, menu_button
            Click, %menu_button%
            SendWebhookWithScreenshot("Clicked menu button.", "menu")
            last_menu_click := A_TickCount
            Sleep, 10000
            IniRead, play_button, config.ini, Coordinates, play_button
            Click, %play_button%
            SendWebhookWithScreenshot("Clicked play button.", "play")
            in_menu_transition := false
        }

        if (in_menu_transition)
            return

        current_day := GetDay()
        if (current_day != last_day)
        {
            if (last_day != "")
            {
                PerformGachaAction()
                SendWebhookWithScreenshot("Day changed to " . current_day . ". Performing gacha action.", "captcha")
            }
            last_day := current_day
        }

        current_lives := GetLives()
        if (current_lives != last_lives)
        {
            if (last_lives != "" and current_lives < last_lives)
            {
                SendWebhookWithScreenshot("Lives changed to " . current_lives . ". Stopping script.", "stop")
                ExitApp
            }
            last_lives := current_lives
        }

        current_silver := GetSilver()
        if (current_silver < 250)
        {
            SendWebhookWithScreenshot("Silver is less than 250. Stopping script.", "silver")
            ExitApp
        }
    }
    catch e
    {
        Log("Error in MainLoop: " . e.Message)
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

GetSilver()
{
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("GET", "http://127.0.0.1:5000/get_silver", true)
    whr.Send()
    whr.WaitForResponse()
    response := whr.ResponseText
    json_response := JSON.Load(response)
    return json_response.silver
}

PerformGachaAction()
{
    whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    whr.Open("POST", "http://127.0.0.1:5000/gacha_action", true)
    whr.Send()
    whr.WaitForResponse()
}

SendWebhookWithScreenshot(message, event_type)
{
    IniRead, webhook_settings, config.ini, Settings, webhook_settings
    if !InStr(webhook_settings, event_type)
        return

    IniRead, webhook_url, config.ini, Settings, webhook_url
    if (webhook_url)
    {
        pToken := Gdip_Startup()
        hBM := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", DllCall("gdi32\CreateDC", "Str", "DISPLAY", "Ptr", 0, "Ptr", 0, "Ptr", 0), "Int", A_ScreenWidth, "Int", A_ScreenHeight)
        hDC := DllCall("gdi32\CreateCompatibleDC", "Ptr", 0)
        DllCall("gdi32\SelectObject", "Ptr", hDC, "Ptr", hBM)
        DllCall("gdi32\BitBlt", "Ptr", hDC, "Int", 0, "Int", 0, "Int", A_ScreenWidth, "Int", A_ScreenHeight, "Ptr", DllCall("gdi32\CreateDC", "Str", "DISPLAY", "Ptr", 0, "Ptr", 0, "Ptr", 0), "Int", 0, "Int", 0, "UInt", 0xCC0020)
        pBitmap := Gdip_CreateBitmapFromHBITMAP(hBM)
        Gdip_SaveBitmapToFile(pBitmap, "screenshot.png", "image/png")
        Gdip_DisposeImage(pBitmap)
        Gdip_Shutdown(pToken)

        whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
        whr.Open("POST", webhook_url, true)

        boundary := "----WebKitFormBoundary" . A_TickCount
        whr.SetRequestHeader("Content-Type", "multipart/form-data; boundary=" . boundary)

        payload := "--" . boundary . "`r`n"
        payload .= "Content-Disposition: form-data; name=""payload_json""`r`n`r`n"
        payload .= JSON.Dump({content: message}) . "`r`n"
        payload .= "--" . boundary . "`r`n"
        payload .= "Content-Disposition: form-data; name=""file""; filename=""screenshot.png""`r`n"
        payload .= "Content-Type: image/png`r`n`r`n"

        FileRead, file_content, *c screenshot.png

        len1 := StrLen(payload)
        len2 := VarSetCapacity(file_content)
        VarSetCapacity(requestBody, len1 + len2)
        DllCall("msvcrt\memcpy", "Ptr", &requestBody, "Ptr", &payload, "UInt", len1)
        DllCall("msvcrt\memcpy", "Ptr", &requestBody + len1, "Ptr", &file_content, "UInt", len2)

        whr.Send(requestBody)
        whr.WaitForResponse()

        FileDelete, screenshot.png
    }
}

GuiClose:
SendWebhookWithScreenshot("Script exited.", "stop")
ExitApp
