#!/bin/bash
# GitHub Environment Variables Validation Script
# Validates GitHub PAT format and tests API connectivity

set -e

echo "🔍 GitHub Environment Variables Validation"
echo ""

# Function to validate GitHub PAT format
validate_pat_format() {
    local token="$1"
    
    if [ -z "$token" ]; then
        echo "❌ GITHUB_PERSONAL_ACCESS_TOKEN is not set"
        return 1
    fi
    
    # Check if token starts with appropriate prefix
    if [[ "$token" =~ ^ghp_[a-zA-Z0-9]{36}$ ]]; then
        echo "✅ GitHub PAT format is valid (classic token)"
        return 0
    elif [[ "$token" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
        echo "✅ GitHub PAT format is valid (fine-grained token)"  
        return 0
    elif [[ "$token" =~ ^gho_[a-zA-Z0-9]{36}$ ]]; then
        echo "✅ GitHub OAuth token format is valid"
        return 0
    elif [[ "$token" =~ ^ghu_[a-zA-Z0-9]{36}$ ]]; then
        echo "✅ GitHub user-to-server token format is valid"
        return 0
    elif [[ "$token" =~ ^ghs_[a-zA-Z0-9]{36}$ ]]; then
        echo "✅ GitHub server-to-server token format is valid"
        return 0
    else
        echo "⚠️  GitHub PAT format may be invalid or unrecognized"
        echo "   Expected format: ghp_... (36 chars) or github_pat_... (82 chars)"
        echo "   Token length: ${#token} characters"
        return 1
    fi
}

# Function to test GitHub API connectivity
test_github_api() {
    local token="$1"
    local api_url="${GITHUB_API_URL:-https://api.github.com}"
    
    echo "🌐 Testing GitHub API connectivity..."
    echo "   API URL: $api_url"
    
    # Test API connectivity and get user info
    local response
    local http_code
    
    response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "User-Agent: ClaudePod-GitHub-MCP/1.0" \
        "$api_url/user" 2>/dev/null) || {
        echo "❌ Failed to connect to GitHub API"
        echo "   Check your network connection and API URL"
        return 1
    }
    
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | head -n -1)
    
    case "$http_code" in
        200)
            local username=$(echo "$response" | grep -o '"login":"[^"]*' | cut -d'"' -f4)
            local name=$(echo "$response" | grep -o '"name":"[^"]*' | cut -d'"' -f4)
            echo "✅ GitHub API connection successful"
            echo "   Authenticated as: $username${name:+ ($name)}"
            
            # Check token scopes
            check_token_scopes "$token" "$api_url"
            return 0
            ;;
        401)
            echo "❌ GitHub API authentication failed"
            echo "   Token may be invalid or expired"
            return 1
            ;;
        403)
            echo "❌ GitHub API access forbidden"
            echo "   Token may lack required permissions"
            return 1
            ;;
        404)
            echo "❌ GitHub API endpoint not found"
            echo "   Check GITHUB_API_URL setting: $api_url"
            return 1
            ;;
        *)
            echo "❌ GitHub API request failed with HTTP $http_code"
            echo "   Response: $response"
            return 1
            ;;
    esac
}

# Function to check token scopes
check_token_scopes() {
    local token="$1"
    local api_url="$2"
    
    echo ""
    echo "🔐 Checking token scopes..."
    
    # Get token scopes from response headers
    local scopes_header
    scopes_header=$(curl -s -I \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "$api_url/user" 2>/dev/null | grep -i "x-oauth-scopes:" | cut -d: -f2 | tr -d ' \r\n')
    
    if [ -n "$scopes_header" ]; then
        echo "   Current scopes: $scopes_header"
        
        # Check for minimum recommended scopes
        local has_repo=false
        local has_read_packages=false
        
        if echo "$scopes_header" | grep -q "repo"; then
            has_repo=true
        fi
        
        if echo "$scopes_header" | grep -q "read:packages"; then
            has_read_packages=true
        fi
        
        echo ""
        echo "📋 Scope recommendations:"
        if [ "$has_repo" = true ]; then
            echo "   ✅ repo (repository access)"
        else
            echo "   ⚠️  repo (repository access) - RECOMMENDED"
        fi
        
        if [ "$has_read_packages" = true ]; then
            echo "   ✅ read:packages (package access)"
        else
            echo "   ⚠️  read:packages (package access) - RECOMMENDED"
        fi
        
        echo ""
        echo "💡 Additional useful scopes:"
        echo "   - workflow (GitHub Actions)"
        echo "   - read:org (organization access)"
        echo "   - security_events (security analysis)"
    else
        echo "   Could not determine token scopes"
    fi
}

# Function to validate optional environment variables
validate_optional_vars() {
    echo ""
    echo "🔧 Optional environment variables:"
    
    if [ -n "$GITHUB_API_URL" ]; then
        echo "   ✅ GITHUB_API_URL: $GITHUB_API_URL"
        if [[ ! "$GITHUB_API_URL" =~ ^https?:// ]]; then
            echo "   ⚠️  API URL should start with http:// or https://"
        fi
    else
        echo "   ℹ️  GITHUB_API_URL: Using default (https://api.github.com)"
    fi
    
    if [ -n "$GITHUB_TOOLSET" ]; then
        echo "   ✅ GITHUB_TOOLSET: $GITHUB_TOOLSET"
        # Validate toolset names
        local valid_toolsets="context,actions,code_security,dependabot,discussions,issues,pull_requests"
        local invalid_toolsets=""
        
        IFS=',' read -ra TOOLSETS <<< "$GITHUB_TOOLSET"
        for toolset in "${TOOLSETS[@]}"; do
            toolset=$(echo "$toolset" | xargs) # trim whitespace
            if [[ ! "$valid_toolsets" =~ $toolset ]]; then
                invalid_toolsets="$invalid_toolsets $toolset"
            fi
        done
        
        if [ -n "$invalid_toolsets" ]; then
            echo "   ⚠️  Unknown toolsets:$invalid_toolsets"
            echo "   Valid options: $valid_toolsets"
        fi
    else
        echo "   ℹ️  GITHUB_TOOLSET: Using all available toolsets"
    fi
}

# Main validation function
main() {
    echo "════════════════════════════════════════════════════════════════"
    echo "🔐 GitHub Environment Variables Validation"
    echo "════════════════════════════════════════════════════════════════"
    
    local validation_passed=true
    
    # Validate PAT format
    if ! validate_pat_format "$GITHUB_PERSONAL_ACCESS_TOKEN"; then
        validation_passed=false
    fi
    
    # Test API connectivity if PAT format is valid
    if [ -n "$GITHUB_PERSONAL_ACCESS_TOKEN" ]; then
        if ! test_github_api "$GITHUB_PERSONAL_ACCESS_TOKEN"; then
            validation_passed=false
        fi
    fi
    
    # Validate optional variables
    validate_optional_vars
    
    echo ""
    echo "════════════════════════════════════════════════════════════════"
    
    if [ "$validation_passed" = true ]; then
        echo "✅ GitHub environment validation completed successfully!"
        echo ""
        echo "🚀 Your GitHub MCP server should work correctly."
        echo "   Try: claude mcp add github -- /workspace/scripts/install-github-mcp.sh"
        exit 0
    else
        echo "❌ GitHub environment validation failed!"
        echo ""
        echo "💡 Next steps:"
        echo "   1. Set GITHUB_PERSONAL_ACCESS_TOKEN with a valid GitHub PAT"
        echo "   2. Ensure the token has required scopes (repo, read:packages)"
        echo "   3. Re-run this script to validate"
        echo ""
        echo "🔗 Get a GitHub PAT: https://github.com/settings/tokens"
        exit 1
    fi
}

# Execute main function
main