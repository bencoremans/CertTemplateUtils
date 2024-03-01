CertTemplateUtils PowerShell Module
The CertTemplateUtils module is a collection of PowerShell functions designed to facilitate the management of Active Directory Certificate Services (AD CS) templates. This module enables administrators to retrieve, compare, import, and update certificate templates directly within an Active Directory environment.

# Compare-TemplateAttributes Function

## Overview
The `Compare-TemplateAttributes` function is designed to compare the attributes of two certificate templates and identify any differences. This is particularly useful for administrators and IT professionals working with certificate services in a Microsoft environment, to ensure that certificate templates are configured as intended.

## Features
- **Attribute Comparison**: Compares a wide range of certificate template attributes, including integers, byte arrays, and collections.
- **Versatile Input Handling**: Accepts two PowerShell objects representing the current and desired states of a certificate template, facilitating easy integration with automation scripts.
- **Detailed Output**: Provides a hashtable detailing the differences between the two templates, with keys representing attribute names and values indicating the desired state.

## Prerequisites
Before using the `Compare-TemplateAttributes` function, ensure you have a PowerShell environment configured with access to the `CertTemplateUtils` module.

## Parameters

- `Obj1`: The current certificate template object.
- `Obj2`: The desired certificate template object, typically obtained from a JSON conversion.

## Outputs
The function outputs a hashtable where each key is an attribute name and each value is the desired state of that attribute.

## Usage Example

```powershell
$currentTemplate = <# Your current template object #>
$desiredTemplate = <# Your desired template object #>

$diffs = Compare-TemplateAttributes -Obj1 $currentTemplate -Obj2 $desiredTemplate
```
# CertTemplateUtils - ConvertTo-SerializedTemplate Function

## Overview
The `ConvertTo-SerializedTemplate` function is part of the CertTemplateUtils PowerShell module. It is designed to convert certificate template objects into a serialized format, which is useful for defining certificate policies in a standardized way. This function is particularly useful in environments where certificate templates need to be programmatically managed or integrated into automated workflows.

## Description
The function takes certificate template objects as input and converts them into a serialized format. This serialized format is then used to define certificate policies. The function handles various properties of the input templates, including cryptographic settings, validity periods, key usage, and more, ensuring that all necessary information is included in the serialized output.

## Parameters

### `-Template`
- **Type**: Mandatory
- **Description**: Specifies the certificate template object or objects to be converted. Each template object should contain properties for PSPKI (PowerShell PKI module) templates.

## Usage Example

```powershell
$templatePSPKI = Get-CertificateTemplate -Name "WebServer" -ErrorAction Stop | Select-Object *

ConvertTo-SerializedTemplate -Template $templatePSPKI
```

# Get-ADCSTemplate PowerShell Function

## Introduction
The `Get-ADCSTemplate` function is designed to return the properties of either a single or all Active Directory Certificate Templates. It can be used to retrieve detailed information about certificate templates configured in an Active Directory environment.

## Prerequisites
- PowerShell 5.1 or later.
- Active Directory module for Windows PowerShell.
- Requires Enterprise Administrator permissions, as this function interacts with the AD Configuration partition.

## Parameters
- `Name`: (Optional) Specifies the name of an Active Directory Certificate Services (AD CS) template to retrieve. If not provided, the function will return all templates.
- `Server`: (Optional) Specifies the Fully Qualified Domain Name (FQDN) of an Active Directory Domain Controller to target for the operation. If not provided, the function searches for the nearest Domain Controller.

## Usage

To retrieve all AD CS templates:
```powershell
PS C:\> Get-ADCSTemplate
```

To retrieve a specific template by name:
```powershell
PS C:\> Get-ADCSTemplate -Name "PowerShellCMS"
```
To sort templates by name and format the output:
```powershell
PS C:\> Get-ADCSTemplate | Sort-Object Name | Format-Table Name, Created, Modified
```
To view template permissions:
```powershell
PS C:\> $template = Get-ADCSTemplate -Name "pscms"
PS C:\> $template.nTSecurityDescriptor
PS C:\> $template.nTSecurityDescriptor.Sddl
PS C:\> $template.nTSecurityDescriptor.Access
PS C:\> ConvertFrom-SddlString -Sddl $template.nTSecurityDescriptor.sddl -Type ActiveDirectoryRights
```

Ensure you have the necessary permissions to interact with AD CS and the AD Configuration partition.
The function attempts to connect to the nearest Domain Controller by default unless a specific server is provided.

## Examples
Retrieve and Display All Templates
```powershell
Get-ADCSTemplate
```

Retrieve a Specific Template by Name
```powershell
Get-ADCSTemplate -Name "WebServer"
```

Sort and Display Templates by Name
```powershell
Get-ADCSTemplate | Sort-Object Name | Format-Table Name, Created, Modified
```

# Import-SerializedTemplate PowerShell Function

## Introduction
The `Import-SerializedTemplate` function is designed to import and register certificate templates into Active Directory from a provided XML string. This function is particularly useful for automating the deployment of certificate templates across an environment.

## Prerequisites
- PowerShell 5.1 or newer.
- Must be run on Windows 7/Windows Server 2008 R2 or newer.
- Active Directory module for Windows PowerShell.

## Parameters

### `-XmlString`
- **Type**: Mandatory
- **Description**: Specifies the XML string that contains the exported certificate templates.

### `-Server`
- **Type**: Optional
- **Description**: Specifies the DNS name of the Active Directory server to which the changes will be applied. If this parameter is not specified, the changes will be applied to the default domain controller.

## Usage Example

```powershell
$templatePSPKI = Get-CertificateTemplate -Name "WebServer" -ErrorAction Stop | Select-Object *

$xmlString = ConvertTo-SerializedTemplate -Template $templatePSPKI      
  
Import-SerializedTemplate -XmlString $xmlString
```

# Update-CertificateTemplate PowerShell Function

## Introduction
The `Update-CertificateTemplate` function is designed to update the attributes of an existing certificate template in Active Directory. It allows for modifications to certificate templates based on a desired state defined in a JSON string.

## Prerequisites
- PowerShell 5.1 or newer.
- Active Directory PowerShell module.
- Appropriate permissions to modify certificate templates in Active Directory.

## Parameters

### `-Name`
- **Type**: Mandatory
- **Description**: Specifies the name of the certificate template to be updated.

### `-DesiredTemplateJson`
- **Type**: Mandatory
- **Description**: A JSON string that represents the desired state of the certificate template.

### `-Server`
- **Type**: Optional
- **Description**: Specifies the domain controller to connect to. If not specified, the function discovers and uses a writable domain controller.

## Usage Example

```powershell
$templateJson = '{
    "displayName": "Updated Web Server Template",
    "Name": "UpdatedWebServerTemplate",
    "flags": "131649"
}'

Update-CertificateTemplate -Name "WebServerTemplate" -DesiredTemplateJson $templateJson
```
