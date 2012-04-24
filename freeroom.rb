require 'pp'
require 'time'
require 'open-uri'

class Room
  attr_accessor :roomnumber, :webid

  def initialize(roomnumber, webid)
    @roomnumber = roomnumber
    @webid      = webid
  end

  def to_s
    @roomnumber + ", " + @webid
  end
end

class Event
  attr_accessor :room, :starttime, :endtime

  def initialize(room, starttime, endtime)
      @room      = room
      @starttime = Time.parse(starttime)
      @endtime   = Time.parse(endtime)
  end

  #timediff

  def to_s
    @room.to_s + ", " + @starttime.to_s + " - " + @endtime.to_s
  end
end

class RoomsEvents
  attr_accessor :rooms, :events

  def initialize(formUrl, icalUrl)
      @rooms      = {}
      @events     = []
      load_rooms_from_timeedit(formUrl)
      load_events_from_timeedit(icalUrl)
  end

  def to_s
      @rooms.each { |o| print o.to_s}
      @events.each { |o| print o.to_s}
  end

  def find_room_by_room_number(roomnumber)
    found = nil
    @rooms.each_value do |r|
      found = r if r.roomnumber == roomnumber.to_str
    end
    found
  end

  def find_next_busy_room_number(roomnumber)
    now = Time.now
    found = nil
    @events.each do |e|
      found = e if e.room.roomnumber == roomnumber.to_str && e.starttime > Time.now
    end
    found
  end

private
  def fetch_and_parse_uri(url, reg)
    open(url).read.scan(reg)
  end

  def buildUrl(url)
    t = Time.now

    url += "&from=" + t.strftime("%y%W")
    url += "&to=" + (t + 60*60*24*7*3).strftime("%y%W")

    i = 1
    @rooms.each_value do |r|
      url += "&id" + i.to_s + "=" + r.webid
      i = i + 1
    end
    url
  end

  def load_rooms_from_timeedit(url)
    fetch_and_parse_uri(url,/addObject\((\d+)\).*?colspan='3'>Pol_(\d+)/m).each do |r|
        @rooms[r[1].to_i] = Room.new(r[1], r[0]);
    end
    #pp @rooms
  end

  def load_events_from_timeedit(url)
    r = /BEGIN:VEVENT.*?DTSTART;(.*?)\nDTEND;(.*?)\n.*?LOCATION:Pol_(\d+).*?END:VEVENT/m
    @events = fetch_and_parse_uri(buildUrl(url),r).collect {|e| Event.new(rooms[e[2].to_i], e[0], e[1])}.sort{|a,b| b.starttime <=> a.starttime}    
  end
end

formUrl = "http://schema.angstrom.uu.se/4DACTION/WebShowSearch/" \
          "2/1-0?wv_type=8&wv_category=0&wv_search=pol"

# Will need &id1=#1roomid ... &idN=#Nroomid
# Will also need &from=1021&to=1023 where format is YYWW
icalUrl = "http://schema.angstrom.uu.se/4DACTION/iCal_downloadReservations/" \
          "timeedit.ics?branch=2&lang=1"
# Main program
puts "Loading schedule..."
shit = RoomsEvents.new(formUrl, icalUrl)
puts "Valid room number e.g: 1146"
while(true)
  print "Enter room number: "
  nr = gets.chomp
  if shit.find_room_by_room_number(nr) == nil
    puts "No such room."
  else
    o = shit.find_next_busy_room_number nr
    if o == nil
      puts "It's free forever."
    else
      puts "It's free until #{o.starttime}"
    end
  end
end
