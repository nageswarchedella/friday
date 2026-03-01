module Friday
  class Schema
    def self.create_tables
      ActiveRecord::Schema.define do
        unless table_exists?(:sessions)
          create_table :sessions do |t|
            t.string :name
            t.string :model
            t.integer :total_tokens, default: 0
            t.timestamps
          end
        end

        unless table_exists?(:messages)
          create_table :messages do |t|
            t.references :session
            t.string :role
            t.text :content
            t.integer :prompt_tokens
            t.integer :completion_tokens
            t.timestamps
          end
        end

        unless table_exists?(:embeddings)
          # We'll use vec0 virtual table for vectors directly as neighbor recommends sqlite-vec
          # but ActiveRecord doesn't support VIRTUAL tables easily in create_table.
          # We'll execute raw SQL for the virtual table.
        end

        # Custom sub-agents defined by the user as data
        unless table_exists?(:sub_agents)
          create_table :sub_agents do |t|
            t.string :name
            t.string :description
            t.text :system_prompt
            t.string :tool_names # Store as a comma-separated list of allowed tool IDs
            t.timestamps
          end
        end

        # Hardware/Software engineers' files RAG metadata
        unless table_exists?(:file_nodes)
          create_table :file_nodes do |t|
            t.string :file_path
            t.string :checksum
            t.text :content
            t.string :file_type
            t.timestamps
          end
        end

        # Create the virtual table for vector search
        # Using 768 dimensions as default for Gemini embeddings (can be changed)
        # sqlite-vec uses vec0
        unless connection.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='vec_embeddings'").any?
          connection.execute("CREATE VIRTUAL TABLE vec_embeddings USING vec0(embedding float[768])")
        end
      end
    end
  end
end
