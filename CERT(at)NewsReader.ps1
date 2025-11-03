######################################
# DaUfooo´s CERT.at ATOM News-Reader #
######################################

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072  # Erzwingen von TLS 1.2/1.3
Add-Type -AssemblyName System.speech
$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer

# Umwandlung der fehlerhaften Zeichen
function Convert-BrokenChars {
    param ($text)
    $text = $text -replace "Ã¼", "ue"
    $text = $text -replace "Ã¶", "oe"
    $text = $text -replace "Ã¤", "ae"
    $text = $text -replace "ÃŸ", "ss"
    return $text
}

# Berechnung der Helligkeit einer Farbe
function Get-Brightness {
    param ($color)
    $rgb = [System.Drawing.Color]::FromName($color)
    $brightness = (0.2126 * $rgb.R + 0.7152 * $rgb.G + 0.0722 * $rgb.B) / 255
    return $brightness
}

# Überprüfung des Kontrasts
function Is-HighContrast {
    param ($fgcolor, $bgcolor)
    
    $fgBrightness = Get-Brightness -color $fgcolor
    $bgBrightness = Get-Brightness -color $bgcolor
    
    # Wenn der Unterschied in der Helligkeit weniger als 0.5 ist, ist der Kontrast zu gering
    if ([math]::Abs($fgBrightness - $bgBrightness) -lt 0.5) {
        return $false
    }
    return $true
}

# URL des Atom-Feeds
$feedUrl = "https://www.cert.at/cert-at.de.warnings.atom_1.0.xml"

# Abrufen der Atom-Feeds
try {
    $feedContent = Invoke-WebRequest -Uri $feedUrl -UseBasicParsing
    $feedXml = [xml]$feedContent.Content
} catch {
    Write-Host "Fehler beim Abrufen des Atom-Feeds. Details: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# DaUfooo TAG!
Write-Host "######################################" -ForegroundColor Cyan
Write-Host "# DaUfooo´s CERT.at ATOM News-Reader #" -ForegroundColor Cyan
Write-Host "######################################" -ForegroundColor Cyan

# Abfrage der Stimmen
Write-Host "Verfügbare installierte Stimmen:" -ForegroundColor Green
$voices = $speak.GetInstalledVoices()
$voiceList = $voices | ForEach-Object { $_.VoiceInfo.Name }

# Liste der Stimmen mit Nummerierung
$voiceList | ForEach-Object { Write-Host "$($_) - $([Array]::IndexOf($voiceList, $_) + 1)" -ForegroundColor Yellow }

# Auswahl der Stimme durch Eingabe einer Zahl
Write-Host "Bitte wähle eine Stimme aus (z.B. 1, 2, 3, ...)" -ForegroundColor Magenta
$selection = Read-Host

# Überprüfen, ob die Auswahl gültig ist
if ($selection -match '^\d+$' -and $selection -gt 0 -and $selection -le $voiceList.Count) {
    $selectedVoice = $voiceList[$selection - 1]
    $speak.SelectVoice($selectedVoice)
    Write-Host "Ausgewählte Stimme: $selectedVoice" -ForegroundColor Green
} else {
    Write-Host "Ungültige Auswahl. Standardstimme wird verwendet." -ForegroundColor Red
    $speak.SelectVoice($voiceList[0])
}

# Ausgabe des Titels des Feeds
Write-Host "$($feedXml.feed.title)" -ForegroundColor Cyan

# Vorlesen: CERT.at - Warnungen
$speak.Speak("CERT.at - Warnungen")

# Hole alle verfügbaren Farben
$colors = [enum]::GetValues([System.ConsoleColor])

# Schleife über alle <entry>-Elemente und nur die Titel vorlesen
foreach ($entry in $feedXml.feed.entry) {
    $title = $entry.title
    $title = Convert-BrokenChars $title  # Fehlerhafte Zeichen ersetzen
    
    $fgcolor = $colors[(Get-Random -Minimum 0 -Maximum $colors.Length)]
    $bgcolor = $colors[(Get-Random -Minimum 0 -Maximum $colors.Length)]

    # Überprüfe, ob der Kontrast zwischen Vorder- und Hintergrundfarbe hoch genug ist
    while (-not (Is-HighContrast -fgcolor $fgcolor -bgcolor $bgcolor)) {
        # Falls der Kontrast zu gering ist, wähle neue Farben
        $fgcolor = $colors[(Get-Random -Minimum 0 -Maximum $colors.Length)]
        $bgcolor = $colors[(Get-Random -Minimum 0 -Maximum $colors.Length)]
    }

    # Ausgabe des Titels in der gewählten Farbkombination
    Write-Host "Titel: $title" -ForegroundColor $fgcolor -BackgroundColor $bgcolor
    
    # Vorlesen des Titels
    $speak.Speak("Neue Warnung: $title")
    
    Start-Sleep -Seconds 2
}
