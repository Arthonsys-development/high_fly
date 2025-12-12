# CORS Error Fix for Flutter Web

## Problem
When running the Flutter app on Chrome (web), you may encounter this error:
```
[http-error] [GET] http://64.227.154.65:81/api/v1/organization/
Message: The connection errored: The XMLHttpRequest onError callback was called. 
This typically indicates an error on the network layer.
```

This is a **CORS (Cross-Origin Resource Sharing)** error. Browsers block requests from one origin (e.g., `http://localhost:8080`) to another origin (e.g., `http://64.227.154.65:81`) unless the server explicitly allows it.

## Root Cause
The backend server at `http://64.227.154.65:81` is not configured to allow cross-origin requests from your Flutter web app. The browser's security policy blocks these requests.

## Solution

### Option 1: Configure CORS on the Backend Server (Recommended)
The backend server needs to add CORS headers to allow requests from your web app. Here are the required headers:

#### For Django (Python):
```python
# In settings.py or middleware
CORS_ALLOWED_ORIGINS = [
    "http://localhost:8080",
    "http://localhost:3000",
    "http://127.0.0.1:8080",
    # Add your production domain here
]

CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'x-tenant-api-key',
]

CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]
```

Or use `django-cors-headers` package:
```python
INSTALLED_APPS = [
    ...
    'corsheaders',
    ...
]

MIDDLEWARE = [
    ...
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    ...
]
```

#### For Express.js (Node.js):
```javascript
const cors = require('cors');

app.use(cors({
  origin: [
    'http://localhost:8080',
    'http://localhost:3000',
    // Add your production domain
  ],
  credentials: true,
  allowedHeaders: [
    'Content-Type',
    'Authorization',
    'X-Tenant-API-Key',
  ],
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
}));
```

#### For Flask (Python):
```python
from flask_cors import CORS

app = Flask(__name__)
CORS(app, resources={
    r"/api/*": {
        "origins": ["http://localhost:8080", "http://localhost:3000"],
        "methods": ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization", "X-Tenant-API-Key"],
        "supports_credentials": True
    }
})
```

#### For Nginx (Reverse Proxy):
Add these headers in your Nginx configuration:
```nginx
location /api/ {
    add_header 'Access-Control-Allow-Origin' '*' always;
    add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, PATCH, OPTIONS' always;
    add_header 'Access-Control-Allow-Headers' 'Content-Type, Authorization, X-Tenant-API-Key' always;
    add_header 'Access-Control-Allow-Credentials' 'true' always;
    
    if ($request_method = 'OPTIONS') {
        return 204;
    }
    
    proxy_pass http://64.227.154.65:81;
}
```

### Option 2: Use a Development Proxy (Temporary Workaround)
For local development only, you can use Flutter's web proxy or a local proxy server:

1. **Using Flutter's built-in proxy** (if available):
   ```bash
   flutter run -d chrome --web-browser-flag="--disable-web-security"
   ```
   ⚠️ **Warning**: This disables browser security and should only be used for development.

2. **Using a local proxy server** (e.g., with `http-proxy-middleware`):
   Create a simple Node.js proxy server that adds CORS headers.

### Option 3: Use HTTPS (If Possible)
If both your web app and API server use HTTPS, CORS policies are more lenient. However, you still need proper CORS headers.

## Required CORS Headers
The server must include these headers in responses:

```
Access-Control-Allow-Origin: * (or specific domain like http://localhost:8080)
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization, X-Tenant-API-Key
Access-Control-Allow-Credentials: true (if using cookies/auth)
```

## Testing CORS Configuration
You can test if CORS is properly configured using curl:

```bash
curl -H "Origin: http://localhost:8080" \
     -H "Access-Control-Request-Method: GET" \
     -H "Access-Control-Request-Headers: Content-Type,Authorization" \
     -X OPTIONS \
     http://64.227.154.65:81/api/v1/organization/ \
     -v
```

Look for `Access-Control-Allow-Origin` in the response headers.

## Client-Side Changes Made
The Flutter app has been updated to:
1. Detect CORS errors on web platform
2. Provide helpful error messages
3. Log detailed information about CORS requirements

## Next Steps
1. **Contact your backend team** to configure CORS headers on the server
2. **Provide them with**:
   - Your web app's origin (e.g., `http://localhost:8080` for development)
   - Required headers: `Content-Type`, `Authorization`, `X-Tenant-API-Key`
   - Required methods: `GET`, `POST`, `PUT`, `DELETE`, `PATCH`, `OPTIONS`
3. **Test the configuration** using the curl command above
4. **Verify** that the error is resolved when running the app on Chrome

## Additional Notes
- CORS is a browser security feature and cannot be bypassed from the client side
- The error only occurs on web platforms (Chrome, Firefox, Safari, etc.)
- Mobile apps (Android/iOS) are not affected by CORS
- For production, always specify exact origins instead of using `*`

