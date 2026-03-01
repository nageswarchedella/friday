# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-03-01

### Added
- **Core Architecture:** Implemented a project-local configuration and data storage system under `.friday/`.
- **Project Instructions:** Added support for `FRIDAY.md` in the project root for automatic project-specific guidance.
- **Persona System:** Added support for Markdown-based sub-agent definitions with YAML frontmatter.
- **Agentic Tools:**
    - `read_file`: Read any file in the project.
    - `create_file`: Create new files with user confirmation.
    - `patch_file`: Surgical Search/Replace patching with colored diffs and user confirmation.
    - `execute_shell`: Run terminal commands with user confirmation.
    - `create_persona`: Allow the AI to generate new expert persona files on the fly.
- **RAG System:** 
    - Integrated `sqlite-vec` for local vector search and file indexing via `/index`.
    - Expanded support for indexing PDF files using `pdf-reader`.
    - Improved context-aware chunking for better search relevance.
- **Streaming:** Implemented real-time response streaming for a responsive UI.
- **REPL Improvements:** 
    - Switched to `Reline` for persistent command history and arrow-key navigation.
    - Added `/sh <command>` for direct shell execution from the REPL.
    - Added multiline input support using the `` trigger.
    - Styled prompt with colors and bold text.
- **Session Management:** JSON-based session persistence with listing and resumption capabilities.
- **Multi-Provider Support:** Verified support for Gemini and local Ollama models (including `minimax-m2.5:cloud` for native tool calling).
- **Graceful Fallback:** Implemented automatic detection and fallback for models that do not support native tool calling.
- **Telemetry:** Tracking token usage and message counts per session.
- **Documentation:** Created comprehensive `README.md` and verification test suite in `test/`.

### Fixed
- Fixed `RubyLLM` initialization errors related to system message placement.
- Fixed `ArgumentError` in tool `param` definitions.
- Resolved `uninitialized constant` errors by correctly nesting modules and requiring dependencies.
- Fixed a bug in `InputHandler` that forced all inputs into multiline mode.
- Optimized `sync_history` to prevent message duplication in JSON logs.
