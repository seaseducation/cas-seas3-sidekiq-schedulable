require 'spec_helper'
module Sidekiq
  module Schedulable
    describe WorkerScheduler do
      subject { WorkerScheduler.new }

      describe '#schedule' do
        it 'takes a worker, time and arguments and schedules the worker' do
          worker_class = double('SchedulableWorker', perform_at: nil)
          schedule_at = DateTime.current + 5.minutes
          subject.schedule worker_class, schedule_at, 1, 2, 3
          expect(worker_class).to have_received(:perform_at).with(schedule_at, 1, 2, 3)
        end

        it 'if a worker is already scheduled, reschedules the worker' do
          worker_class = double('SchedulableWorker', reschedule: nil, perform_at: nil, score: nil)
          schedule_at = DateTime.current + 5.minutes
          subject.stub(existing_worker: worker_class)
          subject.schedule worker_class, schedule_at
          expect(worker_class).to have_received(:reschedule).with(schedule_at)
          expect(worker_class).to_not have_received(:perform_at)
        end

        it 'if a worker is scheduled and the time has not changed, it does not reschedule' do
          schedule_at = DateTime.current + 5.minutes
          worker_class = double('SchedulableWorker', reschedule: nil, perform_at: nil, score: schedule_at)
          subject.stub(existing_worker: worker_class)
          subject.schedule worker_class, schedule_at
          expect(worker_class).to_not have_received(:reschedule)
          expect(worker_class).to_not have_received(:perform_at)
        end

        it 'does not schedule workers in the past' do
          worker_class = double('SchedulableWorker', perform_at: nil)
          schedule_at = DateTime.current - 5.minutes
          subject.schedule worker_class, schedule_at, 1, 2, 3
          expect(worker_class).to_not have_received(:perform_at)
        end

        it 'will remove workers with a new schedule in the past' do
          worker_class = double('SchedulableWorker', reschedule: nil, perform_at: nil, score: DateTime.current + 5.minutes, delete: nil)
          schedule_at = DateTime.current - 5.minutes
          subject.stub(existing_worker: worker_class)
          subject.schedule worker_class, schedule_at
          expect(worker_class).to_not have_received(:reschedule)
          expect(worker_class).to_not have_received(:perform_at)
          expect(worker_class).to have_received(:delete)
        end
      end

      describe '#deschedule' do
        it 'calls delete on an existing worker' do
          worker_class = double('SchedulableWorker', reschedule: nil, perform_at: nil, score: DateTime.current + 5.minutes, delete: nil)
          subject.stub(existing_worker: worker_class)
          subject.deschedule worker_class
          expect(worker_class).to_not have_received(:reschedule)
          expect(worker_class).to_not have_received(:perform_at)
          expect(worker_class).to have_received(:delete)
        end
      end

      describe '#existing_worker' do
        it 'finds an existing worker by arguments and class' do
          worker_class = double('SchedulableWorker', name: 'SchedulableWorker')
          matching_enqueued_job = OpenStruct.new(klass: 'SchedulableWorker', args: [1, 2, 3])
          nonmatching_enqueued_job = OpenStruct.new(klass: 'SchedulableWorker', args: [1, 2])
          expect(Sidekiq::ScheduledSet).to receive(:new) { [nonmatching_enqueued_job, matching_enqueued_job] }
          expect(subject.send(:existing_worker, worker_class, 1, 2, 3)).to eq matching_enqueued_job
        end
      end
    end
  end
end
