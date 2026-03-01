require "ruby_llm"
require "zeitwerk"
require "dotenv/load"
require "active_record"
require "sqlite3"
require "sqlite_vec"
require "neighbor"

loader = Zeitwerk::Loader.for_gem
loader.setup

module Friday
  class Error < StandardError; end

  def self.init_db(db_path = "db/friday.sqlite3")
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: db_path
    )
    ActiveRecord::Base.logger = nil
    ActiveRecord::Migration.verbose = false

    # Initialize sqlite-vec
    db = ActiveRecord::Base.connection.raw_connection
    db.enable_load_extension(true)
    SqliteVec.load(db)
    db.enable_load_extension(false)

    Schema.create_tables
  end
end

# Load skills and sub-agents (after module is defined)
Dir.glob(File.join(__dir__, "friday", "skills", "*.rb")).each { |f| require f }
