# time ruby lib/couch_watch.rb
require 'thread'
require 'net/http'
require 'uri'

class CouchWatch
  @@mutex = Mutex.new
  @@store = []
  @@loggers = []
  @@server = nil
  @@counter = 0
  @@working = true

  def self.worker amount=1
    (0..amount-1).each do
      @@loggers.push(Thread.new do
        while @@working || @@store.length > 0 do
          if @@store.length > 0
            @@mutex.synchronize do
              @@store.each {|severity, message|
                Net::HTTP.post_form(@@server, { "severity" => severity, "message" => message })
                @@counter +=1
              }
              @@store.clear
            end
          end
          sleep 0.001 #wait 1ms
        end
      end)
    end
  end

  def self.add severity, message
    CouchWatch.worker 2 if @@loggers.length < 1
    @@mutex.synchronize do
      @@store.push [severity, message]
    end
  end
  def self.flush
    #TODO: replace dead threads with new ones
    @@loggers[0].run if @@loggers[0]
  end
  def self.close
    #TODO: replace dead threads with new ones
    @@working = false
    flush
    @@loggers.map{|l| l.join}
    puts "count=#{@@counter}"
  end
  def self.server server
    @@server = URI.parse(server)
  end
end

CouchWatch.server 'http://localhost:5984/couchwatch/_design/couchwatch/_update/logger'
CouchWatch.worker 3
(1..1000).each do |i|
  CouchWatch.add(:debug, "#{Time.now}, #{i}")
  Thread.pass
end
CouchWatch.close
