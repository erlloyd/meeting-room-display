class Calendar
  include ActionView::Helpers::DateHelper
  attr_accessor :calendar_id
  attr_accessor :events
  attr_accessor :location

  def initialize(calendar_data, events_data = nil)
    @location = calendar_data.try(:summary)
    @calendar_id = calendar_data.try(:id)

    if events_data.present?
      @events = events_data.items.map { |item| Event.new(self, item) }
    end
  end

  def as_json
    calendar_json = { name: location, calendar_id: calendar_id }
    calendar_json[:events] = events.map(&:as_json) if events.present?
    calendar_json
  end

  def description
    if in_use?
      attendees = current_meeting.attendees.to_sentence(last_word_connector: " and ")

      "This room is used by #{attendees} " \
        "until #{current_meeting.end_time.strftime("%H:%M")} " \
        "(#{time_left})"
    else
      "This room is available"
    end
  end

  def time_left
    if in_use?
      if current_meeting.all_day?
        "this meeting takes all day"
      else
        distance_of_time_in_words(Time.zone.now, current_meeting.end_time) + " left"
      end
    else
      sorted_events = @events.sort_by { |event| event.begin_time }
      next_event = sorted_events.detect { |event| event.begin_time > Time.zone.now }
      if next_event.present?
        distance_of_time_in_words(Time.zone.now, next_event.begin_time) + " left"
      else
        ""
      end
    end
  end

  def available?
    current_meeting.nil?
  end

  def in_use?
    !available?
  end

  def current_meeting
    @events.detect do |event|
      next if event.rejected

      event.all_day? ||
        Time.zone.now >= event.begin_time && Time.zone.now <= event.end_time
    end
  end
end
