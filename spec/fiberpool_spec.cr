require "./spec_helper"

describe Fiberpool do
  it "should deplete the queue and add each item to a results accumulator - just tests the external API" do
    queue = (1..100).to_a
    results = [] of Int32
    Fiberpool.pool(10) do
      if queue.size > 0
        results << queue.pop
      else
        raise Fiberpool::BreakException.new
      end
    end
    results.size.should eq(100)
  end
end
