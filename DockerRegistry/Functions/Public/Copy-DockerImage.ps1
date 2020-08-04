function Copy-DockerImage {
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
        $SourceRepository,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceTag,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationRepository,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $DestinationTag
    )

    # build parameters from $PSBoundParameters
    $CommonParams = @{
        Registry = $Registry
    }
    if ($PSBoundParameters.ContainsKey('Token')) {
        $CommonParams.Add('Token', $Token)
    }
    if ($PSBoundParameters.ContainsKey('HeaderKey')) {
        $CommonParams.Add('HeaderKey', $HeaderKey)
    }
    if ($PSBoundParameters.ContainsKey('HeaderValue')) {
        $CommonParams.Add('HeaderValue', $HeaderValue)
    }
    if ($PSBoundParameters.ContainsKey('Credential')) {
        $CommonParams.Add('Credential', $Credential)
    }

    # Download manifest
    $Manifest = Get-DockerImageManifest @CommonParams -Repository $SourceRepository -Tag $SourceTag

    if ($SourceRepository -ne $DestinationRepository) {

        # Mount layers from source repository
        foreach ($Layer in $Manifest.layers) {
            Add-DockerImageLayer @CommonParams -Repository $DestinationRepository -Digest $Layer.digest -SourceRepository $SourceRepository
        }

        # Mount configuration
        Add-DockerImageLayer @CommonParams -Repository $DestinationRepository -Digest $Manifest.config.digest -SourceRepository $SourceRepository
    }

    # Upload manifest
    New-DockerImageManifest @CommonParams -Repository $DestinationRepository -Tag $DestinationTag -Manifest $Manifest
}
