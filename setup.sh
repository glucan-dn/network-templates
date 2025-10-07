#!/bin/bash

# Network Templates Repository Setup Script
# This script helps set up the repository for GitHub Actions integration

set -e

echo "🔧 Setting up Network Templates Repository..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -d "templates" ]; then
    print_error "Please run this script from the network-templates repository root"
    exit 1
fi

print_section "Repository Validation"

# Check directory structure
required_dirs=("templates" "schemas" "examples" ".github/workflows")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Directory '$dir' exists"
    else
        print_error "Directory '$dir' missing"
        exit 1
    fi
done

# Check required files
required_files=(
    "templates/router-production-v1.yaml"
    "templates/switch-production-v1.yaml"
    "schemas/device-template-schema.json"
    ".github/workflows/template-update-trigger.yml"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "File '$file' exists"
    else
        print_error "File '$file' missing"
        exit 1
    fi
done

print_section "GitHub Repository Setup"

# Check if this is a git repository
if [ ! -d ".git" ]; then
    print_warning "Not a git repository. Initializing..."
    git init
    print_success "Git repository initialized"
else
    print_success "Git repository detected"
fi

# Check for GitHub remote
if git remote get-url origin >/dev/null 2>&1; then
    REPO_URL=$(git remote get-url origin)
    print_success "GitHub remote configured: $REPO_URL"
else
    print_warning "No GitHub remote configured"
    echo "To add GitHub remote:"
    echo "  git remote add origin https://github.com/YOUR_USERNAME/network-templates.git"
fi

print_section "Dependencies Check"

# Check for required tools
tools=("node" "npm" "curl" "jq")
for tool in "${tools[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
        print_success "$tool is installed"
    else
        print_error "$tool is not installed"
        echo "Please install $tool to use validation features"
    fi
done

# Install validation dependencies if node/npm available
if command -v npm >/dev/null 2>&1; then
    print_section "Installing Validation Dependencies"
    
    # Install global packages for validation
    npm install -g ajv-cli yaml-lint js-yaml 2>/dev/null || {
        print_warning "Could not install global packages. You may need sudo or different npm setup"
        echo "Try: sudo npm install -g ajv-cli yaml-lint js-yaml"
    }
fi

print_section "GitHub Actions Configuration"

echo "To enable GitHub Actions workflow, configure these repository secrets:"
echo ""
echo "1. Go to your GitHub repository"
echo "2. Settings → Secrets and variables → Actions"
echo "3. Add the following secrets:"
echo ""
echo "   🔐 DEPLOYMENT_API_URL"
echo "      Example: http://rollout-controller.default.svc.cluster.local/api/v1/templates/updated"
echo ""
echo "   🔐 DEPLOYMENT_API_TOKEN"
echo "      Generate with: openssl rand -hex 32"
echo ""

print_section "Testing"

echo "To test the setup locally:"
echo ""
echo "1. Validate templates:"
echo "   ./validate-templates.sh"
echo ""
echo "2. Test template changes:"
echo "   # Make a change to any template"
echo "   echo '# Test change' >> templates/router-production-v1.yaml"
echo "   git add templates/router-production-v1.yaml"
echo "   git commit -m 'Test: Update router template'"
echo "   git push origin main"
echo ""
echo "3. Check GitHub Actions tab for workflow execution"
echo ""

print_section "Next Steps"

echo "Your network-templates repository is ready! 🎉"
echo ""
echo "1. ✅ Repository structure validated"
echo "2. ✅ GitHub Actions workflow configured" 
echo "3. ⏳ Configure GitHub secrets (DEPLOYMENT_API_URL, DEPLOYMENT_API_TOKEN)"
echo "4. ⏳ Set up deployment system API endpoint"
echo "5. ⏳ Test the complete workflow"
echo ""
echo "For more details, see .github/workflows/README.md"

print_success "Setup complete!"
