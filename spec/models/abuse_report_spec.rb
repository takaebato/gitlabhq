# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AbuseReport, feature_category: :insider_threat do
  let_it_be(:report, reload: true) { create(:abuse_report) }
  let_it_be(:user, reload: true) { create(:admin) }

  subject { report }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to belong_to(:reporter).class_name('User') }
    it { is_expected.to belong_to(:user) }

    it "aliases reporter to author" do
      expect(subject.author).to be(subject.reporter)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:reporter) }
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to validate_presence_of(:message) }
    it { is_expected.to validate_uniqueness_of(:user_id).with_message('has already been reported') }
    it { is_expected.to validate_presence_of(:category) }
  end

  describe '#remove_user' do
    it 'blocks the user' do
      expect { subject.remove_user(deleted_by: user) }.to change { subject.user.blocked? }.to(true)
    end

    it 'lets a worker delete the user' do
      expect(DeleteUserWorker).to receive(:perform_async).with(user.id, subject.user.id, { hard_delete: true })

      subject.remove_user(deleted_by: user)
    end
  end

  describe '#notify' do
    it 'delivers' do
      expect(AbuseReportMailer).to receive(:notify).with(subject.id)
        .and_return(spy)

      subject.notify
    end

    it 'returns early when not persisted' do
      report = build(:abuse_report)

      expect(AbuseReportMailer).not_to receive(:notify)

      report.notify
    end
  end

  describe 'enums' do
    let(:categories) do
      {
        spam: 1,
        offensive: 2,
        phishing: 3,
        crypto: 4,
        credentials: 5,
        copyright: 6,
        malware: 7,
        other: 8
      }
    end

    it { is_expected.to define_enum_for(:category).with_values(**categories) }
  end
end
