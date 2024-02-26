<#
    .Synopsis
        Imports and registers certificate templates in Active Directory from an XML string.
    .Description
        Imports certificate templates from an XML string that contains serialized templates.
        
        If a certificate template is successfully imported, it is installed in Active Directory.
        The command must be run on a Windows 7/Windows Server 2008 R2 or newer OS.
        
        Note: the command generates new object identifier (OID) for the template. Existing
        OID reuse is not supported.
    .Parameter XmlString
        Specifies the XML string that contains exported certificate templates.
    .Parameter Server
        Specifies the DNS name of the Active Directory server to which the changes will be applied.
        If this value is NULL, the changes will be applied to the default domain controller.
    .Example
        $templateObject = @{
            templatePSPKI = Get-CertificateTemplate -Name "WebServer" -ErrorAction Stop | Select-Object *
            templateADO = Get-ADCSTemplate -Name "WebServer" -ErrorAction Stop | Select-Object -Property name, displayName, objectClass, flags, revision, *pki*
        }
        $xmlString = ConvertTo-SerializedTemplate -Template $templateObject        
        Import-SerializedTemplate -XmlString $xmlString
    #>
function Import-SerializedTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$XmlString,
        [string]$Server = (Get-ADDomainController -Discover -ForceDiscover -Writable).HostName[0]
    )
    
    begin {
        if (
            [Environment]::OSVersion.Version.Major -lt 6 -or
                ([Environment]::OSVersion.Version.Major -eq 6 -and [Environment]::OSVersion.Version.Minor -lt 1)
        ) { throw New-Object System.PlatformNotSupportedException "This function requires Windows 7/Windows Server 2008 R2 or newer." }
    
        $encoder = New-Object System.Text.ASCIIEncoding
    }
    
    process {
        try {
            $bytes = $encoder.GetBytes($XmlString)
            $pol = New-Object -ComObject X509Enrollment.CX509EnrollmentPolicyWebService
            $pol.InitializeImport($bytes)
            $templates = $pol.GetTemplates() | ForEach-Object { $_ }
            $importedTemplates = 0
    
            foreach ($template in $templates) {
                try {
                    $adwt = New-Object -ComObject X509Enrollment.CX509CertificateTemplateADWritable
                    $adwt.Initialize($template)
                    $adwt.Commit(1, $Server)
                    Write-Verbose "Template '$($template.Name)' imported successfully."
                    $importedTemplates++
                }
                catch {
                    Write-Warning "Failed to import template '$($template.Name)': $_"
                }
            }
    
            if ($importedTemplates -eq 0) {
                Write-Warning "No templates were imported. Please check the input XML string."
            }
            else {
                Write-Output "$importedTemplates template(s) imported successfully."
            }
        }
        catch {
            Write-Error "An error occurred during the import process: $_"
        }
    }
}