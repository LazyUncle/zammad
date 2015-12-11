# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Observer::Sla::TicketRebuildEscalation < ActiveRecord::Observer
  observe 'sla'

  def after_create(record)
    _rebuild(record)
  end

  def after_update(record)
    _check(record)
  end

  def after_delete(record)
    _rebuild(record)
  end

  private

  def _rebuild(record)
    Cache.delete('SLA::List::Active')

    # send background job
    Delayed::Job.enqueue( Observer::Sla::TicketRebuildEscalation::BackgroundJob.new(record.id) )
  end

  def _check(record)

    # return if we run import mode
    return if Setting.get('import_mode') && !Setting.get('import_ignore_sla')

    # check if condition has changed
    changed = false
    %w(condition calendar_id first_response_time update_time solution_time).each {|item|
      next if !record.changes[item]
      next if record.changes[item][0] == record.changes[item][1]
      changed = true
    }
    return if !changed

    _rebuild(record)
  end

end
