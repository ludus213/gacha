/*
    JSON.ahk by Coco  (https://github.com/cocobelgica/AutoHotkey-JSON)
    Adds support for JSON (JavaScript Object Notation) to AutoHotkey.

    Dependencies:
        - AutoHotkey v1.1.15.00 or higher

    Terms of Use:
        - This library is free for personal and commercial use.
        - No charge may be made for this library in its original or modified form.
        - Credit must be given to the original author with a link to the original
          thread/website.

    v2.0.01 2015-08-20
        - Fixed: Malformed JSON string when it contains certain characters such as
          a lone double-quote character
    v2.0.0 2015-02-12
        - Load() now returns an object instead of populating a variable
        - Better handling of arrays/objects
        - Dump() now has a pretty-print option
        - Changed: Jxon_Load() -> JSON.Load(), Jxon_Dump() -> JSON.Dump()
    v1.1.0 2012-04-14
        - Added Jxon_Dump()
        - Jxon_Load() now handles leading/trailing whitespace
    v1.0.0 2011-12-25
        - Initial version
*/
JSON(Method, P*) {
    Static Dummy
    If !IsObject(Dummy) {
        Dummy := Object()
        F := {Load: "JSON_Load", Dump: "JSON_Dump"}
        For k, v in F
            Dummy.DefineMethod(k, v)
    }
    Return Dummy.Call(Method, P*)
}
JSON_Load(this, ByRef json, ByRef reviver:="")
{
    static type := {1:"number", 2:"string", 3:"array", 4:"object"}
    static quot := Chr(34)

    json := Trim(json)
    If (SubStr(json, 1, 1) != "{" && SubStr(json, 1, 1) != "[")
        json := "[" . json . "]"
    pos := 1
    If (RegExMatch(json, "s)[`r`n`t ]*\{", m))
        is_object := 1, out := {}
    Else
        is_object := 0, out := []
    Loop
    {
        If (!is_object)
        {
            If !(p := InStr(json, ",", 0, pos))
                p := InStr(json, "]", 0, pos)
            If (!p)
                Return
            v := SubStr(json, pos, p - pos)
        }
        Else
        {
            If !(p_k := InStr(json, ":", 0, pos))
                Return
            k := SubStr(json, pos, p_k - pos)
            If (SubStr(k, 1, 1) = "{")
                k := SubStr(k, 2)
            If (SubStr(k, 1, 1) = ",")
                k := SubStr(k, 2)
            k := Trim(k, " `t`r`n")
            If (SubStr(k, 1, 1) = quot)
                k := JSON_Unescape(SubStr(k, 2, -1))
            If !(p_v := InStr(json, ",", 0, p_k))
                p_v := InStr(json, "}", 0, p_k)
            v := SubStr(json, p_k + 1, p_v - p_k - 1)
        }
        v := Trim(v, " `t`r`n[]{}")
        If v is number
            val := v + 0
        Else If (v = "true" || v = "false")
            val := %v%
        Else If (v = "null")
            val := ""
        Else If (SubStr(v, 1, 1) = quot)
            val := JSON_Unescape(SubStr(v, 2, -1))
        Else If (SubStr(v, 1, 1) = "{")
            val := this.Load(v, reviver)
        Else If (SubStr(v, 1, 1) = "[")
            val := this.Load(v, reviver)
        Else
            val := v
        If (IsObject(reviver))
            val := reviver.Call(k, val)
        If (is_object)
            out[k] := val
        Else
            out.Push(val)
        If (pos >= StrLen(json) - 1)
            Break
        pos := p_v + 1
    }
    Return out
}
JSON_Dump(this, object, space:="", replacer:="")
{
    static quot := Chr(34)
    If (!IsObject(object))
        Return
    is_array := object.HasKey(1)
    out := ""
    If (is_array)
    {
        out := "["
        Loop % object.Length()
        {
            v := object[A_Index]
            If (IsObject(replacer))
                v := replacer.Call(A_Index, v)
            If (IsObject(v))
                out .= this.Dump(v, space, replacer)
            Else If v is number
                out .= v
            Else If (v = true || v = false)
                out .= v ? "true" : "false"
            Else If (v = "")
                out .= "null"
            Else
                out .= quot . JSON_Escape(v) . quot
            If (A_Index < object.Length())
                out .= ","
            If (space)
                out .= "`n" . space
        }
        out .= "]"
    }
    Else
    {
        out := "{"
        s := ""
        For k, v in object
        {
            If (IsObject(replacer))
                v := replacer.Call(k, v)
            If (IsObject(v))
                v_out := this.Dump(v, space, replacer)
            Else If v is number
                v_out := v
            Else If (v = true || v = false)
                v_out := v ? "true" : "false"
            Else If (v = "")
                v_out := "null"
            Else
                v_out := quot . JSON_Escape(v) . quot
            out .= s . (space ? "`n" . space : "") . quot . JSON_Escape(k) . quot . ":" . (space ? " " : "") . v_out
            s := ","
        }
        If (space)
            out .= "`n"
        out .= "}"
    }
    Return out
}
JSON_Escape(str) {
    static c, r
    If (!IsObject(r))
        c := ["\", "/", "`b", "`f", "`n", "`r", "`t", quot]
        , r := {"\":"\\", "/":"\/", "`b":"\b", "`f":"\f", "`n":"\n", "`r":"\r", "`t":"\t", quot:"\" . quot}
    Loop % c.Length()
        str := StrReplace(str, c[A_Index], r[c[A_Index]])
    Return str
}
JSON_Unescape(str) {
    static c, r
    If (!IsObject(r))
        c := ["\\", "\/", "\b", "\f", "\n", "\r", "\t", "\" . quot]
        , r := {"\\":"\", "\/":"/", "\b":"`b", "\f":"`f", "\n":"`n", "\r":"`r", "\t":"`t", "\" . quot:quot}
    Loop % c.Length()
        str := StrReplace(str, c[A_Index], r[c[A_Index]])
    Return str
}
