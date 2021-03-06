require "./fiberpool/*"

class Fiberpool(T, I)
  @queue : I
  @pool_size : Int32

  getter exceptions : Array(Exception)

  def self.new(iterable : Iterable, pool_size = 10)
    new(iterable.each, pool_size)
  end

  def self.new(iterator : Iterator(T), pool_size)
    Fiberpool(T, typeof(iterator)).new(iterator, pool_size, nil)
  end

  protected def initialize(@queue, @pool_size, dummy)
    @exceptions = [] of Exception
  end

  private def worker(item : T, &block : T -> Void)
    signal_channel = Channel(Exception).new

    spawn do
      begin
        block.call(item)
      rescue ex
        signal_channel.send(ex)
      else
        signal_channel.send(Exception.new(nil))
      end
    end

    signal_channel.receive_select_action
  end

  def run(&block : T -> Void)
    pool_counter = 0
    workers_channels = [] of Channel::StrictReceiveAction(Exception)
    queue = @queue.each
    more_pools = true

    loop do
      break if !more_pools && workers_channels.empty?
      while pool_counter < @pool_size && more_pools
        item = queue.next
        if item.is_a?(Iterator::Stop)
          more_pools = false
          break
        end
        pool_counter += 1
        workers_channels << worker(item, &block)
      end

      index, signal_exception = Channel.select(workers_channels)
      workers_channels.delete_at(index)
      pool_counter -= 1

      @exceptions << signal_exception if !signal_exception.is_a?(Channel::NotReady) && signal_exception.message
    end
  end
end
