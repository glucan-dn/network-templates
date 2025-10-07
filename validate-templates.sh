#!/bin/bash

# Template Validation Script
# Validates network device templates against the JSON schema

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🔍 Validating Network Device Templates..."

# Check if we're in the right directory
if [ ! -f "schemas/device-template-schema.json" ]; then
    print_error "Please run this script from the network-templates repository root"
    exit 1
fi

# Check dependencies
missing_deps=""
if ! command -v node >/dev/null 2>&1; then
    missing_deps="$missing_deps node"
fi

if ! command -v yaml-lint >/dev/null 2>&1; then
    missing_deps="$missing_deps yaml-lint"
fi

if ! command -v ajv >/dev/null 2>&1; then
    missing_deps="$missing_deps ajv-cli"
fi

if [ -n "$missing_deps" ]; then
    print_error "Missing dependencies:$missing_deps"
    echo "Install with: npm install -g ajv-cli yaml-lint"
    exit 1
fi

# Find all template files
template_files=$(find templates/ -name "*.yaml" -o -name "*.yml" 2>/dev/null || true)

if [ -z "$template_files" ]; then
    print_warning "No template files found in templates/ directory"
    exit 0
fi

total_files=0
valid_files=0
invalid_files=0

echo ""
print_info "Found template files:"
for file in $template_files; do
    echo "  - $file"
    ((total_files++))
done

echo ""
print_info "Starting validation..."

# Validate each template file
for file in $template_files; do
    echo ""
    echo "🔍 Validating $file..."
    
    file_valid=true
    
    # YAML syntax validation
    if yaml-lint "$file" >/dev/null 2>&1; then
        print_success "YAML syntax valid"
    else
        print_error "YAML syntax invalid"
        yaml-lint "$file"
        file_valid=false
    fi
    
    # JSON Schema validation
    if [ "$file_valid" = true ]; then
        # Convert YAML to JSON for schema validation
        temp_json=$(mktemp)
        if node -e "
            const yaml = require('js-yaml');
            const fs = require('fs');
            try {
                const doc = yaml.load(fs.readFileSync('$file', 'utf8'));
                console.log(JSON.stringify(doc, null, 2));
            } catch (e) {
                process.exit(1);
            }
        " > "$temp_json" 2>/dev/null; then
            
            if ajv validate -s schemas/device-template-schema.json -d "$temp_json" >/dev/null 2>&1; then
                print_success "Schema validation passed"
            else
                print_error "Schema validation failed"
                ajv validate -s schemas/device-template-schema.json -d "$temp_json"
                file_valid=false
            fi
        else
            print_error "Failed to convert YAML to JSON"
            file_valid=false
        fi
        
        rm -f "$temp_json"
    fi
    
    # Template-specific validations
    if [ "$file_valid" = true ]; then
        # Check naming convention
        filename=$(basename "$file")
        if [[ $filename =~ ^[a-z]+-[a-z]+-v[0-9]+\.[0-9]+\.ya?ml$ ]]; then
            print_success "Naming convention valid"
        else
            print_warning "Naming convention doesn't match recommended pattern: {device-type}-{environment}-v{version}.yaml"
        fi
        
        # Check required metadata labels
        device_type=$(node -e "
            const yaml = require('js-yaml');
            const fs = require('fs');
            try {
                const doc = yaml.load(fs.readFileSync('$file', 'utf8'));
                console.log(doc.metadata?.labels?.['device-type'] || 'missing');
            } catch (e) {
                console.log('error');
            }
        " 2>/dev/null)
        
        if [ "$device_type" != "missing" ] && [ "$device_type" != "error" ]; then
            print_success "Device type label found: $device_type"
        else
            print_warning "Device type label missing or invalid"
        fi
    fi
    
    if [ "$file_valid" = true ]; then
        print_success "$file is valid ✨"
        ((valid_files++))
    else
        print_error "$file has validation errors"
        ((invalid_files++))
    fi
done

echo ""
echo "📊 Validation Summary:"
echo "  Total files: $total_files"
echo "  Valid files: $valid_files"
echo "  Invalid files: $invalid_files"

if [ $invalid_files -eq 0 ]; then
    echo ""
    print_success "All templates are valid! 🎉"
    exit 0
else
    echo ""
    print_error "$invalid_files template(s) have validation errors"
    exit 1
fi
