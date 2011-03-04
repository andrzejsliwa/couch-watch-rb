# time ruby couch_watch_rb.rb
require 'lib/couch_watch'

sleep_time = 0.002
CouchWatch.server 'http://localhost:5984/couchwatch/_design/couchwatch/_update/logger'
CouchWatch.worker 3
(1..1000).each do |i|
  CouchWatch.add(:debug, "#{Time.now}, #{i}")
  sleep sleep_time
end
CouchWatch.close
