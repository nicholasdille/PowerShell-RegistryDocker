@{
    RootModule = 'DockerRegistry.psm1'
    ModuleVersion = '0.7.1'
    GUID = 'ca2ddc97-8586-45cd-98a4-047d9542f5e5'
    Author = 'Nicholas Dille'
    # CompanyName = ''
    Copyright = '(c) 2017 Nicholas Dille. All rights reserved.'
    Description = 'Cmdlets for talking to Docker Engine and Docker Registry '
    PowerShellVersion = '5.0'
    FunctionsToExport = @(
        'Add-DockerImageLayer'
        'Copy-DockerImage'
        'Get-DockerImageBlob'
        'Get-DockerImageManifest'
        'Get-DockerImageBlob'
        'Get-DockerRegistryToken'
        'Merge-DockerImageLayer'
        'New-DockerImageBlob'
        'New-DockerImageManifest'
        'Test-DockerImageBlob'
    )
    #CmdletsToExport = '*'
    #VariablesToExport = ''
    #AliasesToExport = '*'
    #FormatsToProcess = ''
    RequiredModules = @(
        @{ ModuleName = 'Helpers'; RequiredVersion = '0.4.0.24' }
    )
    PrivateData = @{
        PSData = @{
            Tags = @('Docker', 'Registry', 'Image', 'Layer', 'Manifest', 'Blob')
            LicenseUri = 'https://github.com/nicholasdille/PowerShell-Docker/blob/master/LICENSE'
            ProjectUri = 'https://github.com/nicholasdille/PowerShell-Docker'
            ReleaseNotes = 'https://github.com/nicholasdille/PowerShell-Docker/releases'
        }
    }
}
