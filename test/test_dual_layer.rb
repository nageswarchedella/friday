require_relative "../lib/friday"
require_relative "../lib/friday/agent"
require_relative "../lib/friday/cli"
require "minitest/autorun"
require "fileutils"

class TestDualLayer < Minitest::Test
  def setup
    @tmp_dir = File.expand_path("../tmp", __dir__)
    @tmp_home = File.join(@tmp_dir, "global_home")
    @tmp_project_root = File.join(@tmp_dir, "local_project", ".friday")
    
    FileUtils.mkdir_p(File.join(@tmp_home, "agents"))
    FileUtils.mkdir_p(File.join(@tmp_project_root, "agents"))
    
    # Robust Mocking
    local_home = @tmp_home
    local_project = @tmp_project_root
    
    Friday::Project.singleton_class.class_eval do
      alias_method :orig_global_root, :global_root rescue nil
      alias_method :orig_root, :root rescue nil
      alias_method :orig_find_root, :find_root rescue nil
      
      define_method(:global_root) { local_home }
      define_method(:root) { local_project }
      define_method(:find_root) { local_project }
    end
  end

  def teardown
    Friday::Project.singleton_class.class_eval do
      alias_method :global_root, :orig_global_root if method_defined?(:orig_global_root)
      alias_method :root, :orig_root if method_defined?(:orig_root)
      alias_method :find_root, :orig_find_root if method_defined?(:orig_find_root)
    end
    FileUtils.rm_rf(@tmp_dir)
  end

  def test_global_setup_creates_dir
    Friday::Project.setup_global
    assert Dir.exist?(@tmp_home)
    assert File.exist?(File.join(@tmp_home, "config.yml"))
  end

  def test_config_hierarchical_merge
    # Temporarily hide environment variables for this test
    original_gemini = ENV["GEMINI_API_KEY"]
    original_openai = ENV["OPENAI_API_KEY"]
    original_anthropic = ENV["ANTHROPIC_API_KEY"]
    ENV["GEMINI_API_KEY"] = nil
    ENV["OPENAI_API_KEY"] = nil
    ENV["ANTHROPIC_API_KEY"] = nil

    # 1. Global Config
    Friday::Project.setup_global
    global_config = { "provider" => "global_provider", "api_key" => "global_key" }
    File.write(File.join(@tmp_home, "config.yml"), global_config.to_yaml)
    
    # 2. Local Config (overwrites global)
    local_config = { "provider" => "local_provider" }
    File.write(File.join(@tmp_project_root, "config.yml"), local_config.to_yaml)
    
    # 3. Load
    config = Friday::Config.load
    assert_equal "local_provider", config["provider"]
    assert_equal "global_key", config["api_key"]
    assert_equal "gemini-2.5-flash", config["model"] # From defaults

  ensure
    # Restore environment variables
    ENV["GEMINI_API_KEY"] = original_gemini
    ENV["OPENAI_API_KEY"] = original_openai
    ENV["ANTHROPIC_API_KEY"] = original_anthropic
  end

  def test_universal_persona_store
    # 1. Create a global persona
    File.write(File.join(@tmp_home, "agents", "global_expert.md"), "---\nname: GlobalExpert\ndescription: Global\n---\nGlobal Expert instructions")
    
    # 2. Create a local persona
    File.write(File.join(@tmp_project_root, "agents", "local_expert.md"), "---\nname: LocalExpert\ndescription: Local\n---\nLocal Expert instructions")
    
    # 3. Create a persona in both (Local should win)
    File.write(File.join(@tmp_home, "agents", "conflict.md"), "---\nname: Conflict\ndescription: I am Global\n---\nGlobal")
    File.write(File.join(@tmp_project_root, "agents", "conflict.md"), "---\nname: Conflict\ndescription: I am Local\n---\nLocal")

    personas = Friday::PersonaStore.all
    names = personas.map(&:name).map(&:downcase)
    
    assert_includes names, "globalexpert"
    assert_includes names, "localexpert"
    assert_includes names, "conflict"
    
    conflict = personas.find { |p| p.name == "Conflict" }
    assert_equal "I am Local", conflict.frontmatter["description"]
  end

  def test_cli_prompts_for_initialization
    # Mock find_root to return nil
    local_project = @tmp_project_root
    Friday::Project.singleton_class.class_eval do
      define_method(:find_root) { nil }
    end
    
    prompt_mock = Object.new
    def prompt_mock.yes?(msg); true; end
    TTY::Prompt.define_singleton_method(:new) { prompt_mock }
    
    setup_called = false
    Friday::Project.define_singleton_method(:setup) { |dir| setup_called = true }
    
    capture_io do
      cli = Friday::Cli.new
      cli.start rescue nil
    end
    
    assert setup_called
  end
end
