$logFilePath = "E:\Projects\Workshop_CICD\_FULL_DEPLOY\Azure\terraform_apply_log.txt"

if (Test-Path $logFilePath) {
    Remove-Item $logFilePath -Force
}

$start = Get-Date

# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.host/start-transcript?view=powershell-7.4
Start-Transcript -Path $logFilePath -Append

cd E:\Projects\Workshop_CICD\_FULL_DEPLOY\Azure

terraform apply -auto-approve

Stop-Transcript

$end = Get-Date

$duration = $end - $start
$totalSeconds = [math]::Round($duration.TotalSeconds)
$minutes = [math]::Floor($totalSeconds / 60) 
$seconds = $totalSeconds % 60 

Write-Host -ForegroundColor Blue "Terraform apply took $minutes minute(s) and $seconds second(s) to complete."
