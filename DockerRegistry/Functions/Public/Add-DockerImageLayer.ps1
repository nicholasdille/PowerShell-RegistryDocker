function Add-DockerImageLayer {
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
        $Digest,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SourceRepository
    )

    Write-Debug ('Operating on registry {0}' -f $Registry)
    Write-Verbose ('Adding new layer to repository {0} with digest {1} from repository {2}' -f $Repository, $Digest, $SourceRepository)
    $Params = @{
        UseBasicParsing      = $true
        Method               = 'Post'
        Uri                  = "$Registry/v2/$Repository/blobs/uploads/?mount=$($Digest)&from=$SourceRepository"
        Headers              = @{
            'Content-Length' = 0
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
    Write-Verbose ('Uploaded with UUID {0}' -f $Response.Headers.'Docker-Upload-Uuid')
    if ($Response.StatusCode -ne 201) {
        throw ('Something went wrong mounting the layer. Status code {0} with message <{1}>.' -f $Response.StatusCode, $Response.StatusDescription)
    } else {
        Write-Verbose ('Layer successfully added with digest {0} at URL {1}' -f $Response.Headers.'Docker-Content-Digest', $Response.Headers.Location)
    }
}
