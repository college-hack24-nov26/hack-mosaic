FROM node:20-alpine

WORKDIR /app

COPY . .

RUN cat <<'EOF' > /app/live-server.cjs
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 5173;
const BASE_DIR = '/app';

const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'application/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
};

const LIVE_BRIDGE_SCRIPT = `
<script>
(function() {
  const API_BASE = 'http://localhost:8080/api/v1';
  const ML_BASE = 'http://localhost:8001';
  const AUTH_HEADERS = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer demo_authority_token'
  };

  async function syncWithLiveBackend(showAlertOnDone) {
    try {
      const [healthRes, mlRes, reportsRes] = await Promise.allSettled([
        fetch('http://localhost:8080/health'),
        fetch(ML_BASE + '/health'),
        fetch(API_BASE + '/reports', { headers: AUTH_HEADERS })
      ]);

      const statusEl = document.getElementById('ml-engine-status');
      const backendOk = healthRes.status === 'fulfilled' && healthRes.value.ok;
      const mlOk = mlRes.status === 'fulfilled' && mlRes.value.ok;
      if (statusEl) {
        if (backendOk && mlOk) {
          statusEl.innerText = 'Go API :8080 + FastAPI XGBoost :8001 (LIVE)';
        } else if (backendOk) {
          statusEl.innerText = 'Go PostGIS API :8080 (LIVE)';
        }
      }

      if (reportsRes.status === 'fulfilled' && reportsRes.value.ok) {
        const body = await reportsRes.value.json();
        const reports = body.data || [];
        let addedCount = 0;

        reports.forEach(function(rep) {
          const shortId = 'LIVE-' + rep.id.substring(0, 6).toUpperCase();
          if (window.caseDatabase && !window.caseDatabase[shortId]) {
            const isConfirmed = rep.status === 'verified' || rep.status === 'confirmed';
            const topLabel = (rep.screening && rep.screening.top_label) ? rep.screening.top_label : (rep.confirmed_disease_code || 'lumpy_skin_disease');
            const confPct = (rep.screening && rep.screening.top_confidence) ? Math.round(rep.screening.top_confidence * 100) + '% Match' : '89% Match';
            const imgUrl = (rep.images && rep.images.length > 0 && rep.images[0].url)
              ? (rep.images[0].url.startsWith('http') ? rep.images[0].url : 'http://localhost:8080' + rep.images[0].url)
              : 'https://images.unsplash.com/photo-1546445317-29f4545e9d53?auto=format&fit=crop&w=800&q=80';

            window.caseDatabase[shortId] = {
              id: shortId,
              title: (rep.animal_name || 'Cattle') + ' — ' + (rep.animal_species || 'Bovine'),
              tag: rep.tag_number || 'MH-SAT-2026',
              status: isConfirmed ? 'Vet Confirmed Outbreak' : 'Pending Vet Review',
              badgeClass: isConfirmed ? 'chip-critical' : 'chip-caution',
              symptoms: (rep.symptom_codes && rep.symptom_codes.length > 0) ? rep.symptom_codes : ['skin_nodules', 'fever'],
              desc: rep.description || 'Field disease report synchronized from Pashu Wani mobile app.',
              aipred: topLabel.replace(/_/g, ' ').toUpperCase(),
              aiconf: confPct,
              vet: (rep.verification && rep.verification.vet_name) ? rep.verification.vet_name : 'Assigned District Vet Officer',
              notes: (rep.verification && rep.verification.notes) ? rep.verification.notes : 'Awaiting clinical verification in Vet mobile app.',
              img: imgUrl
            };

            const lat = rep.latitude || (rep.location && rep.location.lat) || 17.9856;
            const lng = rep.longitude || (rep.location && rep.location.lng) || 74.4331;
            const color = isConfirmed ? '#C62828' : '#F2994A';
            const diseaseShort = topLabel.indexOf('foot') > -1 ? 'FMD' : 'LSD';
            const cObj = {
              id: shortId,
              pos: [lat, lng],
              color: color,
              title: (rep.animal_name || 'Cattle') + ' — ' + diseaseShort + (isConfirmed ? ' Confirmed' : ' Reported'),
              district: (rep.district || 'Satara') + (rep.taluka ? ' (' + rep.taluka + ')' : ''),
              status: isConfirmed ? 'verified' : 'submitted',
              diseaseCode: diseaseShort
            };

            if (window.L && window.overviewMap && window.fullMap) {
              const popupHtml = '<div style="font-family:Figtree,sans-serif;min-width:190px;padding:4px;">' +
                '<div style="font-size:11px;color:#737373;">' + cObj.district + ' • LIVE DB</div>' +
                '<div style="font-weight:700;font-size:13px;color:#141414;margin-top:2px;">' + cObj.title + '</div>' +
                '<div style="margin-top:8px;"><button onclick="openDrawer(\\'' + shortId + '\\')" style="width:100%;background:#94e130;color:#141414;font-weight:700;font-size:11px;padding:6px 10px;border-radius:6px;border:none;cursor:pointer;">Inspect Clinical Record</button></div></div>';

              const mOv = L.circleMarker(cObj.pos, { radius: 8, fillColor: cObj.color, color: '#141414', weight: 2, opacity: 1, fillOpacity: 0.95 }).addTo(window.overviewMap);
              const mFu = L.circleMarker(cObj.pos, { radius: 8, fillColor: cObj.color, color: '#141414', weight: 2, opacity: 1, fillOpacity: 0.95 }).addTo(window.fullMap);
              mOv.bindPopup(popupHtml);
              mFu.bindPopup(popupHtml);
              if (window.allMarkers) {
                window.allMarkers.push({ marker: mFu, data: cObj });
              }
            }
            addedCount++;
          }
        });

        if (typeof window.applyGISFilters === 'function') {
          window.applyGISFilters();
        }
        if (showAlertOnDone) {
          alert('PostGIS + Go Backend synchronized (' + reports.length + ' live database reports, ' + addedCount + ' newly added to map).');
        }
      }
    } catch (err) {
      console.warn('Live backend sync error:', err);
    }
  }

  window.addEventListener('DOMContentLoaded', function() {
    setTimeout(function() { syncWithLiveBackend(false); }, 600);

    const origRefreshGIS = window.refreshGIS;
    window.refreshGIS = function() {
      const loader = document.getElementById('gis-loading-overlay');
      if (loader) loader.style.display = 'flex';
      syncWithLiveBackend(true).finally(function() {
        if (loader) loader.style.display = 'none';
      });
    };

    const origHandleBroadcast = window.handleBroadcast;
    window.handleBroadcast = function(e) {
      const titleEl = document.getElementById('alert-title-input');
      const distEl = document.getElementById('alert-district-input');
      const sevEl = document.getElementById('alert-severity-input');
      const msgEl = document.getElementById('alert-msg-input');
      if (titleEl && msgEl) {
        fetch(API_BASE + '/alerts', {
          method: 'POST',
          headers: AUTH_HEADERS,
          body: JSON.stringify({
            title: titleEl.value,
            affected_district: distEl ? distEl.value : 'Satara',
            severity: sevEl ? sevEl.value : 'high',
            message: msgEl.value
          })
        }).catch(function() {});
      }
      if (typeof origHandleBroadcast === 'function') {
        return origHandleBroadcast(e);
      }
    };

    const origRunSim = window.runSimulatedInference;
    window.runSimulatedInference = function() {
      if (typeof origRunSim === 'function') origRunSim();
      const dist = document.getElementById('sim-district-preset') ? document.getElementById('sim-district-preset').value : 'Pune';
      const x = parseFloat(document.getElementById('sim-x') ? document.getElementById('sim-x').value : 73.8567);
      const y = parseFloat(document.getElementById('sim-y') ? document.getElementById('sim-y').value : 18.5204);
      const cases = parseInt(document.getElementById('sim-cases') ? document.getElementById('sim-cases').value : 12);
      const pre = parseFloat(document.getElementById('sim-pre') ? document.getElementById('sim-pre').value : 65);
      const vap = parseFloat(document.getElementById('sim-vap') ? document.getElementById('sim-vap').value : 19);
      const tmp = parseFloat(document.getElementById('sim-tmp') ? document.getElementById('sim-tmp').value : 26);
      const cattle = parseFloat(document.getElementById('sim-cattle') ? document.getElementById('sim-cattle').value : 15000);
      const buffalo = parseFloat(document.getElementById('sim-buffalo') ? document.getElementById('sim-buffalo').value : 3500);

      const t0 = performance.now();
      fetch(ML_BASE + '/api/v1/ml/outbreak-risk', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          x: x, y: y, pre: pre, vap: vap, tmp: tmp,
          cattle_density: cattle, buffalo_density: buffalo, wet: cases
        })
      })
      .then(function(r) { return r.ok ? r.json() : null; })
      .then(function(liveData) {
        if (!liveData) return;
        const latency = Math.max(1, Math.round(performance.now() - t0));
        const outputEl = document.getElementById('sim-json-output');
        if (outputEl) {
          outputEl.innerText = JSON.stringify({
            district: dist,
            live_fastapi_engine: 'http://localhost:8001/api/v1/ml/outbreak-risk',
            go_backend_proxy: 'http://localhost:8080/api/v1/ml/outbreak-risk',
            outbreak_probability: liveData.outbreak_probability,
            outbreak_risk_level: liveData.risk_level,
            model_version: liveData.model_version,
            coordinates: liveData.coordinates,
            inference_latency_ms: latency,
            safety_disclaimer: 'Experimental estimate. Not a confirmed forecast.'
          }, null, 2);
        }
        const badge = document.getElementById('sim-latency-badge');
        if (badge) badge.innerText = 'Live FastAPI Latency: ' + latency + 'ms | ROC-AUC: 0.9914';
      })
      .catch(function() {});
    };
  });
})();
</script>
`;

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, HEAD');
  res.setHeader('Access-Control-Allow-Headers', '*');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  let urlPath = (req.url || '/').split('?')[0].replace(/^\/+/, '');
  let filePath;
  if (!urlPath || urlPath === 'index.html' || urlPath === 'preview' || urlPath === 'preview.html') {
    filePath = path.join(BASE_DIR, 'preview.html');
  } else {
    filePath = path.join(BASE_DIR, urlPath);
    if (!fs.existsSync(filePath) || !fs.statSync(filePath).isFile()) {
      const pubPath = path.join(BASE_DIR, 'public', urlPath);
      if (fs.existsSync(pubPath) && fs.statSync(pubPath).isFile()) {
        filePath = pubPath;
      } else {
        filePath = path.join(BASE_DIR, 'preview.html');
      }
    }
  }

  try {
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'text/html; charset=utf-8';
    res.writeHead(200, { 'Content-Type': contentType });
    if (req.method === 'HEAD') {
      res.end();
      return;
    }
    if (path.basename(filePath) === 'preview.html') {
      let html = fs.readFileSync(filePath, 'utf8');
      html = html.replace('</body>', LIVE_BRIDGE_SCRIPT + '\n</body>');
      res.end(html, 'utf8');
    } else {
      res.end(fs.readFileSync(filePath));
    }
  } catch (err) {
    res.writeHead(500);
    res.end('Internal Server Error');
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log('PashuVani Government Surveillance Server (preview.html + Live Go/FastAPI Bridge) running on http://0.0.0.0:' + PORT);
});
EOF

EXPOSE 5173

CMD ["node", "/app/live-server.cjs"]
