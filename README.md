# Crystal Fiber Pool

Crystal has the ability to spawn a huge amount of Fibers. Because pre-1.0 Crystal only support a single native thread of execution, they won't all run in parallel.

But specially if you're dealing with I/O operations, it seems like you can have several of them running concurrently.

The need came out of my pet project [cr_manga_downloadr](https://github.com/akitaonrails/cr_manga_downloadr) which is an example of how to build an HTTP crawler and scrapper.

In order to avoid doing a Denial of Service (or at least quickly exhausting the machine's available sockets) ideally you want to limit the maximum amount of HTTP requests going on at once.

The solution is to have a combination of a "master-fiber" creating new fibers until a maximum number, having each of those worker-fibers creating an individual channel to signal that they are done, and the master-fiber to select over all the worker-channels. Once one of them returns, the master-fiber can create a new worker-fiber that will, again, create a new worker-channel to signal back.

The implementation is based off stackoverflow answer: http://stackoverflow.com/a/30854065/1529907

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  fiberpool:
    github: akitaonrails/fiberpool
```

## Usage


```crystal
require "fiberpool"

maximum_number_of_workers = 10
# some list of things to do
queue                     = (1..100).to_a
# optional accumulator where the worker-fibers can register the processed results
results                   = [] of Int32

pool = Fiber::Pool.new(queue, maximum_number_of_workers)
pool.run do |item|
  results << item
end

# do something with 'results'
```

## Development

You can run the specs like this:

    crystal spec

## Contributing

1. Fork it ( https://github.com/akitaonrails/fiberpool/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Juan Wajnerman](https://github.com/waj) original implementation
- [AkitaOnRails](https://github.com/akitaonrails) creator of this shard, and maintainer
