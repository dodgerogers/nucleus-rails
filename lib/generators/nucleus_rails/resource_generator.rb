require "rails/generators"

# rm -rf app/models/ app/repositories/ app/operations/ app/view_models/ app/policies/ app/controllers/
# git checkout .

# rubocop:disable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize
module NucleusRails
  class ResourceGenerator < Rails::Generators::Base
    # rails g nucleus_rails:resource
    # rails g nucleus_rails:resource --tables "posts", "comments", "users"
    class_option(
      :tables,
      type: :array,
      default: [],
      required: false,
      banner: '"users", "posts", "comments',
      desc: "Table names to generate endpoints for. Runs for all tables when no specified."
    )

    desc "Creates REST endpoints for the given database tables"
    def create_rest_endpoints_from_database_tables
      tables = options.tables || []

      fetch_table_names(tables).each do |resource|
        generate_files_for(resource)
      end
    end

    private

    def fetch_table_names(table_names=[])
      tables = ActiveRecord::Base.connection.tables.to_set(&:downcase)
      tables = tables.intersection(table_names) if table_names.any?
      tables = tables.subtract(%w[schema_migrations ar_internal_metadata])

      tables.to_a
    end

    def generate_files_for(name)
      refs = entity_details(name)

      class_defined = begin
        Object.const_defined?(refs.class_name)
      rescue StandardError
        false
      end
      raise ArgumentError, "`#{refs.class_name}` is already defined for table #{name}" if class_defined

      create_models(refs)
      create_repository(refs)
      create_operations(refs)
      create_view(refs)
      create_policy(refs)
      create_controller(refs)
      update_routes(refs)
    end

    def create_models(refs)
      content = <<~RUBY
        class #{refs.class_name} < ActiveRecord::Base
          self.table_name = "#{refs.table_name}"

          # Relationships
          #################################
          # TODO: get foreign keys to define relationships, and nested_attributes here

          # Validations
          #################################
          # TODO: mirror unique index validations
        end
      RUBY

      create_file("app/models/#{refs.file_name}.rb", content)
    end

    def create_repository(refs)
      content = <<~RUBY
        class #{refs.class_name}Repository < NucleusCore::Repository
          def find!(id)
            #{refs.class_nagime}.find(id)
          rescue ActiveRecord::RecordNotFound => e
            raise NucleusCore::RecordNotFound.new(message: e.message)
          end

          def search(attrs = {})
            attrs = attrs.with_indifferent_access.slice(*#{refs.columns.to_a})

            #{refs.class_name}.where(attrs)
          end

          def create!(attrs = {})
            attrs = attrs.with_indifferent_access.slice(*#{refs.columns.delete(:id).to_a})

            #{refs.class_name}.create!(attrs)
          rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
            raise NucleusCore::RecordNotSaved.new(message: e.message)
          end

          def update!(id, attrs = {})
            attrs = attrs.with_indifferent_access.slice(*#{refs.columns.delete(:id).to_a})
            #{refs.class_name}.update!(id, attrs)

            return find!(id)
          rescue ActiveRecord::RecordInvalid,
            ActiveRecord::StatementInvalid =>
            raise NucleusCore::RecordNotSaved.new(message: e.message)
          rescue NucleusCore::RecordNotFound => e
            raise e
          end

          def destroy!(id, attrs = {})
            #{refs.class_name}.destroy(id)
          rescue ActiveRecord::RecordNotDeleted => e
            raise NucleusCore::RecordNotDeleted.new(message: e.message)
          end
        end
      RUBY

      create_file("app/repositories/#{refs.file_name}_repository.rb", content)
    end

    def create_operations(refs)
      create = <<~RUBY
        class #{refs.module_name}::Create < NucleusCore::Operation
          def call
            attributes = context.to_h.slice(*#{refs.columns.delete(:id).to_a})

            validate_required_parameters!() do |missing|
              missing.push("missing attributes") if attributes.empty?
            end

            #{refs.variable_name} = #{refs.class_name}Repository.create!(attributes)

            result.#{refs.variable_name} = #{refs.variable_name}
          rescue NucleusCore::RecordNotSaved => e
            context.fail!(exception: e)
          end
        end
      RUBY

      fetch = <<~RUBY
        class #{refs.module_name}::Fetch < NucleusCore::Operation
          def call
            validate_required_parameters!()

            #{refs.variable_name} = #{refs.class_name}Repository.find!(context.id)

            result.#{refs.variable_name} = #{refs.variable_name}
          rescue NucleuCore::RecordNotFound => e
            context.fail!(exception: repo.exception)
          end

          def required_args
            [#{refs.primary_key.to_sym}]
          end
        end
      RUBY

      search = <<~RUBY
        class #{refs.module_name}::Search < NucleusCore::Operation
          def call
            search_attrs = context.to_h.slice(*#{refs.columns.to_a})

            validate_required_parameters!() do |missing|
              if search_attrs.empty?
                missing.push("missing search attributes: #{refs.columns.to_a.join(', ')}")
              end
            end

            #{refs.folder_name} = #{refs.class_name}Repository.search(search_attrs)

            result.#{refs.folder_name} = #{refs.folder_name}
          end
        end
      RUBY

      update = <<~RUBY
        class #{refs.module_name}::Update < NucleusCore::Operation
          def call
            attributes = context.to_h.slice(*#{refs.columns.delete(:id).to_a})

            validate_required_parameters!() do |missing|
              missing.push("missing update attributes") if attributes.empty?
            end

            #{refs.variable_name} = #{refs.class_name}Repository.update!(context.id, attributes)
            context.#{refs.variable_name} = #{refs.variable_name}
          end

          def required_args
            [:id]
          end
        end
      RUBY

      destroy = <<~RUBY
        class #{refs.module_name}::Destroy < NucleusCore::Operation
          def call
            validate_required_parameters!()

            #{refs.class_name}Repository.destroy!(context.id)
          rescue NucleusCore::RecordNotDeleted => e
            context.fail(exception: e)
          end

          def required_args
            [:id]
          end
        end
      RUBY

      create_file("app/operations/#{refs.folder_name}/create.rb", create)
      create_file("app/operations/#{refs.folder_name}/fetch.rb", fetch)
      create_file("app/operations/#{refs.folder_name}/search.rb", search)
      create_file("app/operations/#{refs.folder_name}/update.rb", update)
      create_file("app/operations/#{refs.folder_name}/destroy.rb", destroy)
    end

    def create_view(refs)
      content = <<~RUBY
        class #{refs.module_name}::View < NucleusCore::View
          def initialize(entity)
            super(entity.attributes)
          end
        end
      RUBY

      create_file("app/view_models/#{refs.folder_name}/view.rb", content)
    end

    def create_policy(refs)
      content = <<~RUBY
        class #{refs.class_name}::View < NucleusCore::Policy
          def read_#{refs.entity_name}?
            true # implement
          end

          def write_#{refs.entity_name}?
            true # implement
          end

          def access_#{refs.entity_name}?
            true # implement
          end
        end
      RUBY

      create_file("app/policies/#{refs.file_name}_policy.rb", content)
    end

    def create_controller(refs)
      content = <<~RUBY
        class #{refs.module_name}Controller < ApplicationController
          def show
            render_response do |req|
              result = #{refs.module_name}::Fetch.call(show_params)

              return result if !result.success?

              #{refs.variable_name} = result.#{refs.entity_name}
              policy = #{refs.class_name}Policy.new(current_user, #{refs.variable_name})
              policy.enforce!(:can_read_#{refs.variable_name}?, :can_access_#{refs.variable_name}?)

              return #{refs.module_name}::View.new(result.#{refs.variable_name})
            end
          end

          def index
            render_response do |req|
              policy = #{refs.class_name}Policy.new(current_user)
              policy.enforce!(:can_read_#{refs.entity_name}?)

              result = #{refs.module_name}::Search.call(index_params)

              return result if !result.success?

              #{refs.variable_name.pluralize} = result.#{refs.variable_name.pluralize}

              return #{refs.variable_name.pluralize}.map do |#{refs.variable_name}|
                #{refs.module_name}::View.new(#{refs.variable_name})
              end
            end
          end

          def create
            render_response do |req|
              policy = #{refs.class_name}Policy.new(current_user, #{refs.variable_name})
              policy.enforce!(:can_write_#{refs.variable_name}?)

              result = #{refs.module_name}::Update.call(update_params)

              return result if !result.success?

              #{refs.variable_name} = result.#{refs.variable_name}
              return #{refs.module_name}::View.new(result.#{refs.entity_name})
            end
          end

          def update
            render_response do |req|
              #{refs.variable_name} = #{refs.class_name}Repository.find!(update_params[:id])
              policy = #{refs.class_name}Policy.new(current_user, #{refs.variable_name})
              policy.enforce!(:can_write_#{refs.variable_name}?, :can_access_#{refs.variable_name}?)

              result = #{refs.module_name}::Create.call(create_params)

              return result if !result.success?

              #{refs.variable_name} = result.#{refs.variable_name}
              return #{refs.module_name}::View.new(#{refs.entity_name})
            end
          end

          def destroy
            render_response do |req|
              #{refs.variable_name} = #{refs.class_name}Repository.find!(show_params[:id])
              policy = #{refs.class_name}Policy.new(current_user, #{refs.variable_name})
              policy.enforce!(:can_write_#{refs.variable_name}?, :can_access_#{refs.variable_name}?)

              return #{refs.module_name}::Destroy.call(show_params)
            end
          end

          private

          def show_params
            params.permit(#{refs.primary_key.to_sym})
          end

          def index_params
            params.permit(*#{refs.columns.to_a})
          end

          def create_params
            params.permit(*#{refs.columns.delete(:id).to_a})
          end

          def update_params
            params.permit(*#{refs.columns.to_a})
          end
        end
      RUBY

      create_file("app/controllers/#{refs.folder_name}_controller.rb", content)
    end

    def update_routes(refs)
      append_to_file("config/routes.rb", after: /Rails.application.routes.draw do\n/) do
        <<-RUBY
  resources :#{refs.folder_name}, only: [:show, :index, :create, :update, :destroy]
        RUBY
      end
    end

    def entity_details(table_name)
      conn = ActiveRecord::Base.connection
      primary_key = conn.schema_cache.primary_keys(table_name)
      indexes = conn.indexes(table_name).select(&:unique)
      columns = conn.columns(table_name).to_set(&:name)

      OpenStruct.new(
        {
          table_name: table_name,                                # posts
          primary_key: primary_key,                              # id
          columns: columns,                                      # ['id', 'title', 'body', etc...]
          indexes: indexes,                                      # #<ActiveRecord::ConnectionAdapters::IndexDefinition>
          class_name: table_name.singularize.camelize,           # Post
          entity_name: table_name.tableize.singularize.downcase, # post
          module_name: table_name.pluralize.camelize,            # Posts
          folder_name: table_name.tableize                       # posts
        }.tap do |attrs|
          attrs[:file_name] = attrs[:entity_name]                # post
          attrs[:variable_name] = attrs[:entity_name]            # post
        end
      )
    end
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength, Metrics/AbcSize
