function New-DockerImageManifest {
    [CmdletBinding(DefaultParameterSetName='Unauthenticated', SupportsShouldProcess, ConfirmImpact='Medium')]
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

        [ValidateNotNullOrEmpty()]
        [string]
        $Tag = 'latest',

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Manifest,

        [ValidateSet('v1', 'v2')]
        [string]
        $ManifestVersion = 'v2'
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Confirm')) {
            $ConfirmPreference = $PSCmdlet.SessionState.PSVariable.GetValue('ConfirmPreference')
        }
        if (-not $PSBoundParameters.ContainsKey('WhatIf')) {
            $WhatIfPreference = $PSCmdlet.SessionState.PSVariable.GetValue('WhatIfPreference')
        }
    }

    process {
        $ContentType = 'application/vnd.docker.distribution.manifest.v2+json'
        if ($ManifestVersion -eq 'v1') {
            $ContentType = 'application/vnd.docker.distribution.manifest.v1+json'
        }

        $Params = @{
            UseBasicParsing    = $true
            Method             = 'Put'
            Uri                = "$Registry/v2/$Repository/manifests/$Tag"
            Headers            = @{
                'Content-Type' = $ContentType
            }
            Body               = $Manifest
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

        if ($Force -or $PSCmdlet.ShouldProcess("Create new manifest for repository $Repository with tag $Tag in registry $Registry?")) {
            Invoke-RestMethod @Params
        }
    }
}