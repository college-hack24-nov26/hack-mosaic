$port = 5173
$prefix = "http://localhost:$port/"
$baseDir = $PSScriptRoot

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
    Write-Host "Pashuvani Surveillance Server is live at $prefix" -ForegroundColor Green

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            # Support CORS headers
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS, HEAD")
            $response.Headers.Add("Access-Control-Allow-Headers", "*")

            if ($request.HttpMethod -eq "OPTIONS") {
                $response.StatusCode = 200
                $response.Close()
                continue
            }

            $urlPath = $request.Url.LocalPath.TrimStart('/')
            if ([string]::IsNullOrEmpty($urlPath) -or $urlPath -eq "index.html" -or $urlPath -eq "preview") {
                $filePath = Join-Path $baseDir "preview.html"
            } else {
                $filePath = Join-Path $baseDir $urlPath
                if (-not (Test-Path $filePath -PathType Leaf)) {
                    $publicPath = Join-Path $baseDir "public\$urlPath"
                    if (Test-Path $publicPath -PathType Leaf) {
                        $filePath = $publicPath
                    }
                }
            }

            if (Test-Path $filePath -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
                switch ($ext) {
                    ".html" { $response.ContentType = "text/html; charset=utf-8" }
                    ".js"   { $response.ContentType = "application/javascript; charset=utf-8" }
                    ".css"  { $response.ContentType = "text/css; charset=utf-8" }
                    ".json" { $response.ContentType = "application/json; charset=utf-8" }
                    default { $response.ContentType = "text/html; charset=utf-8" }
                }
                $response.ContentLength64 = $bytes.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            } else {
                # Fallback to preview.html
                $fallback = Join-Path $baseDir "preview.html"
                $bytes = [System.IO.File]::ReadAllBytes($fallback)
                $response.ContentType = "text/html; charset=utf-8"
                $response.ContentLength64 = $bytes.Length
                if ($request.HttpMethod -ne "HEAD") {
                    $response.OutputStream.Write($bytes, 0, $bytes.Length)
                }
            }
            $response.Close()
        } catch {
            Write-Warning "Request processing error: $_"
        }
    }
} catch {
    Write-Error $_
} finally {
    if ($listener -and $listener.IsListening) {
        $listener.Stop()
    }
}
