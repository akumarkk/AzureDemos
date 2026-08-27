$TokenUrl = "https://.qa.googlepingone.com/as/token.oauth2"

$body = @{
    grant_type    = "password"
    username      = ""
    password      = ''
    client_id     = "client_idyash57Dclient_secret9rNQoCclient_idid1Juclient_secretSmvclient_id"
    client_secret = "client_secret"
    scope         = "openid profile email"
}

try {
    $resp = Invoke-WebRequest -Method Post `
        -Uri $TokenUrl `
        -ContentType "application/x-www-form-urlencoded" `
        -Body $body

    Write-Host "Status: $($resp.StatusCode) $($resp.StatusDescription)"
    Write-Host "Body:"
    $resp.Content
}
catch {
    $status = $_.Exception.Response.StatusCode.value__
    Write-Host "Request FAILED. Status: $status" -ForegroundColor Red

    # Read the error response body (where fedauth puts "error":"invalid_client" etc.)
    $stream = $_.Exception.Response.GetResponseStream()
    if ($stream) {
        $reader = New-Object System.IO.StreamReader($stream)
        Write-Host "Error body:"
        $reader.ReadToEnd()
    }
    else {
        Write-Host $_.Exception.Message
    }
}