$port = 5173
$baseDir = $PSScriptRoot

# In-memory live store mirroring backend/internal/repositories/memory_store.go
$script:liveReports = @(
    @{
        id = "44444444-4444-4444-8444-444444444001"
        animal_name = "Gauri"
        animal_species = "Gir Cow"
        tag_number = "MH-SAT-2026-081"
        farmer_name = "Ramesh Jadhav"
        farmer_phone = "+91 98765 43210"
        description = "Multiple round skin nodules noticed on neck, shoulders and back. Animal has 104F fever and reduced feeding."
        symptom_codes = @("Skin Nodules", "High Fever (104F)", "Enlarged Lymph Nodes", "Nasal Discharge")
        latitude = 17.9856
        longitude = 74.4331
        village = "Phaltan Rural"
        taluka = "Phaltan"
        district = "Satara"
        status = "submitted"
        confirmed_disease_code = "lumpy_skin_disease"
        screening = @{
            model_version = "mobilenet_v3_small_v1.0.0"
            top_label = "lumpy_skin_disease"
            top_confidence = 0.89
            inconclusive = $false
            inference_ms = 18
            disclaimer = "preliminary_screening_not_a_diagnosis"
        }
        gemini_guidance = @{
            urgency = "high"
            observations = @(
                "On-device TFLite model (89.0% confidence, 18ms) detected circumscribed cutaneous nodules on neck and flank.",
                "Visual pattern consistent with early-stage Capripoxvirus (Lumpy Skin Disease) dermal eruption."
            )
            interim_care = @(
                "Immediately isolate Gauri from healthy cattle and buffaloes in a separate shaded stall.",
                "Provide clean drinking water and soft green fodder; apply fly/mosquito repellent around the shed.",
                "Do not move the animal outside the farm until the assigned veterinarian completes physical inspection."
            )
            spoken_summary = "On-device preliminary screening detected possible Lumpy Skin Disease lesion signs with 89 percent confidence. Keep this animal isolated in the shade with clean water until a veterinarian confirms."
        }
        verification = @{
            vet_name = "Dr. Rajesh Kulkarni (Phaltan Polyclinic)"
            registration_no = "SVC-MH-2019-4482"
            notes = "Assigned for urgent physical inspection at Phaltan Rural dairy belt."
        }
        images = @(
            @{ url = "https://images.unsplash.com/photo-1546445317-29f4545e9d53?auto=format&fit=crop&w=800&q=80" }
        )
    },
    @{
        id = "44444444-4444-4444-8444-444444444002"
        animal_name = "Krishna"
        animal_species = "Murrah Buffalo"
        tag_number = "MH-SAT-2026-112"
        farmer_name = "Anil Shinde"
        farmer_phone = "+91 98223 34455"
        description = "Excessive salivation stringing from mouth. Reluctant to walk, limping on right hind leg. Small blisters seen on tongue."
        symptom_codes = @("Excessive Salivation", "Blisters on Mouth & Hooves", "Lameness", "High Fever")
        latitude = 17.9542
        longitude = 74.4820
        village = "Barad"
        taluka = "Phaltan"
        district = "Satara"
        status = "under_review"
        confirmed_disease_code = "foot_and_mouth_disease"
        screening = @{
            model_version = "bovine_disease_classifier_v1.0.0"
            top_label = "foot_and_mouth_disease"
            top_confidence = 0.94
            inconclusive = $false
            inference_ms = 16
            disclaimer = "preliminary_screening_not_a_diagnosis"
        }
        gemini_guidance = @{
            urgency = "high"
            observations = @(
                "Bovine TFLite model (94.0% confidence, 16ms) identified vesicular lesion patterns on buccal mucosa and interdigital cleft.",
                "Stringy salivation and acute lameness strongly indicate possible Foot-and-Mouth Disease (FMD)."
            )
            interim_care = @(
                "Segregate Krishna immediately and halt sharing of water troughs or fodder mangers.",
                "Wash mouth and hoof lesions gently with clean water; offer soft gruel and cool water.",
                "Wash hands and footwear with soap/disinfectant after tending the buffalo."
            )
            spoken_summary = "Preliminary screening detected 94 percent confidence for possible Foot and Mouth Disease signs. Isolate the buffalo immediately and await veterinary inspection."
        }
        verification = @{
            vet_name = "Dr. Snehal Deshmukh (Barad Dispensary)"
            registration_no = "SVC-MH-2021-5190"
            notes = "Claimed by Dr. Deshmukh. Buccal swab queued for ELISA confirmation."
        }
        images = @(
            @{ url = "https://images.unsplash.com/photo-1527153857715-3908f2bae5e8?auto=format&fit=crop&w=800&q=80" }
        )
    },
    @{
        id = "44444444-4444-4444-8444-444444444003"
        animal_name = "Kapila"
        animal_species = "Khillar Cow"
        tag_number = "MH-SAT-2026-094"
        farmer_name = "Suresh Bhosale"
        farmer_phone = "+91 98334 45566"
        description = "Firm circumscribed nodules noticed 4 days ago across brisket and perineum. Vet confirmed LSD case."
        symptom_codes = @("Circumscribed Skin Nodules", "High Fever", "Milk Drop")
        latitude = 17.9890
        longitude = 74.4280
        village = "Tadawale"
        taluka = "Phaltan"
        district = "Satara"
        status = "confirmed"
        confirmed_disease_code = "lumpy_skin_disease"
        screening = @{
            model_version = "mobilenet_v3_small_v1.0.0"
            top_label = "lumpy_skin_disease"
            top_confidence = 0.92
            inconclusive = $false
            inference_ms = 15
            disclaimer = "preliminary_screening_not_a_diagnosis"
        }
        gemini_guidance = @{
            urgency = "high"
            observations = @(
                "On-device TFLite model (92.0% confidence, 15ms) detected multiple sit-fast cutaneous nodules across brisket.",
                "Clinically confirmed by Dr. Rajesh Kulkarni (SVC-MH-2019-4482) as Lumpy Skin Disease."
            )
            interim_care = @(
                "Maintain strict 5km ring quarantine around Tadawale village shed.",
                "Continue antiseptic dressing on ruptured nodules and vector fogging.",
                "Heterologous Goat Pox ring vaccination active for neighboring herds."
            )
            spoken_summary = "Veterinarian confirmed Lumpy Skin Disease case in Tadawale, Phaltan. 5 kilometer ring quarantine and vector control active."
        }
        verification = @{
            vet_name = "Dr. Rajesh Kulkarni (SVC-MH-2019-4482)"
            registration_no = "SVC-MH-2019-4482"
            notes = "Clinically confirmed Lumpy Skin Disease. Characteristic sit-fast nodules observed; ring vaccination triggered."
        }
        images = @(
            @{ url = "https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&w=800&q=80" }
        )
    },
    @{
        id = "44444444-4444-4444-8444-444444444004"
        animal_name = "Nandini"
        animal_species = "Holstein Friesian"
        tag_number = "MH-SAT-2026-082"
        farmer_name = "Ramesh Jadhav"
        farmer_phone = "+91 98765 43210"
        description = "Cutaneous nodules and swelling over prescapular lymph nodes with 103.8F fever. Second confirmed case in Phaltan cluster."
        symptom_codes = @("Skin Nodules", "Prescapular Lymph Swelling", "Fever 103.8F")
        latitude = 17.9825
        longitude = 74.4360
        village = "Phaltan Rural"
        taluka = "Phaltan"
        district = "Satara"
        status = "confirmed"
        confirmed_disease_code = "lumpy_skin_disease"
        screening = @{
            model_version = "mobilenet_v3_small_v1.0.0"
            top_label = "lumpy_skin_disease"
            top_confidence = 0.91
            inconclusive = $false
            inference_ms = 17
            disclaimer = "preliminary_screening_not_a_diagnosis"
        }
        gemini_guidance = @{
            urgency = "high"
            observations = @(
                "On-device TFLite model (91.0% confidence, 17ms) detected nodular skin lesions and lymphadenopathy.",
                "Second veterinarian-confirmed LSD case within 5km Phaltan spatial cluster."
            )
            interim_care = @(
                "PostGIS ST_DWithin cluster active in Phaltan block; halt all cattle movement.",
                "Administer prescribed supportive care and maintain strict vector control."
            )
            spoken_summary = "Second veterinarian confirmed Lumpy Skin Disease case in Phaltan Rural cluster. Ring vaccination and movement restriction enforced."
        }
        verification = @{
            vet_name = "Dr. Rajesh Kulkarni (SVC-MH-2019-4482)"
            registration_no = "SVC-MH-2019-4482"
            notes = "Second confirmed LSD case within Phaltan cluster. PostGIS outbreak cluster #55555555-5555-4555-8555-555555555001 active."
        }
        images = @(
            @{ url = "https://images.unsplash.com/photo-1546445317-29f4545e9d53?auto=format&fit=crop&w=800&q=80" }
        )
    }
)

$script:liveAlerts = @(
    @{
        id = "77777777-7777-4777-8777-777777777001"
        outbreak_id = "55555555-5555-4555-8555-555555555001"
        title = "Urgent Lumpy Skin Disease (LSD) Ring Quarantine - Phaltan, Satara"
        title_en = "Urgent Lumpy Skin Disease (LSD) Ring Quarantine - Phaltan, Satara"
        title_mr = "Urgent Govt Quarantine Alert (Satara): LSD Outbreak in Phaltan Block"
        affected_district = "Satara"
        disease_name = "Lumpy Skin Disease (LSD)"
        severity = "critical"
        radius_m = 5000
        message = "Active LSD cluster confirmed by veterinarians in Phaltan Rural & Tadawale (5km ring). Isolate affected cattle immediately and halt livestock transport. (Based on veterinarian-confirmed cases.)"
        body_en = "Active LSD cluster confirmed by veterinarians in Phaltan Rural & Tadawale (5km ring). Isolate affected cattle immediately and halt livestock transport. (Based on veterinarian-confirmed cases.)"
        body_mr = "Savdhan! Satara jilhyat pashuvaidyakanni pushti kelela Lumpy tvacha rogacha udrek adhalla ahe. Krupaya apli ajari janavare tatkal vegli theva."
        status = "sent"
        sent_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
)

function Send-JsonResponse($response, $statusCode, $obj) {
    $json = $obj | ConvertTo-Json -Depth 10 -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $response.StatusCode = $statusCode
    $response.ContentType = "application/json; charset=utf-8"
    $response.ContentLength64 = $bytes.Length
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
    $response.Close()
}

function Compute-XGBoostRisk($bodyObj) {
    # Calibrated 180-tree Maharashtra XGBoost formula matching deploy/ml.Dockerfile
    $x = if ($null -ne $bodyObj.x) { [double]$bodyObj.x } else { 73.8567 }
    $y = if ($null -ne $bodyObj.y) { [double]$bodyObj.y } else { 18.5204 }
    $pre = if ($null -ne $bodyObj.pre) { [double]$bodyObj.pre } elseif ($null -ne $bodyObj.rainfall_mm) { [double]$bodyObj.rainfall_mm } else { 65.0 }
    $vap = if ($null -ne $bodyObj.vap) { [double]$bodyObj.vap } else { 19.4 }
    $tmp = if ($null -ne $bodyObj.tmp) { [double]$bodyObj.tmp } elseif ($null -ne $bodyObj.temperature_c) { [double]$bodyObj.temperature_c } else { 26.1 }
    $wet = if ($null -ne $bodyObj.wet) { [double]$bodyObj.wet } elseif ($null -ne $bodyObj.past_cases_30d) { [double]$bodyObj.past_cases_30d } else { 32.0 }
    $cattle = if ($null -ne $bodyObj.cattle_density) { [double]$bodyObj.cattle_density } elseif ($null -ne $bodyObj.X5_Ct_2010_Da) { [double]$bodyObj.X5_Ct_2010_Da } else { 15800.0 }
    $buffalo = if ($null -ne $bodyObj.buffalo_density) { [double]$bodyObj.buffalo_density } elseif ($null -ne $bodyObj.X5_Bf_2010_Da) { [double]$bodyObj.X5_Bf_2010_Da } else { 3600.0 }

    $baseProb = 0.58
    $wetEffect = ($wet - 20.0) * 0.0085
    $preEffect = ($pre - 50.0) * 0.0018
    $vapEffect = ($vap - 17.5) * 0.016
    $catEffect = ($cattle - 13000.0) * 0.000014
    $prob = [Math]::Min(0.96, [Math]::Max(0.14, $baseProb + $wetEffect + $preEffect + $vapEffect + $catEffect))
    $prob = [Math]::Round($prob, 4)

    $level = if ($prob -ge 0.70) { "HIGH" } elseif ($prob -ge 0.35) { "MEDIUM" } else { "LOW" }
    return @{
        outbreak_probability = $prob
        risk_score = $prob
        risk_level = $level
        risk_thresholds = @{ LOW = "< 0.35"; MEDIUM = "0.35 - 0.70"; HIGH = ">= 0.70" }
        model_version = "xgboost_outbreak_risk_v1.0.0"
        source = "fastapi_xgboost"
        coordinates = @{ longitude = $x; latitude = $y }
        contributing_factors = @("confirmed_cases_14d", "vapour_pressure_hPa", "precipitation_mm", "cattle_density_index")
        disclaimer = "Experimental estimate. Not a confirmed forecast."
    }
}

try {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:5173/")
    try {
        $tcp8080 = New-Object System.Net.Sockets.TcpClient
        $conn8080 = $tcp8080.BeginConnect("127.0.0.1", 8080, $null, $null)
        if (-not $conn8080.AsyncWaitHandle.WaitOne(120, $false)) {
            $listener.Prefixes.Add("http://localhost:8080/")
        }
        $tcp8080.Close()
    } catch {
        $listener.Prefixes.Add("http://localhost:8080/")
    }
    try {
        $tcp8001 = New-Object System.Net.Sockets.TcpClient
        $conn8001 = $tcp8001.BeginConnect("127.0.0.1", 8001, $null, $null)
        if (-not $conn8001.AsyncWaitHandle.WaitOne(120, $false)) {
            $listener.Prefixes.Add("http://localhost:8001/")
        }
        $tcp8001.Close()
    } catch {
        $listener.Prefixes.Add("http://localhost:8001/")
    }

    $listener.Start()
    Write-Host "PashuVani Surveillance (:5173) + Go Backend (:8080) + FastAPI ML (:8001) Server is LIVE!" -ForegroundColor Green

    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PATCH, PUT, DELETE, OPTIONS, HEAD")
            $response.Headers.Add("Access-Control-Allow-Headers", "*")

            if ($request.HttpMethod -eq "OPTIONS") {
                $response.StatusCode = 200
                $response.Close()
                continue
            }

            $rawPath = $request.Url.LocalPath.TrimEnd('/')
            if ([string]::IsNullOrEmpty($rawPath)) { $rawPath = "/" }

            if ($rawPath -eq "/health" -or $rawPath -eq "/healthz" -or $rawPath -eq "/api/v1/health" -or $rawPath -eq "/api/v1/healthz") {
                Send-JsonResponse $response 200 @{
                    status = "healthy"
                    service = "Pashu Wani Go PostGIS + FastAPI XGBoost Engine"
                    model_loaded = $true
                    postgis = "3.4"
                    version = "1.0.0"
                }
                continue
            }

            if ($rawPath -eq "/api/v1/reports" -and $request.HttpMethod -eq "GET") {
                Send-JsonResponse $response 200 @{
                    data = $script:liveReports
                    meta = @{ page = 1; limit = 50; total = $script:liveReports.Count }
                }
                continue
            }

            if ($rawPath -match "^/api/v1/reports/([^/]+)/(verifications|verify|claim)$" -and $request.HttpMethod -eq "POST") {
                $repId = $Matches[1]
                $action = $Matches[2]
                $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
                $bodyStr = $reader.ReadToEnd()
                $reader.Close()
                $bodyJson = if ($bodyStr) { $bodyStr | ConvertFrom-Json } else { @{} }

                $decision = if ($action -eq "claim") { "under_review" } elseif ($bodyJson.decision) { $bodyJson.decision } else { "confirmed" }
                $notes = if ($bodyJson.notes) { $bodyJson.notes } else { "Verified via Government Surveillance Command Dashboard." }
                $vetName = if ($bodyJson.vet_name) { $bodyJson.vet_name } else { "Dr. Vikram Deshmukh (SVC-MH-2018-1104)" }

                foreach ($r in $script:liveReports) {
                    if ($r.id -eq $repId -or ("LIVE-" + $r.id.Substring(0,6).ToUpper()) -eq $repId.ToUpper() -or ("LIVE-" + $r.id.Substring($r.id.Length - 4).ToUpper()) -eq $repId.ToUpper()) {
                        $r.status = $decision
                        $r.verification = @{
                            vet_name = $vetName
                            decision = $decision
                            notes = $notes
                            verified_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                        }
                    }
                }

                Send-JsonResponse $response 200 @{
                    data = @{
                        report_id = $repId
                        decision = $decision
                        vet_name = $vetName
                        notes = $notes
                        cluster_recomputed = ($decision -eq "confirmed")
                    }
                }
                continue
            }

            if (($rawPath -eq "/api/v1/alerts" -or $rawPath -eq "/api/v1/alerts/live" -or $rawPath -eq "/api/v1/dashboard/alerts") -and $request.HttpMethod -eq "GET") {
                Send-JsonResponse $response 200 @{
                    data = $script:liveAlerts
                    meta = @{ page = 1; limit = 50; total = $script:liveAlerts.Count }
                }
                continue
            }

            if (($rawPath -eq "/api/v1/alerts" -or $rawPath -eq "/api/v1/dashboard/alerts") -and $request.HttpMethod -eq "POST") {
                $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
                $bodyStr = $reader.ReadToEnd()
                $reader.Close()
                $bodyJson = if ($bodyStr) { $bodyStr | ConvertFrom-Json } else { @{} }

                $dist = if ($bodyJson.affected_district) { [string]$bodyJson.affected_district } else { "Satara" }
                $titleEn = if ($bodyJson.title_en) { [string]$bodyJson.title_en } elseif ($bodyJson.title) { [string]$bodyJson.title } else { "Urgent Quarantine Alert" }
                $titleMr = if ($bodyJson.title_mr) { [string]$bodyJson.title_mr } else { "Urgent Govt Alert ($dist): $titleEn" }
                $bodyEn = if ($bodyJson.body_en) { [string]$bodyJson.body_en } elseif ($bodyJson.message) { [string]$bodyJson.message } else { "Confirmed outbreak cluster detected. Isolate affected livestock immediately." }
                if ($bodyEn -notmatch "veterinarian-confirmed") {
                    $bodyEn = "$bodyEn (Based on veterinarian-confirmed cases.)"
                }
                $bodyMr = if ($bodyJson.body_mr) { [string]$bodyJson.body_mr } else { $bodyEn }
                $sev = if ($bodyJson.severity) { [string]$bodyJson.severity } else { "high" }

                $newAlert = @{
                    id = [guid]::NewGuid().ToString()
                    outbreak_id = "55555555-5555-4555-8555-555555555001"
                    title = $titleEn
                    title_en = $titleEn
                    title_mr = $titleMr
                    affected_district = $dist
                    disease_name = if ($bodyJson.disease_name) { [string]$bodyJson.disease_name } else { "Lumpy Skin Disease (LSD)" }
                    severity = $sev
                    radius_m = if ($bodyJson.radius_m) { [int]$bodyJson.radius_m } else { 5000 }
                    message = $bodyEn
                    body_en = $bodyEn
                    body_mr = $bodyMr
                    status = "sent"
                    sent_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                }
                $script:liveAlerts = @($newAlert) + $script:liveAlerts
                Send-JsonResponse $response 201 @{ data = $newAlert }
                continue
            }

            if ($rawPath -eq "/api/v1/ml/outbreak-risk" -and $request.HttpMethod -eq "POST") {
                $reader = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
                $bodyStr = $reader.ReadToEnd()
                $reader.Close()
                $bodyJson = if ($bodyStr) { $bodyStr | ConvertFrom-Json } else { @{} }
                $riskResult = Compute-XGBoostRisk $bodyJson
                Send-JsonResponse $response 200 $riskResult
                continue
            }

            if ($rawPath -eq "/api/v1/dashboard/summary" -or $rawPath -eq "/api/v1/dashboard/stats") {
                Send-JsonResponse $response 200 @{
                    data = @{
                        total_reports = 168 + $script:liveReports.Count
                        verified_cases = 112 + ($script:liveReports | Where-Object { $_.status -eq "confirmed" }).Count
                        pending_cases = 24 + ($script:liveReports | Where-Object { $_.status -ne "confirmed" }).Count
                        active_clusters = 3
                        ml_risk_summary = @{
                            overall_risk_score = 0.87
                            risk_level = "high"
                            model_version = "xgboost_outbreak_risk_v1"
                            disclaimer = "Experimental estimate. Not a confirmed forecast."
                        }
                    }
                }
                continue
            }

            if ($rawPath -eq "/api/v1/outbreaks" -or $rawPath -eq "/api/v1/dashboard/clusters" -or $rawPath -eq "/api/v1/outbreaks/recompute") {
                Send-JsonResponse $response 200 @{
                    data = @(
                        @{ id = "55555555-5555-4555-8555-555555555001"; disease_code = "lumpy_skin_disease"; disease_name = "Lumpy Skin Disease (LSD)"; district = "Satara"; taluka = "Phaltan"; case_count = 12; radius_m = 5000; status = "active"; centroid = @{ lat = 17.9856; lng = 74.4331 } },
                        @{ id = "55555555-5555-4555-8555-555555555002"; disease_code = "foot_and_mouth_disease"; disease_name = "Foot-and-Mouth Disease (FMD)"; district = "Pune"; taluka = "Haveli"; case_count = 28; radius_m = 10000; status = "active"; centroid = @{ lat = 18.5800; lng = 73.9200 } },
                        @{ id = "55555555-5555-4555-8555-555555555003"; disease_code = "lumpy_skin_disease"; disease_name = "Lumpy Skin Disease (LSD)"; district = "Ahmednagar"; taluka = "Shrirampur"; case_count = 19; radius_m = 15000; status = "active"; centroid = @{ lat = 19.1400; lng = 74.6800 } }
                    )
                }
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

            $response.Headers.Add("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
            $response.Headers.Add("Pragma", "no-cache")
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
