# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReportsController, feature_category: :users do
  let(:reporter) { create(:user) }
  let(:user)     { create(:user) }
  let(:attrs) do
    attributes_for(:abuse_report) do |hash|
      hash[:user_id] = user.id
    end
  end

  before do
    sign_in(reporter)
  end

  describe 'GET new' do
    context 'when the user has already been deleted' do
      it 'redirects the reporter to root_path' do
        user_id = user.id
        user.destroy!

        get new_abuse_report_path(user_id: user_id)

        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. The user has been deleted.'))
      end
    end

    context 'when the user has already been blocked' do
      it 'redirects the reporter to the user\'s profile' do
        user.block

        get new_abuse_report_path(user_id: user.id)

        expect(response).to redirect_to user
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. This user has been blocked.'))
      end
    end
  end

  describe 'POST add_category', :aggregate_failures do
    subject(:request) { post add_category_abuse_reports_path, params: request_params }

    let(:abuse_category) { 'spam' }

    context 'when user is reported for abuse' do
      let(:ref_url) { 'http://example.com' }
      let(:request_params) { { user_id: user.id, abuse_report: { category: abuse_category }, ref_url: ref_url } }

      it 'renders new template' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template(:new)
      end

      it 'sets the instance variables' do
        subject

        expect(assigns(:abuse_report)).to be_kind_of(AbuseReport)
        expect(assigns(:abuse_report)).to have_attributes(
          user_id: user.id,
          category: abuse_category
        )
        expect(assigns(:ref_url)).to eq(ref_url)
      end
    end

    context 'when abuse_report is missing in params' do
      let(:request_params) { { user_id: user.id } }

      it 'raises an error' do
        expect { subject }.to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when user_id is missing in params' do
      let(:request_params) { { abuse_report: { category: abuse_category } } }

      it 'redirects the reporter to root_path' do
        subject

        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. The user has been deleted.'))
      end
    end

    context 'when the user has already been deleted' do
      let(:request_params) { { user_id: user.id, abuse_report: { category: abuse_category } } }

      it 'redirects the reporter to root_path' do
        user.destroy!

        subject

        expect(response).to redirect_to root_path
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. The user has been deleted.'))
      end
    end

    context 'when the user has already been blocked' do
      let(:request_params) { { user_id: user.id, abuse_report: { category: abuse_category } } }

      it 'redirects the reporter to the user\'s profile' do
        user.block

        subject

        expect(response).to redirect_to user
        expect(flash[:alert]).to eq(_('Cannot create the abuse report. This user has been blocked.'))
      end
    end
  end

  describe 'POST create' do
    context 'with valid attributes' do
      it 'saves the abuse report' do
        expect do
          post abuse_reports_path(abuse_report: attrs)
        end.to change { AbuseReport.count }.by(1)
      end

      it 'calls notify' do
        expect_next_instance_of(AbuseReport) do |instance|
          expect(instance).to receive(:notify)
        end

        post abuse_reports_path(abuse_report: attrs)
      end

      it 'redirects back to root' do
        post abuse_reports_path(abuse_report: attrs)

        expect(response).to redirect_to root_path
      end
    end

    context 'with invalid attributes' do
      it 'redirects back to root' do
        attrs.delete(:user_id)
        post abuse_reports_path(abuse_report: attrs)

        expect(response).to redirect_to root_path
      end
    end
  end
end
