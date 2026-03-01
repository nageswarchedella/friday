Gem::Specification.new do |spec|
  spec.name          = "friday-cli"
  spec.version       = "0.1.0"
  spec.authors       = ["Nageswar Chedella"]
  spec.email         = ["nageswar.chedella@gmail.com"]

  spec.summary       = "A lightweight, local-first LLM orchestrator for engineers."
  spec.description   = "Friday is a vendor-agnostic AI CLI with RAG, surgical patching, and customizable personas."
  spec.homepage      = "https://github.com/nageswarchedella/friday"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.files = Dir.glob("{bin,lib}/**/*") + %w[README.md CHANGELOG.md Gemfile GEMINI.md]
  spec.bindir = "bin"
  spec.executables = ["friday"]
  spec.require_paths = ["lib"]

  # Runtime Dependencies
  spec.add_dependency "ruby_llm", "~> 1.0"
  spec.add_dependency "sqlite3", "~> 1.4"
  spec.add_dependency "sqlite-vec", "~> 0.1"
  spec.add_dependency "thor", "~> 1.2"
  spec.add_dependency "tty-prompt", "~> 0.23"
  spec.add_dependency "tty-spinner", "~> 0.9"
  spec.add_dependency "tty-markdown", "~> 0.7"
  spec.add_dependency "dotenv", "~> 2.8"
  spec.add_dependency "zeitwerk", "~> 2.6"
  spec.add_dependency "pdf-reader", "~> 2.11"
  spec.add_dependency "diff-lcs", "~> 1.5"
  spec.add_dependency "pastel", "~> 0.8"
  spec.add_dependency "reline", "~> 0.3"
end
