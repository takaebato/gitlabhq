# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabShellWorker, :sidekiq_inline do
  describe '#perform' do
    Gitlab::Shell::PERMITTED_ACTIONS.each do |action|
      describe "with the #{action} action" do
        it 'forwards the message to Gitlab::Shell' do
          expect_next_instance_of(Gitlab::Shell) do |instance|
            expect(instance).to respond_to(action)
            expect(instance).to receive(action).with('foo', 'bar')
          end

          described_class.perform_async(action, 'foo', 'bar')
        end
      end
    end

    describe 'all other commands' do
      context 'when verify_gitlab_shell_worker_method_names is enabled' do
        it 'raises ArgumentError' do
          allow_next_instance_of(described_class) do |job_instance|
            expect(job_instance).not_to receive(:gitlab_shell)
          end

          expect { described_class.perform_async('foo', 'bar', 'baz') }
            .to raise_error(ArgumentError, 'foo not allowed for GitlabShellWorker')
        end
      end

      context 'when verify_gitlab_shell_worker_method_names is disabled' do
        before do
          stub_feature_flags(verify_gitlab_shell_worker_method_names: false)
        end

        it 'forwards the message to Gitlab::Shell' do
          expect_next_instance_of(Gitlab::Shell) do |instance|
            expect(instance).to receive('foo').with('bar', 'baz')
          end

          described_class.perform_async('foo', 'bar', 'baz')
        end
      end
    end
  end
end
