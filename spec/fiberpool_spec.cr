require "./spec_helper"
require "benchmark"

describe Fiberpool do
  it "should deplete the queue and add each item to a results accumulator - just tests the external API" do
    results = [] of Int32
    queue = (1..100).to_a
    pool = Fiberpool.new(queue, 10)
    pool.run do |item|
      results << item
    end
    results.size.should eq(100)
  end

  it "should do the work 5x faster with the queue" do
    m = Benchmark.measure("") {
      results = [] of Int32
      queue = (1..10).to_a
      pool = Fiberpool.new(queue, 5)
      pool.run do |item|
        sleep 1
        results << item
      end
    }
    # if they had run in sequence, it should take 10 seconds of sleep
    # but with a queue of 5 fibers, it should take around 2 seconds
    (m.real < 3).should eq(true)
  end
end
