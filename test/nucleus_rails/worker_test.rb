require "test_helper"

describe "#call" do
  include ActiveJob::TestHelper

  before do
    @args = { parameters: { key: "value" }, other: "key" }
  end

  describe "self.call" do
    describe "ActiveJobAdapter" do
      subject { TestActiveJobWorker.call(@args) }

      it "enqueues the job using active job" do
        assert_enqueued_with(
          job: NucleusRails::Worker::ActiveJobAdapter::ApplicationJob,
          args: [TestActiveJobWorker.name, :call, @args],
          queue: "urgent"
        ) { subject }
      end

      describe "when class name and method are passed" do
        before do
          @args = { class_name: Array, method_name: :shift, args: [1, 2] }
        end

        it "enqueues the job using active job" do
          assert_enqueued_with(
            job: NucleusRails::Worker::ActiveJobAdapter::ApplicationJob,
            args: [Array, :shift, @args[:args]],
            queue: "default"
          ) { subject }
        end
      end
    end

    describe "SidekiqAdapter" do
      subject do
        Sidekiq::Testing.fake!

        TestSidekiqWorker.call(@args)
      end

      it "enqueues the job using sidekiq" do
        job_class = NucleusRails::Worker::SidekiqAdapter::ApplicationJob
        initial_job_size = job_class.jobs.size

        subject

        assert_equal(initial_job_size + 1, job_class.jobs.size)

        enqueued_job = job_class.jobs.last
        assert(enqueued_job["retry"])
        assert_equal("whenever", enqueued_job["queue"])
        assert_equal({ "key" => "value" }, enqueued_job["parameters"])
        assert_equal("key", enqueued_job["other"])
        assert_equal(["TestSidekiqWorker", "call", {}], enqueued_job["args"])
      end
    end
  end
end
