require 'active_support/concern'

module Sidekiq
  module Schedulable
    module SchedulableModel
      extend ActiveSupport::Concern

      included do
        after_save :enqueue_worker
        after_destroy :dequeue_worker
      end

      protected
        def enqueue_worker
          WorkerScheduler.new.schedule worker, schedule_at, *worker_args
        end

        def dequeue_worker
          WorkerScheduler.new.deschedule worker, *worker_args
        end

        def worker
          fail NotImplementedError
        end

        def worker_args
          [id]
        end
    end
  end
end
