# Friday

**Friday** is a lightweight, local-first, and LLM-vendor-agnostic CLI application designed for software and hardware engineers. It combines agentic AI capabilities with a robust Retrieval-Augmented Generation (RAG) system, allowing you to interact with your codebase and documentation using both cloud (Gemini) and local (Ollama) models.

## 🚀 Key Features

- **Project-Local Architecture:** Everything is stored in a `.friday/` directory within your project. No hidden global state.
- **Sub-Agents as Markdown:** Personas are defined in simple `.md` files. Commit them to Git to share experts with your team.
- **Surgical Patching:** The agent can modify your code using precise SEARCH/REPLACE blocks. It shows a colored `git-style` diff and requires your confirmation before applying changes.
- **Integrated RAG:** Index your project files into a local `sqlite-vec` database for grounded, context-aware answers.
- **Real-Time Streaming:** Responses appear word-by-word as they are generated, providing a snappy REPL experience.
- **Professional REPL:** Built with `Reline` for persistent command history (Up/Down arrows) and multiline input support (end a line with ``).
- **Vendor Agnostic:** Seamlessly switch between Google Gemini, local Ollama models (Llama, Gemma, DeepSeek, Minimax), and more.
- **Telemetry & Logs:** Transparent JSON session history and a detailed `debug.log` for troubleshooting.

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
3. (Optional) Set your Gemini API Key in a `.env` file:
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
