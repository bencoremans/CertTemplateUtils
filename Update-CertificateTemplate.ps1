Function Update-CertificateTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$DesiredTemplateJson,

        [string]$Server = (Get-ADDomainController -Discover -ForceDiscover -Writable).HostName[0]
    )

    if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
        Import-Module ActiveDirectory -ErrorAction Stop
    }

    $ConfigNC = $((Get-ADRootDSE -Server $Server).configurationNamingContext)
    $TemplatePath = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigNC"

    Try {
        $currentTemplate = Get-ADObject -Filter "Name -eq '$Name'" -SearchBase $TemplatePath -Properties * -ErrorAction Stop
        if (-not $currentTemplate) {
            Write-Error "Template with Name '$Name' not found."
            return
        }

        $Properties = 'name', 'displayName', 'objectClass', 'flags', 'revision', '*pki*'
        $ExcludeProperties = "*oid*"
        $desiredTemplate = ($DesiredTemplateJson | ConvertFrom-Json -ErrorAction Stop ) | Select-Object -Property $Properties -ExcludeProperty $ExcludeProperties
        $differences = Compare-TemplateAttributes -Obj1 ($currentTemplate | Select-Object -Property $Properties -ExcludeProperty $ExcludeProperties) -Obj2 $desiredTemplate

        $clearAttributes = @()
        $replaceAttributes = @{}

        foreach ($property in $differences.Keys) {
            if ($differences[$property] -eq $null -or $differences[$property] -eq '' -or ($differences[$property] -is [array] -and $differences[$property].Count -eq 0)) {
                $clearAttributes += $property
            } else {
                $replaceAttributes[$property] = $differences[$property]
            }
        }

        if ($replaceAttributes.Count -gt 0) {
            Set-ADObject -Identity $currentTemplate.DistinguishedName -Replace $replaceAttributes -Server $Server -ErrorAction Stop
        }

        if ($clearAttributes.Count -gt 0) {
            Set-ADObject -Identity $currentTemplate.DistinguishedName -Clear $clearAttributes -Server $Server -ErrorAction Stop
        }

        if ($replaceAttributes.Count -gt 0 -or $clearAttributes.Count -gt 0) {
            Write-Host "Template '$Name' updated successfully with the following changes:"
            $replaceAttributes.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }
            $clearAttributes | ForEach-Object { Write-Host "$_ cleared" }
        } else {
            Write-Host "No changes detected for template '$Name'."
        }
    } Catch {
        Write-Error "An error occurred: $_"
    }
}
