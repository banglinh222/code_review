namespace :db do
  desc 'jinjer_10740_fix_shop_id_wf_step'

  task :jinjer_10740_fix_shop_id_wf_step, [:fix] => :environment do |t, args|
    p 'START'
    logger = Logger.new("#{Rails.root}/log/jinjer_10740_fix_shop_id_wf_step.log")
    time = Time.current
    fix = args.fix.present?
    count = 0
    shift_rq_steps = RequestWorkflowStep.where(request_type: 'request_shift').only(:id, :request_id, :shop_id).to_a
    tc_rq_steps = RequestWorkflowStep.where(:request_type.in => ['request_fix_and_create_time_card', 'request_over_times', 'request_timecard']).only(:id, :request_id, :shop_id).to_a
    con_rq_steps = RequestWorkflowStep.where(:request_type.in => ['request_work_change', 'request_work_recoup']).only(:id, :request_id, :shop_id).to_a
    over_rq_steps = RequestWorkflowStep.where(request_type: 'request_pre_over_times').only(:id, :request_id, :shop_id).to_a
    dayoff_rq_steps = RequestWorkflowStep.where(request_type: 'request_day_off').only(:id, :request_id, :shop_id).to_a

    p "Total steps: #{shift_rq_steps.size}"
    logger.info 'company_code,staff_code,rwfs_id,request_id,old_shop_id,new_shop_id,type'

    Parallel.each_with_index(shift_rq_steps, in_threads: 5) do |rqs, i|
      puts i
      rq = Shift.unscoped.find(rqs.request_id)
      if rq.present? && rq.shop_id != rqs.shop_id
        print '.'
        count += 1
        user = rq.user
        company = user.company if user
        next if company.blank?
        logger.info "#{company.company_code},#{user.staff_code},#{rqs.id},#{rqs.request_id},#{rqs.shop_id},#{rq.shop_id},request_shift"
        rqs.set(shop_id: rq.shop_id) if fix
      end
    end
    Parallel.each_with_index(over_rq_steps, in_threads: 5) do |rqs, i|
      rq = OverTime.unscoped.find(rqs.request_id)
      if rq.present? && rq.shop_id != rqs.shop_id
        print '.'
        count += 1
        user = rq.user
        company = user.company if user
        next if company.blank?
        logger.info "#{company.company_code},#{user.staff_code},#{rqs.id},#{rqs.request_id},#{rqs.shop_id},#{rq.shop_id},overtime"
        rqs.set(shop_id: rq.shop_id) if fix
      end
    end
    Parallel.each_with_index(tc_rq_steps, in_threads: 5) do |rqs, i|
      rq = TimeCard.unscoped.unscoped.find(rqs.request_id)
      if rq.present? && rq.shop_id != rqs.shop_id
        print '.'
        count += 1
        user = rq.user
        company = user.company if user
        next if company.blank?
        logger.info "#{company.company_code},#{user.staff_code},#{rqs.id},#{rqs.request_id},#{rqs.shop_id},#{rq.shop_id},timecard"
        rqs.set(shop_id: rq.shop_id) if fix
      end
    end
    Parallel.each_with_index(con_rq_steps, in_threads: 5) do |rqs, i|
      rq = ConversionDay.unscoped.find(rqs.request_id)
      if rq.present? && rq.shop_id != rqs.shop_id
        print '.'
        count += 1
        user = rq.user
        company = user.company if user
        next if company.blank?
        logger.info "#{company.company_code},#{user.staff_code},#{rqs.id},#{rqs.request_id},#{rqs.shop_id},#{rq.shop_id},conversion"
        rqs.set(shop_id: rq.shop_id) if fix
      end
    end
    Parallel.each_with_index(dayoff_rq_steps, in_threads: 5) do |rqs, i|
      rq = RequestDayOff.unscoped.find(rqs.request_id)
      if rq.present? && rq.shop_id != rqs.shop_id
        print '.'
        count += 1
        user = rq.user
        company = user.company if user
        next if company.blank?
        logger.info "#{company.company_code},#{user.staff_code},#{rqs.id},#{rqs.request_id},#{rqs.shop_id},#{rq.shop_id},requestdayoff"
        rqs.set(shop_id: rq.shop_id) if fix
      end
    end
    p "DONE: #{Time.current - time} seconds - updated total #{count} rwfs"
  end
end
