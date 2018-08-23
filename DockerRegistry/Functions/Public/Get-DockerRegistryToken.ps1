function Get-DockerRegistryToken {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential
        ,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository
        ,
        [ValidateSet('pull', 'push')]
        [string[]]
        $Access = 'pull'
    )

    $AccessList = $Access -join ','
    $Params = @{
        'UseBasicParsing' = $true
        'Method'          = 'Get'
        'Uri'             = 'https://auth.docker.io/token?service=registry.docker.io&scope=repository:{0}:{1}' -f $Repository, $AccessList
    }
    if ($PSBoundParameters.ContainsKey('Credential')) {
        $Token = Get-PlaintextFromSecureString -SecureString $Credential.Password
        $Authentication = "$($Credential.UserName):$Token" | ConvertTo-Base64
        if (-not $Params.ContainsKey('Headers')) {
            $Params.Add('Headers', @{})
        }
        $Params.Headers.Add('Authorization', "Basic $Authentication")
    }
    $Response = Invoke-WebRequest @Params

    if ($Response.StatusCode -ne 200) {
        throw 'Failed to obtain token'

    } else {
        $Response.Content | ConvertFrom-Json | Select-Object -ExpandProperty token
    }
}