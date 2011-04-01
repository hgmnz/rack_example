class IpThrottler
  REQUESTS_PER_MINUTE = 5
  def initialize(app)
    @app = app
  end

  def call(env)
    if self.class.restrict?(env["REMOTE_ADDR"])
      body = "You've been blocked for hitting us #{self.class.current_count_for(env["REMOTE_ADDR"])} times"
      [200, {'Content-Type' => 'text/plain', 'Content-Length' => body.length.to_s}, [body]]
    else
      @app.call(env)
    end
  end

  private

  cattr_accessor :cache
  self.cache = Dalli::Client.new("127.0.0.1:11211")

  def self.restrict?(ip_address)
    begin
      track(ip_address)
      current_count_for(ip_address) > REQUESTS_PER_MINUTE
    rescue Dalli::RingError
      false
    end
  end

  def self.current_count_for(ip_address)
    (cache.get(ip_address) || 0).to_i
  end

  def self.track(ip_address)
    cache.add(ip_address, "0", 1.minute.from_now.to_i, :raw => true) unless cache.get(ip_address)
    cache.incr(ip_address)
  end

end
