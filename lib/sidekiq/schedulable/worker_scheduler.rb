require 'ostruct'
require 'active_support/all'
require 'sidekiq/api'

module Sidekiq
  module Schedulable
    class WorkerScheduler
      def schedule(klass, schedule_at, *args)
        if (worker = existing_worker(klass, *args))
          if schedule_at <= DateTime.current
            worker.delete
          elsif worker.score != schedule_at
            worker.reschedule schedule_at unless worker.score == schedule_at
          end
        else
          klass.perform_at schedule_at, *args if schedule_at > DateTime.current
        end
      end

      def deschedule(klass, *args)
        worker = existing_worker(klass, *args)
        worker.delete if worker
      end

      def existing_worker(klass, *args)
        Sidekiq::ScheduledSet.new.find do |job|
          job.args == args && klass.name == job.klass
        end
      end
    end
  end
end
