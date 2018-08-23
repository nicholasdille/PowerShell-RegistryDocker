function Merge-DockerImageLayer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Registry,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $BaseRepository,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ParallelRepository
    )

    $ErrorActionPreference = 'Stop'

    #region Target documents
    $TargetManifest = Get-DockerImageManifest -Registry $Registry -Repository $BaseRepository | ConvertFrom-Json
    $TargetConfig = Get-DockerImageBlob -Registry $Registry -Repository $BaseRepository -Digest $TargetManifest.config.digest | ConvertFrom-Json
    #endregion

    #region Patch layers
    'Patching layers'
    $BaseManifest = Get-DockerImageManifest -Registry $Registry -Repository $BaseRepository | ConvertFrom-Json
    $BaseLayerCount = $BaseManifest.layers.Length
    foreach ($Repository in $ParallelRepository) {
        "  from $Repository"

        $ParallelManifest = Get-DockerImageManifest -Registry $Registry -Repository $Repository | ConvertFrom-Json
        $ParallelLayers = $ParallelManifest.layers

        $TargetManifest.layers += $ParallelLayers[$BaseLayerCount,$ParallelLayers.Length]
    }
    #endregion

    #region Patch history
    'Patching history'
    $BaseConfig = Get-DockerImageBlob -Registry $Registry -Repository $BaseRepository -Digest $BaseManifest.config.digest | ConvertFrom-Json
    $BaseHistoryCount = $BaseConfig.history.Length
    "  base has $BaseHistoryCount entries"
    foreach ($Repository in $ParallelRepository) {
        "  from $Repository"

        $ParallelManifest = Get-DockerImageManifest -Registry $Registry -Repository $Repository | ConvertFrom-Json
        $ParallelConfig = Get-DockerImageBlob -Registry $Registry -Repository $Repository -Digest $ParallelManifest.config.digest | ConvertFrom-Json
        $ParallelHistory = $ParallelConfig.history
        "    with $($ParallelHistory.Length) entries"

        $HistoryEnd = $ParallelHistory.Length - 1
        "    appending $($ParallelHistory[$BaseHistoryCount..$HistoryEnd].Length) entries"
        $TargetConfig.history += $ParallelHistory[$BaseHistoryCount..$HistoryEnd]
    }
    #endregion

    #region Patch rootfs
    'Patching rootfs'
    $BaseFsCount = $BaseConfig.rootfs.diff_ids.Length
    foreach ($Repository in $ParallelRepository) {
        "  from $Repository"

        $ParallelManifest = Get-DockerImageManifest -Registry $Registry -Repository $Repository | ConvertFrom-Json
        $ParallelConfig = Get-DockerImageBlob -Registry $Registry -Repository $Repository -Digest $ParallelManifest.config.digest | ConvertFrom-Json
        $ParallelFs = $ParallelConfig.rootfs.diff_ids
        "    with $($ParallelFs.Length) entries"

        $FsEnd = $ParallelFs.Length - 1
        "    appending $($ParallelFs[$BaseFsCount..$FsEnd].Length) entries"
        $TargetConfig.rootfs.diff_ids += $ParallelFs[$BaseFsCount..$FsEnd]
    }
    #endregion

    #region Mount layers
    'Mounting layers'
    foreach ($Repository in $ParallelRepository) {
        "  from $Repository"
        $Manifest = Get-DockerImageManifest -Registry $Registry -Repository $Repository | ConvertFrom-Json
        foreach ($Layer in $Manifest.layers) {
            Add-DockerImageLayer -Registry $Registry -Repository $Name -Digest $Layer.digest -SourceRepository $Repository
        }
    }
    #endregion

    #region Upload config
    'Uploading config'
    $TargetConfigRaw = $TargetConfig | ConvertTo-Json -Depth 10
    New-DockerImageBlob -Registry $Registry -Repository $Name -Data $TargetConfigRaw -ContentType 'application/vnd.docker.container.image.v1+json'
    #endregion

    #region Build manifest
    'Uploading manifest'
    $TargetManifest.config.size = $TargetConfigRaw.Length
    $ConfigDigest = Get-StringHash -Algorithm SHA256 -Encoding ASCII -Data (ConvertTo-ByteArray -Encoding ASCII -Data $TargetConfigRaw)
    $TargetManifest.config.digest = "sha256:$ConfigDigest"
    $TargetManifestRaw = $TargetManifest | ConvertTo-Json -Depth 10
    New-DockerImageManifest -Registry $Registry -Repository $Name -Manifest $TargetManifestRaw -ManifestVersion v2
    #endregion
}