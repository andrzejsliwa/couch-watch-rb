# time ruby couch_watch_rb.rb

require 'lib/couch_watch'

sleep_time = 0.002 #delay 2ms to not do all at once
CouchWatch.server 'http://localhost:5984/couchwatch/_design/couchwatch/_update/logger'
CouchWatch.workers 3 #work with three workers
(1..1000).each do |i|
  CouchWatch.add(:debug, "#{Time.now}, #{i}")
  sleep sleep_time #could be also Thread.pass
end
CouchWatch.close #displays count, but "CouchWatch.workers 0" does the same job
