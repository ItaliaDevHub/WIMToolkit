# Ask for admin privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Admin privileges are required, restarting as admin..." -ForegroundColor Red
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

########################################################

# Disable quick edit mode
Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int mode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern IntPtr GetStdHandle(int handle);
"@ -Namespace Win32 -Name NativeMethods

$Handle = [Win32.NativeMethods]::GetStdHandle(-10)
$success = $false

# Retry logic for disabling Quick Edit mode
while (-not $success) {
    $success = [Win32.NativeMethods]::SetConsoleMode($Handle, 0x0080)

    if ($success) {
        Write-Host "Quick Edit mode has been disabled." -ForegroundColor Green
    } else {
        Write-Host "Failed to disable Quick Edit mode. Retrying..." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

########################################################

# Check for process
Write-Host -Fore Green 'The debloat process will start shortly. The mouse and keyboard will be disabled until the operations are completed.'

$processName = 'SecurityHealthSystray'
$processCheckInterval = 3  # Interval in seconds

# Monitor process until it's found
while (-not (Get-Process -Name $processName -ErrorAction SilentlyContinue)) {
    Write-Host "$processName is not running. Checking again..." -ForegroundColor Yellow
    Start-Sleep -Seconds $processCheckInterval
}

Write-Host "$processName is running." -ForegroundColor Green

########################################################

# Block user input
$code = @"
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
"@

$userInput = Add-Type -MemberDefinition $code -Name UserInput -Namespace UserInput -PassThru

function Disable-UserInput {
    try {
        $userInput::BlockInput($true)
        Write-Host "User input has been disabled." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to disable user input." -ForegroundColor Red
    }
}

# Disable user Input
Disable-UserInput

Start-Sleep -Seconds 30

# Start secondary script
try {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File 'C:\Windows\main.ps1' -Wait"
    Write-Host "Main script executed successfully." -ForegroundColor Green
} catch {
    Write-Host "Error starting the main script: $_" -ForegroundColor Red
}

# Force shutdown after operations
Stop-Computer -Force
exit
