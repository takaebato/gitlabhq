require 'spec_helper'

describe Epic do
  describe 'associations' do
    subject { build(:epic) }

    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:assignee).class_name('User') }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to have_many(:epic_issues) }
  end

  describe 'validations' do
    subject { create(:epic) }

    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:title) }
  end

  describe 'modules' do
    subject { described_class }

    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :iid }
      let(:instance) { build(:epic) }
      let(:scope) { :group }
      let(:scope_attrs) { { namespace: instance.group } }
      let(:usage) { :epics }
    end
  end

  describe '.order_start_or_end_date_asc' do
    let(:group) { create(:group) }

    it 'returns epics sorted by start or end date' do
      epic1 = create(:epic, group: group, start_date: 7.days.ago, end_date: 3.days.ago)
      epic2 = create(:epic, group: group, start_date: 3.days.ago)
      epic3 = create(:epic, group: group, end_date: 5.days.ago)
      epic4 = create(:epic, group: group)

      expect(described_class.order_start_or_end_date_asc).to eq([epic4, epic1, epic3, epic2])
    end
  end

  describe '#upcoming?' do
    it 'returns true when start_date is in the future' do
      epic = build(:epic, start_date: 1.month.from_now)

      expect(epic.upcoming?).to be_truthy
    end

    it 'returns false when start_date is in the past' do
      epic = build(:epic, start_date: Date.today.prev_year)

      expect(epic.upcoming?).to be_falsey
    end
  end

  describe '#expired?' do
    it 'returns true when due_date is in the past' do
      epic = build(:epic, end_date: Date.today.prev_year)

      expect(epic.expired?).to be_truthy
    end

    it 'returns false when due_date is in the future' do
      epic = build(:epic, end_date: Date.today.next_year)

      expect(epic.expired?).to be_falsey
    end
  end

  describe '#elapsed_days' do
    it 'returns 0 if there is no start_date' do
      epic = build(:epic)

      expect(epic.elapsed_days).to eq(0)
    end

    it 'returns elapsed_days when start_date is present' do
      epic = build(:epic, start_date: 7.days.ago)

      expect(epic.elapsed_days).to eq(7)
    end
  end

  describe '#start_date' do
    let(:date) { Date.new(2000, 1, 1) }

    context 'is set' do
      subject { build(:epic, :use_fixed_dates, start_date: date) }

      it 'returns as is' do
        expect(subject.start_date).to eq(date)
      end
    end
  end

  describe '#start_date_from_milestones' do
    context 'fixed date' do
      subject { create(:epic, :use_fixed_dates) }
      let(:date) { Date.new(2017, 3, 4) }

      before do
        milestone1 = create(
          :milestone,
          start_date: date,
          due_date: date + 10.days
        )
        epic_issue1 = create(:epic_issue, epic: subject)
        epic_issue1.issue.update(milestone: milestone1)

        milestone2 = create(
          :milestone,
          start_date: date + 5.days,
          due_date: date + 15.days
        )
        epic_issue2 = create(:epic_issue, epic: subject)
        epic_issue2.issue.update(milestone: milestone2)
      end

      it 'returns earliest start date from issue milestones' do
        expect(subject.start_date_from_milestones).to eq(date)
      end
    end

    context 'milestone date' do
      subject { create(:epic, start_date: date) }
      let(:date) { Date.new(2017, 3, 4) }

      it 'returns start_date' do
        expect(subject.start_date_from_milestones).to eq(date)
      end
    end
  end

  describe '#due_date_from_milestones' do
    context 'fixed date' do
      subject { create(:epic, :use_fixed_dates) }
      let(:date) { Date.new(2017, 3, 4) }

      before do
        milestone1 = create(
          :milestone,
          start_date: date - 30.days,
          due_date: date - 20.days
        )
        epic_issue1 = create(:epic_issue, epic: subject)
        epic_issue1.issue.update(milestone: milestone1)

        milestone2 = create(
          :milestone,
          start_date: date - 10.days,
          due_date: date
        )
        epic_issue2 = create(:epic_issue, epic: subject)
        epic_issue2.issue.update(milestone: milestone2)
      end

      it 'returns latest due date from issue milestones' do
        expect(subject.due_date_from_milestones).to eq(date)
      end
    end

    context 'milestone date' do
      subject { create(:epic, due_date: date) }
      let(:date) { Date.new(2017, 3, 4) }

      it 'returns due_date' do
        expect(subject.due_date_from_milestones).to eq(date)
      end
    end
  end

  describe '#update_dates' do
    context 'fixed date is set' do
      subject { create(:epic, :use_fixed_dates, start_date: nil, end_date: nil) }

      it 'updates to fixed date' do
        subject.update_dates

        expect(subject.start_date).to eq(subject.start_date_fixed)
        expect(subject.due_date).to eq(subject.due_date_fixed)
      end
    end

    context 'fixed date is not set' do
      subject { create(:epic, start_date: nil, end_date: nil) }

      let(:milestone1) do
        create(
          :milestone,
          start_date: Date.new(2000, 1, 1),
          due_date: Date.new(2000, 1, 10)
        )
      end
      let(:milestone2) do
        create(
          :milestone,
          start_date: Date.new(2000, 1, 3),
          due_date: Date.new(2000, 1, 20)
        )
      end

      context 'multiple milestones' do
        before do
          epic_issue1 = create(:epic_issue, epic: subject)
          epic_issue1.issue.update(milestone: milestone1)
          epic_issue2 = create(:epic_issue, epic: subject)
          epic_issue2.issue.update(milestone: milestone2)
        end

        context 'complete start and due dates' do
          it 'updates to milestone dates' do
            subject.update_dates

            expect(subject.start_date).to eq(milestone1.start_date)
            expect(subject.due_date).to eq(milestone2.due_date)
          end
        end

        context 'without due date' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: Date.new(2000, 1, 1),
              due_date: nil
            )
          end
          let(:milestone2) do
            create(
              :milestone,
              start_date: Date.new(2000, 1, 3),
              due_date: nil
            )
          end

          it 'updates to milestone dates' do
            subject.update_dates

            expect(subject.start_date).to eq(milestone1.start_date)
            expect(subject.due_date).to eq(nil)
          end
        end

        context 'without any dates' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: nil,
              due_date: nil
            )
          end
          let(:milestone2) do
            create(
              :milestone,
              start_date: nil,
              due_date: nil
            )
          end

          it 'updates to milestone dates' do
            subject.update_dates

            expect(subject.start_date).to eq(nil)
            expect(subject.due_date).to eq(nil)
          end
        end
      end

      context 'without milestone' do
        before do
          create(:epic_issue, epic: subject)
        end

        it 'updates to milestone dates' do
          subject.update_dates

          expect(subject.start_date).to eq(nil)
          expect(subject.start_date_sourcing_milestone_id).to eq(nil)
          expect(subject.due_date).to eq(nil)
          expect(subject.due_date_sourcing_milestone_id).to eq(nil)
        end
      end

      context 'single milestone' do
        before do
          epic_issue1 = create(:epic_issue, epic: subject)
          epic_issue1.issue.update(milestone: milestone1)
        end

        context 'complete start and due dates' do
          it 'updates to milestone dates' do
            subject.update_dates

            expect(subject.start_date).to eq(milestone1.start_date)
            expect(subject.due_date).to eq(milestone1.due_date)
          end
        end

        context 'without due date' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: Date.new(2000, 1, 1),
              due_date: nil
            )
          end

          it 'updates to milestone dates' do
            subject.update_dates

            expect(subject.start_date).to eq(milestone1.start_date)
            expect(subject.due_date).to eq(nil)
          end
        end

        context 'without any dates' do
          let(:milestone1) do
            create(
              :milestone,
              start_date: nil,
              due_date: nil
            )
          end

          it 'updates to milestone dates' do
            subject.update_dates

            expect(subject.start_date).to eq(nil)
            expect(subject.due_date).to eq(nil)
          end
        end
      end
    end
  end

  describe '#issues_readable_by' do
    let(:user) { create(:user) }
    let(:group) { create(:group, :private) }
    let(:project) { create(:project, group: group) }
    let(:project2) { create(:project, group: group) }

    let!(:epic) { create(:epic, group: group) }
    let!(:issue) { create(:issue, project: project)}
    let!(:lone_issue) { create(:issue, project: project)}
    let!(:other_issue) { create(:issue, project: project2)}
    let!(:epic_issues) do
      [
        create(:epic_issue, epic: epic, issue: issue),
        create(:epic_issue, epic: epic, issue: other_issue)
      ]
    end

    let(:result) { epic.issues_readable_by(user) }

    it 'returns all issues if a user has access to them' do
      group.add_developer(user)

      expect(result.count).to eq(2)
      expect(result.map(&:id)).to match_array([issue.id, other_issue.id])
      expect(result.map(&:epic_issue_id)).to match_array(epic_issues.map(&:id))
    end

    it 'does not return issues user can not see' do
      project.add_developer(user)

      expect(result.count).to eq(1)
      expect(result.map(&:id)).to match_array([issue.id])
      expect(result.map(&:epic_issue_id)).to match_array([epic_issues.first.id])
    end
  end

  describe '#to_reference' do
    let(:group) { create(:group, path: 'group-a') }
    let(:epic) { create(:epic, iid: 1, group: group) }

    context 'when nil argument' do
      it 'returns epic id' do
        expect(epic.to_reference).to eq('&1')
      end
    end

    context 'when group argument equals epic group' do
      it 'returns epic id' do
        expect(epic.to_reference(epic.group)).to eq('&1')
      end
    end

    context 'when group argument differs from epic group' do
      it 'returns complete path to the epic' do
        expect(epic.to_reference(create(:group))).to eq('group-a&1')
      end
    end

    context 'when full is true' do
      it 'returns complete path to the epic' do
        expect(epic.to_reference(full: true)).to             eq('group-a&1')
        expect(epic.to_reference(epic.group, full: true)).to eq('group-a&1')
        expect(epic.to_reference(group, full: true)).to      eq('group-a&1')
      end
    end
  end

  context 'mentioning other objects' do
    let(:group)   { create(:group) }
    let(:epic) { create(:epic, group: group) }

    let(:project) { create(:project, :repository, :public) }
    let(:mentioned_issue) { create(:issue, project: project) }
    let(:mentioned_mr)     { create(:merge_request, source_project: project) }
    let(:mentioned_commit) { project.commit("HEAD~1") }

    let(:backref_text) { "epic #{epic.to_reference}" }
    let(:ref_text) do
      <<-MSG.strip_heredoc
        These are simple references:
          Issue:  #{mentioned_issue.to_reference(group)}
          Merge Request:  #{mentioned_mr.to_reference(group)}
          Commit: #{mentioned_commit.to_reference(group)}

        This is a self-reference and should not be mentioned at all:
          Self: #{backref_text}
      MSG
    end

    before do
      epic.description = ref_text
      epic.save
    end

    it 'creates new system notes for cross references' do
      [mentioned_issue, mentioned_mr, mentioned_commit].each do |newref|
        expect(SystemNoteService).to receive(:cross_reference)
          .with(newref, epic, epic.author)
      end

      epic.create_new_cross_references!(epic.author)
    end
  end
end
