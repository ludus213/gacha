/*
    GDI+ binding for AutoHotkey
    by Tic
    http://www.autohotkey.com/forum/topic34958.html
*/

; GDI+ Flat API functions
; http://msdn.microsoft.com/en-us/library/ms533969(v=vs.85).aspx

; GDI+ enums
; http://msdn.microsoft.com/en-us/library/ms534175(v=vs.85).aspx

Gdip_Startup()
{
    static hModule
    If !hModule
        hModule := DllCall("LoadLibrary", "Str", "gdiplus.dll")
    VarSetCapacity(si, 16, 0)
    NumPut(1, si, 0, "UChar")
    DllCall("gdiplus\GdiplusStartup", "Ptr*", pToken, "Ptr", &si, "Ptr", 0)
    Return pToken
}

Gdip_Shutdown(pToken)
{
    DllCall("gdiplus\GdiplusShutdown", "Ptr", pToken)
    If hModule
        DllCall("FreeLibrary", "Ptr", hModule), hModule := ""
}

Gdip_CreateBitmapFromFile(sFile)
{
    DllCall("gdiplus\GdipCreateBitmapFromFile", "WStr", sFile, "Ptr*", pBitmap)
    Return pBitmap
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, hPalette=0)
{
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "Ptr", hBitmap, "Ptr", hPalette, "Ptr*", pBitmap)
    Return pBitmap
}

Gdip_CreateHBITMAPFromBitmap(pBitmap, hbmReturn, background=0xffffff)
{
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", hbmReturn, "UInt", background)
    Return hbmReturn
}

Gdip_DisposeImage(pImage)
{
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pImage)
}

Gdip_SaveBitmapToFile(pBitmap, sFile, sMimeType="image/png", quality=75)
{
    static e
    If !e
        DllCall("gdiplus\GdipGetImageEncodersSize", "UInt*", nCount, "UInt*", nSize), VarSetCapacity(ci, nSize), DllCall("gdiplus\GdipGetImageEncoders", "UInt", nCount, "UInt", nSize, "Ptr", &ci)
    Loop % nCount
    {
        If (Chr(*(NumGet(ci, (A_Index-1)*104+4, "UInt"))) = sMimeType)
        {
            pCodec := &ci + (A_Index-1)*104
            Break
        }
    }
    If sMimeType = image/jpeg
    {
        VarSetCapacity(pi, 20, 0)
        NumPut(0x1D234190, pi, 0, "UInt")
        NumPut(0x95949282, pi, 4, "UInt")
        NumPut(1, pi, 8, "UInt")
        NumPut(6, pi, 12, "UInt")
        NumPut(1, pi, 16, "UInt")
        pParam := &quality
        NumPut(pParam, pi, 16, "UInt")
        DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", sFile, "Ptr", pCodec, "Ptr", &pi)
    }
    Else
        DllCall("gdiplus\GdipSaveImageToFile", "Ptr", pBitmap, "WStr", sFile, "Ptr", pCodec, "Ptr", 0)
}

Gdip_GetImageWidth(pImage)
{
    DllCall("gdiplus\GdipGetImageWidth", "Ptr", pImage, "UInt*", nWidth)
    Return nWidth
}

Gdip_GetImageHeight(pImage)
{
    DllCall("gdiplus\GdipGetImageHeight", "Ptr", pImage, "UInt*", nHeight)
    Return nHeight
}
