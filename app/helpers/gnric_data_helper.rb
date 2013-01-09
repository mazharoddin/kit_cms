module GnricDataHelper

  def calendar_entry(id)
    entry = CalendarEntry.find_sys_id(_sid, id)
    entry = nil if entry.approved_at == nil && !can?(:moderate, :calendar)

    return entry
  end

end
