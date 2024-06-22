require "active_job"

module NucleusRails
  class Worker < NucleusCore::Worker
    def self.enabled?(class_name)
      Object.const_defined?(class_name.to_s.to_sym)
    end

    class SidekiqAdapter < NucleusCore::Worker::Adapter
      class ApplicationJob
        include Sidekiq::Worker if NucleusRails::Worker.enabled?(:Sidekiq)

        def perform(*args)
          NucleusCore::Worker::Adapter.execute(*args)
        end
      end

      def self.execute_async(class_name, method_name, args)
        worker_option_keys = NucleusRails::Worker.enabled?(:Sidekiq) ? Sidekiq.options.keys : {}
        worker_args = args.slice!(worker_option_keys)

        ApplicationJob.set(worker_args).perform_async(class_name, method_name, args)
      end
    end

    class ActiveJobAdapter < NucleusCore::Worker::Adapter
      class ApplicationJob < ActiveJob::Base
        def perform(*args)
          NucleusCore::Worker::Adapter.execute(*args)
        end
      end

      def self.execute_async(class_name, method_name, args)
        worker_args = {}

        if args.is_a?(Hash)
          worker_arg_keys = %i[wait wait_until queue priority]
          worker_args = args.slice(*worker_arg_keys)
          args = args.except(*worker_arg_keys)
        end

        ApplicationJob.set(worker_args).perform_later(class_name, method_name, args)
      end
    end

    ADAPTER_LOOKUP = {
      active_job: NucleusRails::Worker::ActiveJobAdapter,
      sidekiq: NucleusRails::Worker::SidekiqAdapter
    }.freeze

    def self.queue_adapter(adapter=nil)
      super(ADAPTER_LOOKUP.fetch(adapter) { adapter })
    end
  end
end
