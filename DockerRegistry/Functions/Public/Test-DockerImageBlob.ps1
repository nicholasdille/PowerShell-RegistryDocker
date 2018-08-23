function Test-DockerImageBlob {
    [CmdletBinding()]
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $Registry = 'https://registry.hub.docker.com',

        [Parameter(ParameterSetName='BearerToken', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Token,

        [Parameter(ParameterSetName='HeaderApiKey', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $HeaderKey,

        [Parameter(ParameterSetName='HeaderApiKey', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $HeaderValue,

        [Parameter(ParameterSetName='BasicAuthentication', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Digest
    )

    try {
        $Params = @{
            UseBasicParsing = $true
            Method          = 'Head'
            Uri             = "$Registry/v2/$Repository/blobs/$Digest"
        }
        if ($PSCmdlet.ParameterSetName -ieq 'BearerToken') {
            $Params.Headers.Add('Authorization', "Bearer $Token")

        } elseif ($PSCmdlet.ParameterSetName -ieq 'HeaderApiKey') {
            $Params.Headers.Add($HeaderKey, $HeaderValue)

        } elseif ($PSCmdlet.ParameterSetName -ieq 'BasicAuthentication') {
            $Token = Get-PlaintextFromSecureString -SecureString $Credential.Password
            $Authentication = "$($Credential.UserName):$Token" | ConvertTo-Base64
            $Params.Headers.Add('Authorization', "Basic $Authentication")
        }
        $Response = Invoke-WebRequest @Params -ErrorAction SilentlyContinue

    } catch [System.Net.WebException] {
        $false
        return
    }

    $true
}
