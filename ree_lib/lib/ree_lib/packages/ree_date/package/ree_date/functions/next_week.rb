# frozen_string_literal: true

class ReeDate::NextWeek
  include Ree::FnDSL

  fn :next_week do
    link :today
    link :advance
  end

  doc("Short-hand for <tt>weeks_since(1)</tt>.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance(date || today, weeks: 1)
  end
end