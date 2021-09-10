require "./fiberpool/*"

class Worker(T)
  def initialize(signal_channel : Channel(Tuple(Worker, Exception)), item : T, &block : T -> Void)
    spawn do
      begin
        block.call(item)
      rescue ex
        signal_channel.send({self, ex})
      else
        signal_channel.send({self, Exception.new(nil)})
      end
    end
  end
end

class Fiberpool(T, I)
  @queue : I
  @pool_size : Int32
  @signal_channel : Channel(Tuple(Worker(T), Exception))

  getter exceptions : Array(Exception)

  def self.new(iterable : Iterable, pool_size = 10)
    new(iterable.each, pool_size)
  end

  def self.new(iterator : Iterator(T), pool_size)
    Fiberpool(T, typeof(iterator)).new(iterator, pool_size, nil)
  end

  protected def initialize(@queue, @pool_size, dummy)
    @exceptions = [] of Exception
    @signal_channel = Channel(Tuple(Worker(T), Exception)).new
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
    workers = [] of Worker(T)
    queue = @queue.each
    more_pools = true

    loop do
      break if !more_pools && workers.empty?
      while pool_counter < @pool_size && more_pools
        item = queue.next

        if item.is_a?(Iterator::Stop)
          more_pools = false
          break
        end
        pool_counter += 1
        workers << Worker.new(@signal_channel, item, &block)
      end

      signal_exception = @signal_channel.receive
      workers.delete(signal_exception[0])
      pool_counter -= 1

      @exceptions << signal_exception[1] if !signal_exception[1].is_a?(Channel::NotReady) && signal_exception[1].message
    end
  end
end
