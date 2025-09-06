#!/bin/bash

# Cleanup Repository - Remove Old Fix Scripts
# Keep only the essential scripts for maintenance

echo "🧹 Repository Cleanup - Removing Old Fix Scripts"
echo "==============================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}📋 Current scripts in repository:${NC}"
ls -la *.sh

echo -e "\n${YELLOW}🗑️ Removing old fix scripts (keeping essential ones)...${NC}"

# Remove old fix scripts but keep essential ones
scripts_to_remove=(
    "emergency-fix.sh"
    "ultra-simple-fix.sh"
    "diagnose-500-error.sh"
    "fix-413-error.sh"
    "fix-admin-dashboard.sh"
    "fix-backend-api.sh"
    "fix-dashboard-persistence.sh"
    "fix-frontend.sh"
    "fix-missing-data.sh"
    "fix-multer-field.sh"
    "fix-nginx-config.sh"
    "quick-fix-502.sh"
    "quick-update.sh"
    "smart-fix.sh"
)

for script in "${scripts_to_remove[@]}"; do
    if [ -f "$script" ]; then
        echo "Removing: $script"
        rm "$script"
    fi
done

echo -e "\n${GREEN}✅ Cleanup complete!${NC}"
echo -e "\n${YELLOW}📋 Remaining essential scripts:${NC}"
ls -la *.sh | grep -E "(setup|deploy|manage|verify|configure)" || echo "No essential scripts found"

echo -e "\n${YELLOW}📁 Repository structure after cleanup:${NC}"
echo "Essential Scripts:"
echo "  - deploy-frontend-fix.sh (for frontend deployment)"
echo "  - server-frontend-fix.sh (for server-side fixes)"
echo "  - one-click-setup.sh (complete setup)"
echo "  - manage-database.sh (database management)"
echo "  - setup-ssl.sh (SSL setup)"
echo "  - configure-firewall.sh (security)"
echo "  - verify-backend.sh (backend verification)"
echo "  - debug-backend.sh (debugging)"
