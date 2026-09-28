# ==============================================================================
#  Raksha Emergency Mesh - IoT Hardware to Phone USB Cable Bridge
# ==============================================================================
#  Bridges ESP32 (connected via USB Serial) <-> Phone App (connected via USB ADB)
# ==============================================================================

param(
    [string]$PortName = "",
    [int]$BaudRate = 115200,
    [int]$TcpPort = 8888
)

Clear-Host
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "   🛡️ RAKSHA EMERGENCY MESH - IoT USB TO PHONE BRIDGE         " -ForegroundColor Yellow
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "  ESP32 (USB Cable) <--> Laptop <--> Phone (USB ADB Cable)   " -ForegroundColor Gray
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Locate ADB executable
$adb = "adb"
$adbFound = $false

$candidatePaths = @(
    "adb",
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe",
    "C:\Users\Harshit\AppData\Local\Android\Sdk\platform-tools\adb.exe",
    "C:\Users\Harshit\AppData\Local\Android\sdk\platform-tools\adb.exe"
)

foreach ($p in $candidatePaths) {
    if ($p -eq "adb") {
        if (Get-Command "adb" -ErrorAction SilentlyContinue) {
            $adb = "adb"
            $adbFound = $true
            break
        }
    } else {
        if (Test-Path $p) {
            $adb = $p
            $adbFound = $true
            break
        }
    }
}

# 2. Establish ADB Forward and Reverse Port Rules
Write-Host "[1/3] Setting up USB Cable Tunnel via ADB on port $TcpPort..." -ForegroundColor Cyan
if ($adbFound) {
    try {
        # Check connected ADB devices
        $devices = & $adb devices | Where-Object { $_ -match '\tdevice$' }
        if ($devices.Count -gt 0) {
            Write-Host "      📱 Detected Android Device: $($devices[0].Split("`t")[0])" -ForegroundColor Green
        } else {
            Write-Host "      ⚠️ No Android device in 'device' state. Ensure USB debugging is ON." -ForegroundColor Yellow
        }

        # Setup both forward and reverse for 100% reliable connectivity
        & $adb forward "tcp:$TcpPort" "tcp:$TcpPort" 2>$null
        & $adb reverse "tcp:$TcpPort" "tcp:$TcpPort" 2>$null
        Write-Host "      ✅ ADB Port Forward & Reverse Active (tcp:$TcpPort <-> tcp:$TcpPort)" -ForegroundColor Green
    } catch {
        Write-Host "      ⚠️ Notice: $($_)" -ForegroundColor Yellow
    }
} else {
    Write-Host "      ⚠️ adb.exe not found automatically. Ensure phone has Raksha app open." -ForegroundColor Yellow
}

# 3. Detect and Select ESP32 Serial COM Port
Write-Host ""
Write-Host "[2/3] Detecting Serial COM Ports for ESP32..." -ForegroundColor Cyan

$rawPorts = [System.IO.Ports.SerialPort]::GetPortNames()
if ($rawPorts.Count -eq 0) {
    Write-Host "❌ No Serial COM ports found! Ensure your ESP32 is plugged in via USB." -ForegroundColor Red
    exit 1
}

# Try to get friendly names from Windows PnP
$pnpPorts = @()
try {
    $pnpPorts = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\(COM\d+\)' }
} catch {}

$portList = @()
foreach ($p in $rawPorts) {
    $matched = $pnpPorts | Where-Object { $_.Name -match "\($p\)" }
    if ($matched) {
        $portList += [PSCustomObject]@{ Port = $p; Description = $matched.Name }
    } else {
        $portList += [PSCustomObject]@{ Port = $p; Description = "$p (Serial Device)" }
    }
}

if (-not $PortName) {
    Write-Host "Available COM Ports:" -ForegroundColor Yellow
    $recommendedIndex = 0
    for ($i = 0; $i -lt $portList.Count; $i++) {
        $desc = $portList[$i].Description
        $isEsp = ($desc -match "CP210" -or $desc -match "CH340" -or $desc -match "USB to UART" -or $desc -match "Silicon Labs")
        if ($isEsp) { $recommendedIndex = $i }
        $mark = if ($isEsp) { " ⭐ [RECOMMENDED ESP32]" } else { "" }
        Write-Host "  [$i] $($portList[$i].Description)$mark" -ForegroundColor White
    }

    if ($portList.Count -eq 1) {
        $PortName = $portList[0].Port
        Write-Host "Auto-selected only available port: $PortName" -ForegroundColor Green
    } else {
        $choice = Read-Host "Select COM port number (default $recommendedIndex: $($portList[$recommendedIndex].Port))"
        if ($choice -match '^\d+$' -and [int]$choice -lt $portList.Count) {
            $PortName = $portList[[int]$choice].Port
        } else {
            $PortName = $portList[$recommendedIndex].Port
        }
    }
}

# 4. Open Serial Port to ESP32
Write-Host ""
Write-Host "Opening Serial Port $PortName at $BaudRate baud..." -ForegroundColor Cyan
try {
    $serial = New-Object System.IO.Ports.SerialPort $PortName, $BaudRate, [System.IO.Ports.Parity]::None, 8, [System.IO.Ports.StopBits]::One
    $serial.ReadTimeout = 200
    $serial.WriteTimeout = 500
    $serial.DtrEnable = $true
    $serial.RtsEnable = $true
    $serial.Open()
    Write-Host "      ✅ Serial Port $PortName connected to ESP32!" -ForegroundColor Green
} catch {
    Write-Host "      ❌ Error opening $PortName: $_" -ForegroundColor Red
    Write-Host "      (If Arduino IDE Serial Monitor or another app is using $PortName, please CLOSE it first!)" -ForegroundColor Yellow
    exit 1
}

# 5. Connect to Phone App via TCP
Write-Host ""
Write-Host "[3/3] Establishing connection to Phone App..." -ForegroundColor Cyan

$tcp = $null
$stream = $null
$reader = $null
$writer = $null

# First try connecting as Client to Phone (adb forward: 127.0.0.1:$TcpPort -> Phone:8888)
$maxAttempts = 6
for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
    try {
        $tcp = New-Object System.Net.Sockets.TcpClient
        $tcp.ReceiveTimeout = 500
        $tcp.SendTimeout = 500
        $tcp.Connect("127.0.0.1", $TcpPort)
        $stream = $tcp.GetStream()
        $reader = New-Object System.IO.StreamReader $stream
        $writer = New-Object System.IO.StreamWriter $stream
        $writer.AutoFlush = $true
        Write-Host "      ✅ Connected to Raksha Mobile App over USB Cable!" -ForegroundColor Green
        break
    } catch {
        Write-Host "      Waiting for Raksha app to accept connection (attempt $attempt/$maxAttempts)..." -ForegroundColor Gray
        Start-Sleep -Seconds 2
    }
}

if (-not $tcp -or -not $tcp.Connected) {
    Write-Host ""
    Write-Host "⚠️ Direct TCP connection waiting. Starting fallback listener on port $TcpPort..." -ForegroundColor Yellow
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $TcpPort)
        $listener.Start()
        Write-Host "   Waiting up to 10s for phone to connect via ADB reverse..." -ForegroundColor Gray
        $asyncResult = $listener.BeginAcceptTcpClient($null, $null)
        if ($asyncResult.AsyncWaitHandle.WaitOne(10000)) {
            $tcp = $listener.EndAcceptTcpClient($asyncResult)
            $stream = $tcp.GetStream()
            $reader = New-Object System.IO.StreamReader $stream
            $writer = New-Object System.IO.StreamWriter $stream
            $writer.AutoFlush = $true
            Write-Host "   ✅ Phone App connected to Laptop Bridge (via ADB Reverse)!" -ForegroundColor Green
        }
        $listener.Stop()
    } catch {}
}

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Green
Write-Host "  🚀 USB BRIDGE IS LIVE! DATA FLOWING BETWEEN ESP32 & PHONE   " -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Green
Write-Host "  🔘 [TRIGGER 1]: Press ESP32 Physical Button (GPIO 4)" -ForegroundColor Cyan
Write-Host "  🎙️ [TRIGGER 2]: Clap or Scream near Mic (GPIO 18)" -ForegroundColor Cyan
Write-Host "  📱 [TRIGGER 3]: Tap Red SOS Button in Phone App" -ForegroundColor Cyan
Write-Host "==============================================================" -ForegroundColor Green
Write-Host "  Press Ctrl+C to stop the bridge" -ForegroundColor Gray
Write-Host ""

try {
    while ($true) {
        # Check incoming line from ESP32 Serial
        if ($serial.IsOpen -and $serial.BytesToRead -gt 0) {
            try {
                $line = $serial.ReadLine().Trim()
                if ($line.Length -gt 0) {
                    $timestamp = (Get-Date).ToString("HH:mm:ss")
                    
                    if ($line.Contains("SOS_TRIGGERED")) {
                        Write-Host "[$timestamp] 🚨 ESP32 ALERT TRIGGERED -> Sending to Phone: $line" -ForegroundColor Red
                    } elseif ($line.Contains("ALERT_RESET")) {
                        Write-Host "[$timestamp] 🛡️ ESP32 ALERT RESET -> Sending to Phone: $line" -ForegroundColor Green
                    } elseif ($line.Contains("HEARTBEAT")) {
                        Write-Host "[$timestamp] 💓 ESP32 Telemetry: $line" -ForegroundColor DarkGray
                    } else {
                        Write-Host "[$timestamp] 📡 ESP32: $line" -ForegroundColor Gray
                    }

                    # Forward to Phone App over TCP
                    if ($writer -and $tcp -and $tcp.Connected) {
                        try {
                            $writer.WriteLine($line)
                        } catch {
                            Write-Host "[$timestamp] ⚠️ Error sending to phone: $_" -ForegroundColor Yellow
                        }
                    }
                }
            } catch [System.TimeoutException] {
                # Normal timeout
            } catch {
                # Ignore transient read error
            }
        }

        # Check incoming command from Phone App (e.g., SIREN_ON, RESET)
        if ($stream -and $stream.DataAvailable) {
            try {
                $cmd = $reader.ReadLine()
                if ($cmd) {
                    $cmd = $cmd.Trim()
                    $timestamp = (Get-Date).ToString("HH:mm:ss")
                    Write-Host "[$timestamp] 📱 Phone App Command: '$cmd' -> Sending to ESP32" -ForegroundColor Magenta
                    if ($serial.IsOpen) {
                        $serial.WriteLine($cmd)
                    }
                }
            } catch {}
        }

        Start-Sleep -Milliseconds 15
    }
} finally {
    Write-Host "`nClosing connections..." -ForegroundColor Gray
    if ($serial -and $serial.IsOpen) { $serial.Close() }
    if ($tcp) { $tcp.Close() }
    Write-Host "Bridge stopped." -ForegroundColor Gray
}
