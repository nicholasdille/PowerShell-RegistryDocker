function Get-DockerImageTag {
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
        $Repository
    )

    $Params = @{
        UseBasicParsing = $true
        Method          = 'Get'
        Uri             = "$Registry/v2/$Repository/tags/list"
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

    $Result = Invoke-RestMethod @Params
    $Result.tags
}