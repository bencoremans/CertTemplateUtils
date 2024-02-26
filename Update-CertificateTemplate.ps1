<#
.SYNOPSIS
Updates the attributes of an existing certificate template in Active Directory.

.DESCRIPTION
This function updates an existing certificate template in Active Directory with desired attribute values. It first retrieves the current state of the template, compares it with the desired state, and applies any differences.

.PARAMETER Name
The name of the certificate template to update.

.PARAMETER DesiredTemplateJson
A JSON string representing the desired state of the certificate template.

.PARAMETER Server
(Optional) The domain controller to connect to. If not specified, the function discovers and uses a writable domain controller.

.EXAMPLE
Update-CertificateTemplate -Name "WebServerTemplate" -DesiredTemplateJson $templateJson
This example updates the "WebServerTemplate" with the desired attributes specified in the $templateJson string.
#>
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

        $desiredTemplate = $DesiredTemplateJson | ConvertFrom-Json -ErrorAction Stop
        $differences = Compare-TemplateAttributes -Obj1 ($currentTemplate | Select-Object -Property name, displayName, objectClass, flags, revision, *pki*) -Obj2 $desiredTemplate
        if ($differences.Count -gt 0) {
            Set-ADObject -Identity $currentTemplate.DistinguishedName -Replace $differences -Server $Server -ErrorAction Stop
            Write-Host "Template '$Name' updated successfully with the following changes:"
            $differences.GetEnumerator() | ForEach-Object { Write-Host "$($_.Key): $($_.Value)" }
        } else {
            Write-Host "No changes detected for template '$Name'."
        }
    } Catch {
        Write-Error "An error occurred: $_"
    }
}
