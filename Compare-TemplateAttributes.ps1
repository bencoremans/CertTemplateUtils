<#
.SYNOPSIS
Compares attributes of two certificate templates and identifies differences.

.DESCRIPTION
This function takes two certificate template objects as input and compares their attributes to identify differences. It is specifically designed to handle various attribute types appropriately, including integers, byte arrays, and collections.

.PARAMETER Obj1
The current certificate template object.

.PARAMETER Obj2
The desired certificate template object represented as a PowerShell object, typically obtained from JSON conversion.

.OUTPUTS
Hashtable of differences where keys are attribute names and values are the desired state of those attributes.

.EXAMPLE
$diffs = Compare-TemplateAttributes -Obj1 $currentTemplate -Obj2 $desiredTemplate
This example compares the current and desired state of a certificate template and stores the differences in $diffs.
#>
function Compare-TemplateAttributes {
    param(
        [Parameter(Mandatory)]
        [psobject]$Obj1,

        [Parameter(Mandatory)]
        [psobject]$Obj2
    )

    $differences = @{}
    $properties = ($Obj1.PSObject.Properties.Name + $Obj2.PSObject.Properties.Name) | Select-Object -Unique

    foreach ($property in $properties) {
        $value1 = $Obj1.$property
        $value2 = $Obj2.$property

        # Detecteer en converteer attributen afzonderlijk op basis van hun naam
        if ('flags', 'msPKI-Certificate-Name-Flag', 'msPKI-Enrollment-Flag', 'msPKI-Minimal-Key-Size',
            'msPKI-Private-Key-Flag', 'msPKI-Template-Minor-Revision', 'msPKI-Template-Schema-Version',
            'msPKI-RA-Signature', 'pKIMaxIssuingDepth', 'pKIDefaultKeySpec', 'revision' -contains $property) {
            if ($value1 -ne $value2) {
                $differences[$property] = [int]$value2
            }
        }
        elseif ('msPKI-Certificate-Application-Policy', 'pKICriticalExtensions', 'pKIDefaultCSPs',
                'pKIExtendedKeyUsage', 'msPKI-Certificate-Policy' -contains $property) {
            $array1 = $value1 | ForEach-Object { $_.ToString() }
            $array2 = $value2 | ForEach-Object { $_.ToString() }
            if ($null -ne $array1 -and $null -ne $array2 -and (Compare-Object -ReferenceObject $array1 -DifferenceObject $array2)) {
                $differences[$property] = $value2  # Pas op met conversie
            }
        }
        elseif ('pKIExpirationPeriod', 'pKIKeyUsage', 'pKIOverlapPeriod' -contains $property) {
            if ($null -ne $value1 -and $null -ne $value2 -and (Compare-Object -ReferenceObject $value1 -DifferenceObject $value2)) {
                $differences[$property] = [byte[]]$value2
            }
        }
        else {
            if ($value1 -is [string] -and $value2 -is [string]) {
                $trimmedValue1 = $value1.Trim()
                $trimmedValue2 = $value2.Trim()
                if ($trimmedValue1 -cne $trimmedValue2) {
                    $differences[$property] = $trimmedValue2
                }
            }
            elseif ($value1 -ne $value2) {
                $differences[$property] = $value2
            }
        }
    }

    return $differences
}
