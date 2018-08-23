function Get-DockerImageTag {
    Invoke-RestMethod -UseBasicParsing -Uri 'https://index.docker.io/v2/nicholasdille/tools/tags/list' -Headers @{
        'Accept'        = 'application/json'
        'Authorization' = "Bearer $Token"
    }
}