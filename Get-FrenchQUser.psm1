<#
.Synopsis
    Obtient les users connectés sur un ordinateur distant.
.DESCRIPTION
    Obtient les users connectés sur un ordinateur distant. Permet d'obtenir des informations intéressantes.
.EXAMPLE
    Get-QUser -ComputerName "remote-computer01"
#>
 
Function Get-QUser {
    [CmdletBinding()]
    Param (
        [String]$ComputerName = $env:COMPUTERNAME
    )

    Begin {
        $ErrorActionPreference = "Stop"
        
        # Format le Idle time et retourne un format DateTime formatté.
        Function Format-LastInputTime {
            Param (
                [Array]$Value
            )

            [Array]$ArrayTime = ((($Value -replace ':', ',') -replace '\+', ',')).Split(",")
            [Array]::Reverse($ArrayTime)
                    
            $CurrentDate = Get-Date

            For($i=0; $i -lt $ArrayTime.Length; $i++) {
                Switch ($i) {
                    0 { $CurrentDate = $CurrentDate.AddMinutes(-$ArrayTime[$i]) }
                    1 { $CurrentDate = $CurrentDate.AddHours(-$ArrayTime[$i]) }
                    2 { $CurrentDate = $CurrentDate.AddDays(-$ArrayTime[$i]) }
                }
            }

            $CurrentDate.ToString("yyyy-MM-dd HH:mm")
        }

        # Retourne un PSObject formaté.
        Function Format-Body {
            Param (
                [Array]$Headers,
                [String]$RawBodyLine
            )

            $PSObject = New-Object -TypeName PSObject
            $Index = 0;

            $RawBodyLine.Split(",") | ForEach-Object {
                $Value = $_

                Switch -Regex ($_) {
                    "D.co" { $Value = "Inactif" }
                    "(^\.|aucun)" { $Value = "0" }
                }

                Switch ($Index) {
                    1 { If($Value -match '^\d.*') { $Index++; } }
                    4 { $Value = Format-LastInputTime -Value $Value }
                }

                $PSObject | Add-Member -MemberType NoteProperty -Name $Headers[$Index]  -Value "$($Value)"
                $Index++
            }

            $PSObject
        }
    }
    Process {
        $QUserRaw = (quser.exe /server:$ComputerName)
        $Headers = @("Username", "Session", "ID", "State", "LastInputTime", "SessionTime")

        $Output = ((($QUserRaw | Select-Object -Skip 1) -replace '^\s' ) -replace '\s{2,}', ',') | ForEach-Object {
            Format-Body -RawBodyLine $_ -Headers $Headers
            
        }
        
        $Output
    }
}