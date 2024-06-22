class TestActiveJobWorker < NucleusRails::Worker
  queue_adapter :active_job

  def self.call(args={})
    super(args.reverse_merge(queue: :urgent))
  end

  def call
    args.keys.join("-")
  end
end

class TestSidekiqWorker < NucleusRails::Worker
  queue_adapter :sidekiq

  def self.call(args={})
    super(args.reverse_merge(queue: :whenever))
  end

  def call
    args.keys.join(".")
  end
end
