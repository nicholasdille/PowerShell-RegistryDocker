function Get-DockerImageBlob {
    [CmdletBinding(DefaultParameterSetName='Unauthenticated')]
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

    $Params = @{
        UseBasicParsing = $true
        Method          = 'Get'
        Uri             = "$Registry/v2/$Repository/blobs/$Digest"
        Headers         = @{}
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

    $Response = Invoke-WebRequest @Params
    ConvertFrom-ByteArray -Data $Response.Content -Encoding ASCII
}
