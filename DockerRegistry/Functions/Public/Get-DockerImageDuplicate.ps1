function Get-DockerImageDuplicate {
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
        $Tag = 'latest'
    )

    $Params = $PSBoundParameters
    $Manifest = Get-DockerImageManifest @Params | ConvertFrom-Json
    $ConfigDigest = $Manifest.config.digest

    $Params.Remove('Tag') | Out-Null
    $Tags = Get-DockerImageTag @Params

    foreach ($Tag in $Tags) {
        $Manifest = Get-DockerImageManifest @Params -Tag $Tag | ConvertFrom-Json
        if ($Manifest.config.digest -eq $ConfigDigest) {
            $Tag
        }
    }
}