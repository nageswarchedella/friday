module Friday
  module Skills
    class HardwareExpert < Skill
      def initialize
        super(
          name: "HardwareExpert",
          description: "Expert in Verilog, FPGA, and hardware architecture optimization.",
          tools: [Tools::VerilogCheck, Tools::OptimizeLogic],
          system_prompt: "You are an expert hardware engineer. When analyzing code, focus on synthesis efficiency, clock domains, and timing constraints."
        )
      end
    end
  end

  module Tools
    class VerilogCheck < RubyLLM::Tool
      description "Checks Verilog code for common synthesis issues."
      param :file_path

      def execute(file_path:)
        content = File.read(file_path)
        if content.include?("always @(*)")
          "Found combinatorial logic. Consider if flip-flops are needed for timing."
        else
          "No immediate issues found in #{file_path}."
        end
      rescue => e
        "Error checking Verilog: #{e.message}"
      end
    end

    class OptimizeLogic < RubyLLM::Tool
      description "Suggests optimizations for hardware logic gates or state machines."
      param :logic_description

      def execute(logic_description:)
        "Optimization suggestion for: #{logic_description}. Consider using binary encoding for state machines with fewer states to save area."
      end
    end
  end
end

Friday::Skill::Registry.register(Friday::Skills::HardwareExpert)
