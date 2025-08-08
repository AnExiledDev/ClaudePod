# Claude Code Available Tools

## Optimized Configuration

This ClaudePod container comes with an **optimized tool configuration** that:
- **Pre-allows 79 essential tools** (51% reduction from 161 total available)
- **Eliminates permission prompts** for common workflows  
- **Prioritizes intelligent MCP tools** over basic built-ins
- **Reduces decision fatigue** while maintaining full development capabilities

**See [.claude/settings.json](.claude/settings.json) for the complete configuration.**

---

## Built-in Tools

### Task Management
- **Task** - Launch specialized agents for complex, multi-step tasks with specific expertise
- **TodoWrite** - Create and manage structured task lists for coding sessions

### File Operations
- **Read** - Read files from the local filesystem (supports images, PDFs, Jupyter notebooks)
- **Write** - Write files to the local filesystem
- **Edit** - Perform exact string replacements in files
- **MultiEdit** - Make multiple edits to a single file in one operation
- **NotebookEdit** - Edit Jupyter notebook cells with replace/insert/delete operations

### File Search & Navigation
- **Glob** - Fast file pattern matching with glob patterns (e.g., "**/*.js")
- **Grep** - Powerful text search using ripgrep with regex support
- **LS** - List files and directories in a given path

### System Operations
- **Bash** - Execute bash commands in a persistent shell session
- **ExitPlanMode** - Exit plan mode after presenting implementation plans

### Web Operations
- **WebFetch** - Fetch and process content from URLs with AI analysis
- **WebSearch** - Search the web for real-time information

### MCP Resources
- **ListMcpResourcesTool** - List available resources from configured MCP servers
- **ReadMcpResourceTool** - Read specific resources from MCP servers by URI

## MCP Server Tools

### Serena (Code Analysis & Semantic Search)
- **mcp__serena__list_dir** - List non-gitignored files and directories with recursion
- **mcp__serena__find_file** - Find files matching patterns using wildcards
- **mcp__serena__replace_regex** - Replace content using Python-style regular expressions with wildcards
- **mcp__serena__search_for_pattern** - Flexible pattern search in codebase with file filtering
- **mcp__serena__restart_language_server** - Restart language server if it hangs
- **mcp__serena__get_symbols_overview** - Get high-level overview of code symbols in files/directories
- **mcp__serena__find_symbol** - Find symbols by name path with optional body inclusion
- **mcp__serena__find_referencing_symbols** - Find all references to a specific symbol
- **mcp__serena__replace_symbol_body** - Replace the body of a symbol by name path
- **mcp__serena__insert_after_symbol** - Insert content after a symbol definition
- **mcp__serena__insert_before_symbol** - Insert content before a symbol definition
- **mcp__serena__write_memory** - Write project information to memory files
- **mcp__serena__read_memory** - Read content from memory files
- **mcp__serena__list_memories** - List available memory files
- **mcp__serena__delete_memory** - Delete memory files
- **mcp__serena__check_onboarding_performed** - Check if project onboarding was completed
- **mcp__serena__onboarding** - Perform initial project onboarding
- **mcp__serena__think_about_collected_information** - Analyze collected information for task completion
- **mcp__serena__think_about_task_adherence** - Verify task alignment before code changes
- **mcp__serena__think_about_whether_you_are_done** - Evaluate task completion status

### Tavily Search (Web Search & Content)
- **mcp__tavily-search__tavily_search** - Search the web for real-time information with filtering options
- **mcp__tavily-search__tavily_extract** - Extract content from specific web pages in markdown/text format
- **mcp__tavily-search__tavily_crawl** - Crawl multiple pages from a website starting from base URL
- **mcp__tavily-search__tavily_map** - Map and discover website structure by finding all URLs

### DeepWiki (Documentation & Knowledge)
- **mcp__deepwiki__read_wiki_structure** - Get documentation topics for GitHub repositories
- **mcp__deepwiki__read_wiki_contents** - View documentation about GitHub repositories
- **mcp__deepwiki__ask_question** - Ask questions about GitHub repositories

### GitHub MCP Server
- **mcp__github__add_comment_to_pending_review** - Add review comments to pending pull request reviews
- **mcp__github__add_issue_comment** - Add comments to GitHub issues
- **mcp__github__add_sub_issue** - Add sub-issues to parent issues
- **mcp__github__assign_copilot_to_issue** - Assign GitHub Copilot to resolve issues
- **mcp__github__cancel_workflow_run** - Cancel GitHub Actions workflow runs
- **mcp__github__create_and_submit_pull_request_review** - Create and submit PR reviews without comments
- **mcp__github__create_branch** - Create new branches in repositories
- **mcp__github__create_gist** - Create new GitHub gists
- **mcp__github__create_issue** - Create new issues in repositories
- **mcp__github__create_or_update_file** - Create or update single files in repositories
- **mcp__github__create_pending_pull_request_review** - Create pending PR reviews for later submission
- **mcp__github__create_pull_request** - Create new pull requests
- **mcp__github__create_repository** - Create new GitHub repositories
- **mcp__github__delete_file** - Delete files from repositories
- **mcp__github__delete_pending_pull_request_review** - Delete pending PR reviews
- **mcp__github__delete_workflow_run_logs** - Delete workflow run logs
- **mcp__github__dismiss_notification** - Mark GitHub notifications as read/done
- **mcp__github__download_workflow_run_artifact** - Get download URLs for workflow artifacts
- **mcp__github__fork_repository** - Fork repositories to your account or organization
- **mcp__github__get_code_scanning_alert** - Get details of code scanning alerts
- **mcp__github__get_commit** - Get commit details from repositories
- **mcp__github__get_dependabot_alert** - Get details of Dependabot alerts
- **mcp__github__get_discussion** - Get specific discussions by ID
- **mcp__github__get_discussion_comments** - Get comments from discussions
- **mcp__github__get_file_contents** - Get contents of files or directories from repositories
- **mcp__github__get_issue** - Get details of specific issues
- **mcp__github__get_issue_comments** - Get comments for specific issues
- **mcp__github__get_job_logs** - Download logs for workflow jobs or all failed jobs
- **mcp__github__get_me** - Get details of authenticated GitHub user
- **mcp__github__get_notification_details** - Get detailed information about notifications
- **mcp__github__get_pull_request** - Get details of specific pull requests
- **mcp__github__get_pull_request_comments** - Get comments for pull requests
- **mcp__github__get_pull_request_diff** - Get diff of pull requests
- **mcp__github__get_pull_request_files** - Get files changed in pull requests
- **mcp__github__get_pull_request_reviews** - Get reviews for pull requests
- **mcp__github__get_pull_request_status** - Get status of pull requests
- **mcp__github__get_secret_scanning_alert** - Get details of secret scanning alerts
- **mcp__github__get_tag** - Get details about git tags
- **mcp__github__get_workflow_run** - Get details of workflow runs
- **mcp__github__get_workflow_run_logs** - Download complete workflow run logs (expensive)
- **mcp__github__get_workflow_run_usage** - Get usage metrics for workflow runs
- **mcp__github__list_branches** - List branches in repositories
- **mcp__github__list_code_scanning_alerts** - List code scanning alerts in repositories
- **mcp__github__list_commits** - Get commits from branches with pagination
- **mcp__github__list_dependabot_alerts** - List Dependabot alerts in repositories
- **mcp__github__list_discussion_categories** - List discussion categories for repositories
- **mcp__github__list_discussions** - List discussions for repositories or organizations
- **mcp__github__list_gists** - List gists for users
- **mcp__github__list_issues** - List issues in repositories with filtering
- **mcp__github__list_notifications** - List all GitHub notifications for authenticated user
- **mcp__github__list_pull_requests** - List pull requests in repositories
- **mcp__github__list_secret_scanning_alerts** - List secret scanning alerts
- **mcp__github__list_sub_issues** - List sub-issues for specific issues
- **mcp__github__list_tags** - List git tags in repositories
- **mcp__github__list_workflow_jobs** - List jobs for workflow runs
- **mcp__github__list_workflow_run_artifacts** - List artifacts for workflow runs
- **mcp__github__list_workflow_runs** - List workflow runs for workflows
- **mcp__github__list_workflows** - List workflows in repositories
- **mcp__github__manage_notification_subscription** - Manage notification subscriptions (ignore/watch/delete)
- **mcp__github__manage_repository_notification_subscription** - Manage repository notification subscriptions
- **mcp__github__mark_all_notifications_read** - Mark all notifications as read
- **mcp__github__merge_pull_request** - Merge pull requests with different strategies
- **mcp__github__push_files** - Push multiple files in a single commit
- **mcp__github__remove_sub_issue** - Remove sub-issues from parent issues
- **mcp__github__reprioritize_sub_issue** - Change sub-issue priority order
- **mcp__github__request_copilot_review** - Request GitHub Copilot code reviews for PRs
- **mcp__github__rerun_failed_jobs** - Re-run only failed jobs in workflow runs
- **mcp__github__rerun_workflow_run** - Re-run entire workflow runs
- **mcp__github__run_workflow** - Run GitHub Actions workflows by ID or filename
- **mcp__github__search_code** - Search code across all GitHub repositories
- **mcp__github__search_issues** - Search for issues using GitHub search syntax
- **mcp__github__search_orgs** - Find GitHub organizations by name/location/metadata
- **mcp__github__search_pull_requests** - Search for pull requests using GitHub search syntax
- **mcp__github__search_repositories** - Find repositories by name/description/topics
- **mcp__github__search_users** - Find GitHub users by username/profile information
- **mcp__github__submit_pending_pull_request_review** - Submit pending PR reviews
- **mcp__github__update_gist** - Update existing gists
- **mcp__github__update_issue** - Update existing issues
- **mcp__github__update_pull_request** - Update existing pull requests
- **mcp__github__update_pull_request_branch** - Update PR branches with latest base changes

### TaskMaster AI (Task Management & Project Execution)
- **mcp__taskmaster-ai__initialize_project** - Initialize TaskMaster project structure
- **mcp__taskmaster-ai__models** - Get/set AI model configurations and API key status
- **mcp__taskmaster-ai__rules** - Add or remove rule profiles from projects
- **mcp__taskmaster-ai__parse_prd** - Parse Product Requirements Documents to generate tasks
- **mcp__taskmaster-ai__analyze_project_complexity** - Analyze task complexity and generate expansion recommendations
- **mcp__taskmaster-ai__expand_task** - Expand tasks into subtasks for detailed implementation
- **mcp__taskmaster-ai__expand_all** - Expand all pending tasks into subtasks based on complexity
- **mcp__taskmaster-ai__scope_up_task** - Increase task complexity using AI
- **mcp__taskmaster-ai__scope_down_task** - Decrease task complexity using AI
- **mcp__taskmaster-ai__get_tasks** - Get all tasks with optional filtering by status
- **mcp__taskmaster-ai__get_task** - Get detailed information about specific tasks
- **mcp__taskmaster-ai__next_task** - Find next task to work on based on dependencies
- **mcp__taskmaster-ai__complexity_report** - Display complexity analysis report
- **mcp__taskmaster-ai__set_task_status** - Set status of tasks or subtasks
- **mcp__taskmaster-ai__generate** - Generate individual task files from tasks.json
- **mcp__taskmaster-ai__add_task** - Add new tasks using AI assistance
- **mcp__taskmaster-ai__add_subtask** - Add subtasks to existing tasks
- **mcp__taskmaster-ai__update** - Update multiple upcoming tasks based on new context
- **mcp__taskmaster-ai__update_task** - Update single tasks with new information
- **mcp__taskmaster-ai__update_subtask** - Append timestamped information to subtasks
- **mcp__taskmaster-ai__remove_task** - Remove tasks or subtasks permanently
- **mcp__taskmaster-ai__remove_subtask** - Remove subtasks from parent tasks
- **mcp__taskmaster-ai__clear_subtasks** - Clear subtasks from specified tasks
- **mcp__taskmaster-ai__move_task** - Move tasks or subtasks to new positions
- **mcp__taskmaster-ai__add_dependency** - Add dependency relationships between tasks
- **mcp__taskmaster-ai__remove_dependency** - Remove dependencies from tasks
- **mcp__taskmaster-ai__validate_dependencies** - Check for dependency issues without changes
- **mcp__taskmaster-ai__fix_dependencies** - Fix invalid dependencies automatically
- **mcp__taskmaster-ai__response-language** - Get or set response language for projects
- **mcp__taskmaster-ai__list_tags** - List all available tags with task counts
- **mcp__taskmaster-ai__add_tag** - Create new tags for organizing tasks
- **mcp__taskmaster-ai__delete_tag** - Delete existing tags and all their tasks
- **mcp__taskmaster-ai__use_tag** - Switch to different tag context for operations
- **mcp__taskmaster-ai__rename_tag** - Rename existing tags
- **mcp__taskmaster-ai__copy_tag** - Copy existing tags to create new ones
- **mcp__taskmaster-ai__research** - Perform AI-powered research queries with project context

### IDE Integration
- **mcp__ide__getDiagnostics** - Get language diagnostics from VS Code
- **mcp__ide__executeCode** - Execute Python code in Jupyter kernel

## Tool Categories

### Code Analysis & Navigation
- Serena tools for semantic code analysis
- Built-in Grep, Glob for text/file search
- GitHub code search capabilities

### File Operations
- Built-in Read, Write, Edit, MultiEdit
- Serena regex replacement and symbol editing
- GitHub file creation/update/deletion

### Task & Project Management
- Built-in TodoWrite for session tasks
- TaskMaster AI for comprehensive project management
- Task expansion, complexity analysis, dependency management

### Web & Research
- Built-in WebFetch and WebSearch
- Tavily tools for advanced web crawling/extraction
- TaskMaster research capabilities

### GitHub Integration
- Comprehensive GitHub API coverage
- Repository, issue, PR, workflow management
- Notifications, reviews, security alerts

### Development Workflow
- Built-in Bash for system commands
- IDE integration for diagnostics and code execution
- Memory management for project context

## Summary

**Built-in Tools: 13**
**MCP Server Tools: 148**
- Serena (20 tools) - Code analysis and semantic search
- Tavily Search (4 tools) - Web search and content extraction  
- DeepWiki (3 tools) - Documentation and knowledge
- GitHub (80 tools) - Complete GitHub API integration
- TaskMaster AI (39 tools) - AI-powered project management
- IDE Integration (2 tools) - VS Code diagnostics and Jupyter execution

**Total: 161 tools available**
**Optimized Configuration: 79 tools pre-allowed (51% reduction)**