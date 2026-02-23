# ================================
# Deploy Script
# ================================
# This script:
# 1. Makes sure we are on dev
# 2. Adds & commits changes
# 3. Pushes dev
# 4. Switches to main
# 5. Merges dev into main
# 6. Pushes main
# 7. Switches back to dev
# ================================
# Deploy using following command in VSC terminal: .\deploy.ps1
# If unsuccessfull, run this: Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
# Now try running the deploy script again.
# ===============================

Write-Host "Switching to dev branch..."
git checkout dev

Write-Host "Adding all changes..."
git add .

$commitMessage = Read-Host "Enter commit message"
git commit -m "$commitMessage"

Write-Host "Pushing dev to origin..."
git push origin dev

Write-Host "Switching to main..."
git checkout main

Write-Host "Merging dev into main..."
git merge dev

Write-Host "Pushing main to origin..."
git push origin main

Write-Host "Switching back to dev..."
git checkout dev

Write-Host "Deployment complete!"