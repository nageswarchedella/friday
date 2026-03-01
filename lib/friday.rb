require "ruby_llm"
require "zeitwerk"
require "dotenv/load"
require "sqlite3"
require "sqlite_vec"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Friday
  class Error < StandardError; end
end
