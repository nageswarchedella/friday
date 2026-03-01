# Friday

**Friday** is a lightweight, local-first, and LLM-vendor-agnostic CLI application designed for software and hardware engineers. It is built to be **extremely lean**, with a tiny footprint compared to heavier alternatives like Claude Code or Gemini CLI.

## 🚀 Key Features

- **Project-Local Architecture:** Everything is stored in a `.friday/` directory within your project. No hidden global state.
- **Small Footprint:** Minimal dependencies. No heavy ORMs (ActiveRecord) or large utility libraries (ActiveSupport). 
- **Transparent History:** Sessions are stored as simple **JSON files**, making them easy for users to read, audit, and share.
- **Highly Customizable Personas:** Sub-agents are defined as simple **Markdown files** with YAML frontmatter. Highly portable and easy to customize.
- **Surgical Patching:** The agent can modify your code using precise SEARCH/REPLACE blocks with colored `git-style` diffs.
- **Robust RAG System:** Built-in vector search using **SQLite + `sqlite-vec`**. Fast, local, and vendor-agnostic.
- **Vendor Agnostic:** Seamlessly switch between Google Gemini, Anthropic, OpenAI, or local models via Ollama and LM Studio.
- **Real-Time Streaming:** Word-by-word response generation for a snappy REPL experience.

## 🛠 Setup

### Prerequisites
- **Ruby 3.0+**
- **Ollama** (for local models) or a **Gemini API Key**.

### Installation
1. Clone this repository.
2. Install dependencies:
   ```bash
   bundle install
   ```
3. Build and Install globally as a Gem:
   ```bash
   gem build friday-cli.gemspec
   ```
   ```bash
   gem install ./friday-cli-0.1.0.gem
   ```
4. (Optional) Set your Gemini API Key in a `.env` file (or globally in `~/.friday/config.yml`):
   ```bash
   echo "GEMINI_API_KEY=your_key_here" > .env
   ```

## 📖 Usage

### Start a Chat
```bash
./bin/friday start
```

### Resume a Session
```bash
./bin/friday list
./bin/friday start -s <session_id>
```

### In-Chat Commands
- `/index`: Recursively scan and index your project for RAG.
- `/agent <name>`: Switch to a specialized sub-agent (e.g., `/agent HardwareExpert`).
- `/stats`: View token usage and message counts.
- `/help`: Show all available commands.
- `exit` or `/exit`: Save the session and quit.

## 📝 Project-Specific Instructions
Similar to `CLAUDE.md`, you can create a **`FRIDAY.md`** file in your project's root directory. The agent will automatically read this file at the start of every session and follow any custom rules, style guides, or project context you provide there.

## 📂 Project Structure
- `.friday/config.yml`: Project LLM settings.
- `.friday/system.md`: Global system instructions.
- `.friday/agents/`: Your library of expert personas.
- `.friday/history/`: JSON conversation logs.
- `.friday/rag.sqlite3`: Local vector database.

## 🔧 Local Provider Configuration
Friday supports any OpenAI-compatible local server. Here are common configurations for `.friday/config.yml`:

### LM Studio
```yaml
provider: "openai_compatible"
model: "loaded-model-name"
api_base: "http://localhost:1234/v1"
```

### vLLM
```yaml
provider: "openai_compatible"
model: "your-model-name"
api_base: "http://localhost:8000/v1"
```

### Ollama (Default)
```yaml
provider: "ollama"
model: "llama3"
api_base: "http://localhost:11434/v1"
```

## 🌐 Online Provider Configuration
Friday supports the most popular online LLM providers. Simply set your provider and model in `.friday/config.yml` and provide the API key in your `.env` file.

### Supported Providers & Env Vars:
- **Anthropic (Claude):** `provider: "anthropic"`, Env: `ANTHROPIC_API_KEY`
- **OpenAI (GPT):** `provider: "openai"`, Env: `OPENAI_API_KEY`
- **Groq:** `provider: "groq"`, Env: `GROQ_API_KEY`
- **Mistral:** `provider: "mistral"`, Env: `MISTRAL_API_KEY`
- **DeepSeek:** `provider: "deepseek"`, Env: `DEEPSEEK_API_KEY`
- **Google Gemini:** `provider: "gemini"`, Env: `GEMINI_API_KEY`

## 🧪 Testing
The project includes a comprehensive verification suite in the `test/` directory. Run these to ensure your environment is correctly configured:
```bash
ruby test/test_stream.rb
ruby test/test_patching_flow.rb
```

---
**Friday v0.1.0** - Built for engineers who want total control over their AI tools.
