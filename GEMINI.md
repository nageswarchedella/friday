# Friday Project Goals

**Friday** is a lightweight, local-first, and LLM-vendor-agnostic CLI AI assistant designed specifically for software and hardware engineers.

## Core Mandates

### 1. LLM Vendor Agnostic
- **Goal:** Support any LLM provider (Gemini, Anthropic, OpenAI, Groq, Mistral, DeepSeek) and local models (Ollama, LM Studio, vLLM).
- **Strategy:** Use `ruby_llm` as a unified interface and maintain a flexible configuration system.

### 2. Robust RAG System
- **Goal:** Grounded, context-aware answers based on the local codebase.
- **Strategy:** Use **SQLite + `sqlite-vec`** for a high-performance, local vector database. Support multiple file types (Code, Markdown, PDF) with intelligent, section-aware chunking.

### 3. Highly Customizable
- **Goal:** Users should have total control over the agent's behavior and tools.
- **Strategy:** 
    - **Personas as Markdown:** Expert sub-agents are defined in `.md` files with YAML frontmatter. Easy to edit, version-control, and share.
    - **Modular Tools:** A clean Ruby-based tool system that allows the agent to interact with the file system and shell.

### 4. Small Footprint
- **Goal:** Be significantly lighter and faster than alternatives like Claude Code or Gemini CLI.
- **Strategy:** 
    - **Minimal Dependencies:** Avoid heavy frameworks like ActiveRecord or ActiveSupport. 
    - **Pure Ruby + SQLite:** Leverage the efficiency of the Ruby language and the tiny footprint of SQLite.

### 5. Local-First & Transparent
- **Goal:** Keep project-specific data within the project itself.
- **Strategy:** 
    - **`.friday/` Directory:** Store project-specific config, history, RAG index, and local agents.
    - **JSON History:** Conversation logs are stored in transparent, human-readable JSON files for easy auditing and telemetry.

### 6. Dual-Layer Architecture (Global + Local)
- **Goal:** Seamlessly run `friday` in any folder while maintaining global preferences and personas.
- **Strategy:**
    - **Global Root (`~/.friday`):** Store global configurations (API keys), global expert personas, and cross-project history.
    - **Hierarchical Config:** Load order: Defaults < Global Config < Local Project Config < Environment Variables.
    - **Universal Persona Store:** Search for expert sub-agents in both `~/.friday/agents/` and `./.friday/agents/`.

### 7. Engineering-Centric Workflow
- **Goal:** Provide tools that engineers actually need.
- **Strategy:** 
    - **Surgical Patching:** Modify code using precise SEARCH/REPLACE blocks with colored diffs and user confirmation.
    - **Global Execution:** Run `friday` from any subdirectory; it intelligently finds the project root.
    - **Shell Integration:** Run terminal commands (read-only by preference) for testing and inspection.

## Architectural Principles
- **Simplicity over Complexity:** Avoid unnecessary abstractions.
- **Human-Readable Configurations:** Prefer YAML and Markdown for user-facing data.
- **Explicit over Implicit:** Always ask for user confirmation before modifying files or executing shell commands.
