# frozen_string_literal: true

module API
  class ImportGithub < ::API::Base
    before { authenticate! }

    feature_category :importers
    urgency :low

    rescue_from Octokit::Unauthorized, with: :provider_unauthorized
    rescue_from Gitlab::GithubImport::RateLimitError, with: :too_many_requests

    helpers do
      def client
        @client ||= if Feature.enabled?(:remove_legacy_github_client)
                      Gitlab::GithubImport::Client.new(params[:personal_access_token], host: params[:github_hostname])
                    else
                      Gitlab::LegacyGithubImport::Client.new(params[:personal_access_token], **client_options)
                    end
      end

      def access_params
        { github_access_token: params[:personal_access_token] }
      end

      def client_options
        { host: params[:github_hostname] }
      end

      def provider
        :github
      end

      def provider_unauthorized
        error!("Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account.", 401)
      end

      def too_many_requests
        error!('Too Many Requests', 429)
      end
    end

    desc 'Import a GitHub project' do
      detail 'This feature was introduced in GitLab 11.3.4.'
      success code: 201, model: ::ProjectEntity
      failure [
        { code: 400, message: 'Bad request' },
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 422, message: 'Unprocessable entity' },
        { code: 503, message: 'Service unavailable' }
      ]
      tags ['project_import_github']
    end
    params do
      requires :personal_access_token, type: String, desc: 'GitHub personal access token'
      requires :repo_id, type: Integer, desc: 'GitHub repository ID'
      optional :new_name, type: String, desc: 'New repo name'
      requires :target_namespace, type: String, desc: 'Namespace to import repo into'
      optional :github_hostname, type: String, desc: 'Custom GitHub enterprise hostname'
      optional :optional_stages, type: Hash, desc: 'Optional stages of import to be performed'
    end
    post 'import/github' do
      result = Import::GithubService.new(client, current_user, params).execute(access_params, provider)

      if result[:status] == :success
        present ProjectSerializer.new.represent(result[:project])
      else
        status result[:http_status]
        { errors: result[:message] }
      end
    end

    desc 'Cancel GitHub project import' do
      detail 'This feature was introduced in GitLab 15.5'
      success code: 200, model: ProjectImportEntity
      failure [
        { code: 400, message: 'Bad request' },
        { code: 401, message: 'Unauthorized' },
        { code: 403, message: 'Forbidden' },
        { code: 404, message: 'Not found' },
        { code: 503, message: 'Service unavailable' }
      ]
      tags ['project_import_github']
    end
    params do
      requires :project_id, type: Integer, desc: 'ID of importing project to be canceled'
    end
    post 'import/github/cancel' do
      project = Project.imported_from(provider.to_s).find(params[:project_id])
      result = Import::Github::CancelProjectImportService.new(project, current_user).execute

      if result[:status] == :success
        status :ok
        present ProjectSerializer.new.represent(project, serializer: :import)
      else
        render_api_error!(result[:message], result[:http_status])
      end
    end

    desc 'Import User Gists' do
      detail 'This feature was introduced in GitLab 15.8'
      success code: 202
      failure [
        { code: 401, message: 'Unauthorized' },
        { code: 422, message: 'Unprocessable Entity' },
        { code: 429, message: 'Too Many Requests' }
      ]
    end
    params do
      requires :personal_access_token, type: String, desc: 'GitHub personal access token'
    end
    post 'import/github/gists' do
      not_found! if Feature.disabled?(:github_import_gists)

      authorize! :create_snippet

      result = Import::Github::GistsImportService.new(current_user, client, access_params).execute

      if result[:status] == :success
        status 202
      else
        status result[:http_status]
        { errors: result[:message] }
      end
    end
  end
end
