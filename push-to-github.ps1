# Script to push local repository to GitHub
# Run this after creating the repository on GitHub

Write-Host "Pushing Podcast Hosting Service to GitHub..." -ForegroundColor Green

# Add GitHub remote
Write-Host "Adding GitHub remote..." -ForegroundColor Yellow
git remote add origin https://github.com/AktiveX/PodcastHostingService.git

# Push main branch
Write-Host "Pushing main branch..." -ForegroundColor Yellow
git push -u origin main

# Push dev branch
Write-Host "Pushing dev branch..." -ForegroundColor Yellow
git push origin dev

# Push staging branch
Write-Host "Pushing staging branch..." -ForegroundColor Yellow
git push origin staging

Write-Host "Repository successfully pushed to GitHub!" -ForegroundColor Green
Write-Host "Repository URL: https://github.com/AktiveX/PodcastHostingService" -ForegroundColor Cyan

Write-Host "`nNext steps:" -ForegroundColor Magenta
Write-Host "1. Go to https://github.com/AktiveX/PodcastHostingService" -ForegroundColor White
Write-Host "2. Create GitHub Environments (Settings → Environments)" -ForegroundColor White
Write-Host "3. Follow SETUP_INSTRUCTIONS.md for complete setup" -ForegroundColor White
