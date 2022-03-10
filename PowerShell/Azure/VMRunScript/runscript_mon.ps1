# Monitors jobs started with the Azure runscript script
[CmdletBinding()]
param (

    $MonitorSleepSeconds = 10

)
$Global:CheckedJobs = @()
$Global:ReceivedJobs = @()
While ($true) {
    Write-Output ''
    Write-Output "Checking status of jobs"
    if (!(Compare-Object -ReferenceObject $Global:ScanJobs.Id -DifferenceObject $Global:CheckedJobs)) {
        Write-Output "Think I've finished"
        Exit

    }
    foreach ($job in $global:ScanJobs) {  

        if ($job.State -eq 'Completed' -and $job.id -notin $Global:CheckedJobs) { 
            Write-Output "$($Job.Name): completed."
            $ReceivedJob = $job | Receive-Job
            $ReceivedJob
            $Global:ReceivedJobs += $ReceivedJob
            $Global:CheckedJobs += $job.id 
        
        } elseif ($job.State -ne 'Completed' -and $job.State -ne 'Running') {
            Write-Output "$($Job.Name): did not complete."
            $ReceivedJob = $job | Receive-Job
            $ReceivedJob
            $Global:ReceivedJobs += $ReceivedJob
            $Global:CheckedJobs += $job.id 
        }

    }
    Get-Job -State Running | Format-Table -Property Id,Name,State
    Write-Output "Sleeping $SleepSeconds"
    Start-Sleep -Seconds $MonitorSleepSeconds
}