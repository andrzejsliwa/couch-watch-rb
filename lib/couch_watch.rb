# time ruby -e "require 'lib/couch_watch' ; CouchWatch.server 'http://localhost:5984/couchwatch/_design/couchwatch/_update/logger' ; (1..1000).each {|i| CouchWatch.add(:debug, \"#{Time.now}, #{i}\"); Thread.pass }; CouchWatch.flush"
require 'thread'
require 'net/http'
require 'uri'

class CouchWatch
  @@mutex = Mutex.new
  @@store = []
  @@loggers = []
  @@server = nil

  def self.worker amount=1
    (0..amount-1).each do
      @@loggers.push(Thread.new do
        loop do
          @@mutex.synchronize do
            if @@store.length > 0
              @@store.each {|severity, message|
                Net::HTTP.post_form(@@server, { "severity" => severity, "message" => message })
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
  def self.server server
    @@server = URI.parse(server)
  end
end
