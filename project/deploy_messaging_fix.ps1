# Deploy Book Club Messaging Fix
# This script helps deploy the messaging fix to Supabase

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Book Club Messaging Fix Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This script will help you fix the Book Club messaging issues." -ForegroundColor Yellow
Write-Host ""
Write-Host "The issues being fixed:" -ForegroundColor Green
Write-Host "1. Missing 'message' column in book_club_messages table" -ForegroundColor White
Write-Host "2. Missing is_user_blocked_flexible function" -ForegroundColor White
Write-Host "3. Incorrect database function parameters" -ForegroundColor White
Write-Host "4. Missing RLS policies for messaging" -ForegroundColor White
Write-Host ""

Write-Host "To apply this fix:" -ForegroundColor Yellow
Write-Host "1. Go to your Supabase Dashboard" -ForegroundColor White
Write-Host "2. Navigate to SQL Editor" -ForegroundColor White
Write-Host "3. Copy the contents of 'fix_book_club_messaging.sql'" -ForegroundColor White
Write-Host "4. Paste and run the SQL script" -ForegroundColor White
Write-Host ""

Write-Host "Reading the fix script..." -ForegroundColor Cyan
$scriptPath = Join-Path $PSScriptRoot "fix_book_club_messaging.sql"

if (Test-Path $scriptPath) {
    $scriptContent = Get-Content $scriptPath -Raw
    Write-Host "✅ Fix script found: $scriptPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Script size: $($scriptContent.Length) characters" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Would you like to:" -ForegroundColor Yellow
    Write-Host "1. Open the fix script in your default editor" -ForegroundColor White
    Write-Host "2. Copy the script content to clipboard" -ForegroundColor White
    Write-Host "3. Display the first 500 characters of the script" -ForegroundColor White
    Write-Host "4. Exit" -ForegroundColor White
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-4)"
    
    switch ($choice) {
        "1" {
            Write-Host "Opening script in default editor..." -ForegroundColor Cyan
            Start-Process $scriptPath
        }
        "2" {
            Write-Host "Copying script to clipboard..." -ForegroundColor Cyan
            $scriptContent | Set-Clipboard
            Write-Host "✅ Script copied to clipboard!" -ForegroundColor Green
        }
        "3" {
            Write-Host "First 500 characters of the script:" -ForegroundColor Cyan
            Write-Host "----------------------------------------" -ForegroundColor Gray
            Write-Host $scriptContent.Substring(0, [Math]::Min(500, $scriptContent.Length)) -ForegroundColor White
            Write-Host "----------------------------------------" -ForegroundColor Gray
        }
        "4" {
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit
        }
        default {
            Write-Host "Invalid choice. Exiting..." -ForegroundColor Red
            exit
        }
    }
} else {
    Write-Host "❌ Fix script not found: $scriptPath" -ForegroundColor Red
    Write-Host "Please ensure the fix_book_club_messaging.sql file exists in the project directory." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "After applying the fix:" -ForegroundColor Yellow
Write-Host "1. Test sending a message in a Book Club" -ForegroundColor White
Write-Host "2. Check the browser console for any remaining errors" -ForegroundColor White
Write-Host "3. Verify that messages are being saved to the database" -ForegroundColor White
Write-Host ""
Write-Host "If you encounter any issues, check the Supabase logs for detailed error messages." -ForegroundColor Gray
