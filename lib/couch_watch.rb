require 'thread'
require 'net/http'
require 'uri'

# CouchWatch.server 'http://localhost:5984/couchwatch/_design/couchwatch/_update/logger'
# CouchWatch.workers 1
# CouchWatch.add(:debug, "#{Time.now}, #{i}")
# CouchWatch.workers 0

class CouchWatch
  @@mutex = Mutex.new
  @@store = []
  @@loggers = []
  @@server = nil
  @@counter = 0
  @@working = true

  def self.server server
    @@server = URI.parse(server)
  end

  def self.add severity, message
    workers(2) if @@loggers.length < 1
    @@mutex.synchronize { @@store.push [severity, message] }
  end

  def self.close
    workers(0)
    puts "count=#{@@counter}"
  end

  def self.workers amount=1
    (amount...@@loggers.length).each { finish_worker(  @@loggers.pop() ) }
    (@@loggers.length...amount).each { @@loggers.push( create_worker() ) }
  end

  def self.flush
    @@loggers[0].run if @@loggers[0]
  end

  private

  def self.create_worker
    Thread.new do
      Thread.current[:working] = true
      while Thread.current[:working] || @@store.length > 0 do
        @@mutex.synchronize do
          #puts "#{Thread.current.inspect} awaiting #{@@store.length}" if (@@store.length > 1)
          if (@@store.length > 0)
            severity, message = @@store.shift()
            Net::HTTP.post_form(@@server, { "severity" => severity, "message" => message })
            @@counter +=1
          end
        end
        sleep 0.001 #wait 1ms
      end
      @@mutex.synchronize do
        @@store.clear if (@@store.length > 0)
      end
    end
  end

  def self.finish_worker worker
    worker[:working] = false
    worker.join
  end
end
