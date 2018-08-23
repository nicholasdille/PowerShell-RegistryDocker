function Get-DockerImageManifest {
    [CmdletBinding(DefaultParameterSetName='Unauthenticated')]
    param(
        [ValidateNotNullOrEmpty()]
        [string]
        $Registry = 'https://registry.hub.docker.com',

        [Parameter(ParameterSetName='BearerToken')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Token,

        [Parameter(ParameterSetName='HeaderApiKey')]
        [ValidateNotNullOrEmpty()]
        [string]
        $HeaderKey,

        [Parameter(ParameterSetName='HeaderApiKey')]
        [ValidateNotNullOrEmpty()]
        [string]
        $HeaderValue,

        [Parameter(ParameterSetName='BasicAuthentication')]
        [ValidateNotNullOrEmpty()]
        [pscredential]
        $Credential,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Repository,

        [ValidateNotNullOrEmpty()]
        [string]
        $Tag = 'latest',

        [ValidateSet('v1', 'v2')]
        [string]
        $ManifestVersion = 'v2'
    )

    $ContentType = 'application/vnd.docker.distribution.manifest.v2+json'
    if ($ManifestVersion -eq 'v1') {
        $ContentType = 'application/vnd.docker.distribution.manifest.v1+json'
    }

    $Params = @{
        UseBasicParsing = $true
        Method          = 'Get'
        Uri             = "$Registry/v2/$Repository/manifests/$Tag"
        Headers         = @{
            Accept      = $ContentType
        }
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