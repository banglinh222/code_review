def fix_old_rounded_format(time_cards)
  combined_time_cards = Marshal.load(Marshal.dump(time_cards.to_a)).to_a
  combined_time_cards.each do |tc|
    tc.breaks_for_old_rounded_format ||= tc.breaks.to_a
  end
  time_cards.count.times do
    combined_time_cards.each_with_index do |time_card, idx|
      # combined_time_cards.each do |time_card_target|
      time_card_target = combined_time_cards[idx + 1]
      next if time_card_target.blank? || time_card == time_card_target
      next if time_card.time_out.blank? ||
              ((time_card.time_out + 1.minute) != time_card_target.time_attend &&
              time_card.time_out != time_card_target.time_attend)

      # conbine two time_cards
      combined_time_cards[idx].time_out = time_card_target.time_out

      # unite breaks into breaks_for_old_rounded_format
      breaks = []
      timecard_old_break = time_card.breaks_for_old_rounded_format
      target_timecard_old_break = time_card_target.breaks_for_old_rounded_format

      # if timecard_old_break is nil then take breaks from break collection
      breaks = timecard_old_break || time_card.breaks.to_a
      if target_timecard_old_break.present?
        target_timecard_old_break.each do |bkt|
          lastest_index = breaks.count { |b| b.type.zero? }
          bkt.index = bkt.index + lastest_index
        end
        breaks += target_timecard_old_break
      else
        time_card_target.breaks.each do |bkt|
          next if bkt.break.blank? || bkt.return.blank?
          lastest_index = breaks.count { |b| b.type.zero? }
          new_break = Break.new(index: lastest_index + 1, break: bkt.break, return: bkt.return, type: bkt.type)
          breaks.push(new_break)
        end
      end
      time_card.breaks_for_old_rounded_format = breaks
      combined_time_cards.delete(time_card_target)
    end
  end
  combined_time_cards
end