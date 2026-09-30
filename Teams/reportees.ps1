function Get-AllReporteesObjId {
    param (
        [string]$UserId
    )
    $directReports = Get-MgUserDirectReport -UserId $UserId
    $allReportees = @()

    foreach ($report in $directReports) {
        $allReportees += $report
        # Recursively fetch indirect reportees
        $allReportees += Get-AllReportees -UserId $report.Id
    }

    return $allReportees
}

# Run function
#Get-AllReportees -UserId "reid.childress@alaskaair.com"

function Get-AllReportees {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId,
        
        [System.Collections.Generic.HashSet[string]]$VisitedUserIds = [System.Collections.Generic.HashSet[string]]::new()
    )

    if ($VisitedUserIds.Contains($UserId)) {
        return @()
    }
    [void]$VisitedUserIds.Add($UserId)

    $allReportees = @()

    try {
        # Retrieve direct reports
        $directReports = Get-MgUserDirectReport -UserId $UserId -ErrorAction Stop
        
        foreach ($report in $directReports) {
            # Fetch the full User object to populate DisplayName, Mail, UPN
            $fullUser = Get-MgUser -UserId $report.Id -Property Id, DisplayName, UserPrincipalName, Mail, JobTitle

            if ($fullUser) {
                $allReportees += $fullUser
                # Recursively get indirect reports
                $allReportees += Get-AllReportees -UserId $fullUser.Id -VisitedUserIds $VisitedUserIds
            }
        }
    }
    catch {
        Write-Warning "Could not retrieve reports for User ID: $UserId. Error: $_"
    }

    return $allReportees
}

# Run script
$LeaderUserPrincipalName = "director/vp@microsoft.com"
$reportees = Get-AllReportees -UserId $LeaderUserPrincipalName

# Display results
$reportees | Select-Object Id, DisplayName, UserPrincipalName, Mail, JobTitle