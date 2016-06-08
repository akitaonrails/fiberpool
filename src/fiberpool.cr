require "./fiberpool/*"

module Fiberpool
  class BreakException < Exception; end

  private def self.worker(&block)
    signal_channel = Channel::Unbuffered(Exception).new

    spawn do
      begin
        block.call
      rescue ex
        signal_channel.send(ex)
      else
        signal_channel.send(Exception.new(nil))
      end
    end

    signal_channel.receive_op
  end

  def self.pool(max_num_of_workers = 10, &block)
    pool_counter = 0
    workers_channels = [] of Channel::ReceiveOp(Channel::Unbuffered(Exception), Exception)

    loop do
      while pool_counter < max_num_of_workers
        pool_counter += 1
        workers_channels << worker(&block)
      end

      index, signal_exception = Channel.select(workers_channels)
      workers_channels.delete_at(index)
      pool_counter -= 1

      if signal_exception.is_a?(BreakException)
        break
      elsif signal_exception.message.nil?
        # does nothing, just signalling to continue
      else
        puts "ERROR: #{signal_exception.message}"
      end
    end
  end
end
