function New-DockerImageBlob {
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

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Data,

        [ValidateNotNullOrEmpty()]
        [string]
        $ContentType = 'application/octet-string'
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
        $Params = @{
            UseBasicParsing = $true
            Method          = 'Post'
            Uri             = "$Registry/v2/$Repository/blobs/uploads/"
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

        if ($Force -or $PSCmdlet.ShouldProcess("Create new blob for repository $Repository in registry $Registry?")) {
            $UuidResponse = Invoke-WebRequest @Params
            $Location = $UuidResponse.Headers.Location
            Write-Verbose ('Using UUID {0} for uploading to {1}' -f $Uuid, $Repository)

            $Digest = 'sha256:'
            $DataBytes = ConvertTo-ByteArray -Encoding ASCII -Data $Data
            $Digest += Get-StringHash -Algorithm SHA256 -Encoding ASCII -Data $DataBytes

            Write-Verbose ('Uploading data of length {0} with digest {1}' -f $Data.Length, $Digest)
            $Params.Method = 'Put'
            $Params.Uri    = "$Location&digest=$Digest"
            $Params.Body   = $Data
            $Params.Headers.Add('Content-Length', $Data.Length)
            $Params.Headers.Add('Content-Type', $ContentType)
            $Response = Invoke-WebRequest @Params
            if ($Response.StatusCode -ne 201) {
                throw ('Something went wrong uploading the blob. Status code {0} with message <{1}>.' -f $Response.StatusCode, $Response.StatusDescription)
            } else {
                Write-Verbose ('Blob successfully uploaded with digest {0}' -f $Response.Headers.'Docker-Content-Digest')
            }
        }
    }
}