# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Note'], feature_category: :team_planning do
  it 'exposes the expected fields' do
    expected_fields = %i[
      author
      body
      body_html
      confidential
      internal
      created_at
      discussion
      id
      position
      project
      resolvable
      resolved
      resolved_at
      resolved_by
      system
      system_note_icon_name
      updated_at
      user_permissions
      url
      system_note_metadata
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::Note) }
  specify { expect(described_class).to require_graphql_authorizations(:read_note) }
end
