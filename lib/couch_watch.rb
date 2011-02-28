# time ruby -e "require 'lib/couch_watch' ; (0..4).each { CouchWatch.new } ; (1..500).each {|i| CouchWatch.add i; Thread.pass }; CouchWatch.flush"
require 'thread'

class CouchWatch
  @@mutex = Mutex.new
  @@store = []
  @@loggers = []

  def initialize amount=1
    (0..amount-1).each do
      @@loggers.push(Thread.new do
        loop do
          @@mutex.synchronize do
            if @@store.length > 0
              #puts " ------- #{@@store*', '}"
              @@store.each {|message|
                s = "#{message}2"
              }
              @@store.clear
            end
          end
          sleep 0.001 #wait 1ms
        end
      end)
    end
  end

  def self.add message
    CouchWatch.new 2 if @@loggers.length < 1
    @@mutex.synchronize do
      @@store.push message
    end
  end
  def self.flush
    #TODO: replace dead threads with new ones
    @@loggers[0].run if @@loggers[0]
  end
end
