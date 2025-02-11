# frozen_string_literal: true
require 'spec_helper'

RSpec.shared_examples 'validate path globs' do |path_globs|
  it 'returns an array of path globs' do
    expect(path_globs).to be_an(Array)
    expect(path_globs).to all(be_an(Pathname))
  end
end

RSpec.shared_examples 'validate schema data' do |tables_and_views|
  it 'all tables and views have assigned a known gitlab_schema' do
    expect(tables_and_views).to all(
      match([be_a(String), be_in(Gitlab::Database.schemas_to_base_models.keys.map(&:to_sym))])
    )
  end
end

RSpec.describe Gitlab::Database::GitlabSchema do
  describe '.deleted_views_and_tables_to_schema' do
    include_examples 'validate schema data', described_class.deleted_views_and_tables_to_schema
  end

  describe '.views_and_tables_to_schema' do
    include_examples 'validate schema data', described_class.views_and_tables_to_schema

    # This being run across different databases indirectly also tests
    # a general consistency of structure across databases
    Gitlab::Database.database_base_models.except(:geo).each do |db_config_name, db_class|
      context "for #{db_config_name} using #{db_class}" do
        let(:db_data_sources) { db_class.connection.data_sources }

        # The Geo database does not share the same structure as all decomposed databases
        subject { described_class.views_and_tables_to_schema.select { |_, v| v != :gitlab_geo } }

        it 'new data sources are added' do
          missing_data_sources = db_data_sources.to_set - subject.keys

          expect(missing_data_sources).to be_empty, \
            "Missing table/view(s) #{missing_data_sources.to_a} not found in " \
            "#{described_class}.views_and_tables_to_schema. " \
            "Any new tables or views must be added to the database dictionary. " \
            "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
        end

        it 'non-existing data sources are removed' do
          extra_data_sources = subject.keys.to_set - db_data_sources

          expect(extra_data_sources).to be_empty, \
            "Extra table/view(s) #{extra_data_sources.to_a} found in #{described_class}.views_and_tables_to_schema. " \
            "Any removed or renamed tables or views must be removed from the database dictionary. " \
            "More info: https://docs.gitlab.com/ee/development/database/database_dictionary.html"
        end
      end
    end
  end

  describe '.dictionary_path_globs' do
    include_examples 'validate path globs', described_class.dictionary_path_globs
  end

  describe '.view_path_globs' do
    include_examples 'validate path globs', described_class.view_path_globs
  end

  describe '.deleted_tables_path_globs' do
    include_examples 'validate path globs', described_class.deleted_tables_path_globs
  end

  describe '.deleted_views_path_globs' do
    include_examples 'validate path globs', described_class.deleted_views_path_globs
  end

  describe '.tables_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.except(:geo) }
    let(:views) { database_models.flat_map { |_, m| m.connection.views }.sort.uniq }

    subject { described_class.tables_to_schema }

    it 'returns only tables' do
      tables = subject.keys

      expect(tables).not_to include(views.to_set)
    end
  end

  describe '.views_to_schema' do
    let(:database_models) { Gitlab::Database.database_base_models.except(:geo) }
    let(:tables) { database_models.flat_map { |_, m| m.connection.tables }.sort.uniq }

    subject { described_class.views_to_schema }

    it 'returns only views' do
      views = subject.keys

      expect(views).not_to include(tables.to_set)
    end
  end

  describe '.table_schema' do
    using RSpec::Parameterized::TableSyntax

    where(:name, :classification) do
      'ci_builds'                       | :gitlab_ci
      'my_schema.ci_builds'             | :gitlab_ci
      'information_schema.columns'      | :gitlab_internal
      'audit_events_part_5fc467ac26'    | :gitlab_main
      '_test_gitlab_main_table'         | :gitlab_main
      '_test_gitlab_ci_table'           | :gitlab_ci
      '_test_my_table'                  | :gitlab_shared
      'pg_attribute'                    | :gitlab_internal
      'my_other_table'                  | :undefined_my_other_table
    end

    with_them do
      subject { described_class.table_schema(name) }

      it { is_expected.to eq(classification) }
    end
  end
end
