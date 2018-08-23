function Get-StringHash {
    [CmdletBinding()]
    param(
        [ValidateSet('SHA256')]
        [string]
        $Algorithm = 'SHA256',

        [ValidateSet('ASCII', 'UTF8')]
        [string]
        $Encoding = 'ASCII',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [byte[]]
        $Data
    )

    $StringBuilder = New-Object System.Text.StringBuilder
    [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm).ComputeHash($Data) | ForEach-Object {
        [Void]$StringBuilder.Append($_.ToString("x2"))
    }
    $StringBuilder.ToString()
}