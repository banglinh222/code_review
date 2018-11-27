def fix_old_rounded_format(time_cards)
  all_tc = Marshal.load(Marshal.dump(time_cards.to_a)).to_a
  all_tc.each { |tc| tc.breaks_for_old_rounded_format ||= tc.breaks.to_a }
  normal_tc, no_checkout_tc = all_tc.partition { |tc| tc.time_out.present? }
  main_tc = all_tc.find { |tc| HandleTimecardHistory.live?(tc) }
  merge_tc(normal_tc, main_tc) + no_checkout_tc
end

def merge_tc(time_cards, main_tc)
  return time_cards if time_cards.size < 2 || main_tc.blank?
  base_tc = time_cards[0]
  next_tc = time_cards[1]
  if (base_tc.time_out == next_tc.time_attend || base_tc.time_out + 1.minute == next_tc.time_attend) && base_tc.user_shop_id == next_tc.user_shop_id
    main_tc.time_attend = base_tc.time_attend
    main_tc.time_out = next_tc.time_out
    next_tc.breaks_for_old_rounded_format.each do |br|
      break_count = base_tc.breaks_for_old_rounded_format.count { |b| b.type.zero? }
      br.index += break_count
    end
    main_tc.breaks_for_old_rounded_format += next_tc.breaks_for_old_rounded_format
    time_cards.slice!(0, 2)
    time_cards.unshift(main_tc)
    merge_tc(time_cards, main_tc)
  else
    [time_cards.shift] + merge_tc(time_cards, main_tc)
  end
end