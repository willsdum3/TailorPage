# Deploy Tailor Mates Database Schema and Functions
# This script will help you deploy the Tailor Mates functionality to your Supabase database

Write-Host "Deploying Tailor Mates Database Schema and Functions..." -ForegroundColor Green

# Check if .env file exists
if (-not (Test-Path "project\.env")) {
    Write-Host "Error: .env file not found in project directory!" -ForegroundColor Red
    Write-Host "Please create a .env file with your Supabase credentials:" -ForegroundColor Yellow
    Write-Host "VITE_SUPABASE_URL=your_supabase_url" -ForegroundColor Cyan
    Write-Host "VITE_SUPABASE_ANON_KEY=your_supabase_anon_key" -ForegroundColor Cyan
    Write-Host "VITE_SUPABASE_SERVICE_KEY=your_supabase_service_key" -ForegroundColor Cyan
    exit 1
}

# Load environment variables
Get-Content "project\.env" | ForEach-Object {
    if ($_ -match "^([^=]+)=(.*)$") {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
    }
}

$SUPABASE_URL = [Environment]::GetEnvironmentVariable("VITE_SUPABASE_URL")
$SUPABASE_SERVICE_KEY = [Environment]::GetEnvironmentVariable("VITE_SUPABASE_SERVICE_KEY")

if (-not $SUPABASE_URL -or -not $SUPABASE_SERVICE_KEY) {
    Write-Host "Error: Missing Supabase credentials in .env file!" -ForegroundColor Red
    exit 1
}

Write-Host "Supabase URL: $SUPABASE_URL" -ForegroundColor Cyan

# Function to execute SQL via Supabase REST API
function Invoke-SupabaseSQL {
    param(
        [string]$SQL,
        [string]$Description
    )
    
    Write-Host "Executing: $Description" -ForegroundColor Yellow
    
    $headers = @{
        "Content-Type" = "application/json"
        "Authorization" = "Bearer $SUPABASE_SERVICE_KEY"
        "apikey" = $SUPABASE_SERVICE_KEY
    }
    
    $body = @{
        query = $SQL
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "$SUPABASE_URL/rest/v1/rpc/exec_sql" -Method POST -Headers $headers -Body $body
        Write-Host "✓ $Description completed successfully" -ForegroundColor Green
        return $response
    }
    catch {
        Write-Host "✗ Error executing $Description" -ForegroundColor Red
        Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Read SQL files
$schemaSQL = Get-Content "tailor_mates_schema.sql" -Raw
$functionsSQL = Get-Content "tailor_mates_functions.sql" -Raw

# Deploy schema
Write-Host "`nDeploying Tailor Mates Schema..." -ForegroundColor Green
$schemaResult = Invoke-SupabaseSQL -SQL $schemaSQL -Description "Tailor Mates Schema"

# Deploy functions
Write-Host "`nDeploying Tailor Mates Functions..." -ForegroundColor Green
$functionsResult = Invoke-SupabaseSQL -SQL $functionsSQL -Description "Tailor Mates Functions"

if ($schemaResult -and $functionsResult) {
    Write-Host "`n✓ Tailor Mates deployment completed successfully!" -ForegroundColor Green
    Write-Host "You can now create book clubs and use the Tailor Mates features." -ForegroundColor Cyan
} else {
    Write-Host "`n✗ Tailor Mates deployment failed!" -ForegroundColor Red
    Write-Host "Please check the error messages above and try again." -ForegroundColor Yellow
}

Write-Host "`nNote: If you encounter issues, you can also deploy manually through the Supabase dashboard:" -ForegroundColor Yellow
Write-Host "1. Go to your Supabase project dashboard" -ForegroundColor Cyan
Write-Host "2. Navigate to SQL Editor" -ForegroundColor Cyan
Write-Host "3. Copy and paste the contents of tailor_mates_schema.sql" -ForegroundColor Cyan
Write-Host "4. Execute the SQL" -ForegroundColor Cyan
Write-Host "5. Repeat for tailor_mates_functions.sql" -ForegroundColor Cyan
