# bundle exec rake db:fix_shop_id_wf_step['true']
namespace :db do
  desc '10740_fix_shop_id_wf_step'

  task :fix_shop_id_wf_step_10740, [:fix] => :environment do |t, args|
    p 'START'
    logger = Logger.new("#{Rails.root}/log/10740_fix_shop_id_wf_step.log")
    logger.info "company_code,wf_id,old_shop_id,new_shop_id,request_type"
    time = Time.current
    fix = args.fix.present?
    count = 0
    result = []
    shift_rq_steps = RequestWorkflowStep.where(request_type: 'request_shift')
    tc_rq_steps = RequestWorkflowStep.where(:request_type.in => ['request_fix_and_create_time_card', 'request_over_times', 'request_timecard'])
    con_rq_steps = RequestWorkflowStep.where(:request_type.in => ['request_work_change', 'request_work_recoup'])
    over_rq_steps = RequestWorkflowStep.where(request_type: 'request_pre_over_times')
    dayoff_rq_steps = RequestWorkflowStep.where(request_type: 'request_day_off')

    [shift_rq_steps, tc_rq_steps, con_rq_steps, over_rq_steps, dayoff_rq_steps].each_with_index do |request_wfs, idx|
    # [shift_rq_steps].each_with_index do |request_wfs, idx|
      request_wfs = request_wfs.only(:id, :request_id, :shop_id)
      ids = request_wfs.map(&:request_id)
      bad_wfs = []
      all_requests = if idx.zero?
                       p "search for bad shift wfs"
                       Shift.where(:id.in => ids)
                     elsif idx == 1
                       p "search for bad tc wfs"
                       TimeCard.out_default_scope.where(:id.in => ids)
                     elsif idx == 2
                       p "search for bad conversion wfs"
                       ConversionDay.where(:id.in => ids)
                     elsif idx == 3
                       p "search for bad overtime wfs"
                       OverTime.where(:id.in => ids)
                     else
                       p "search for bad day off wfs"
                       RequestDayOff.where(:id.in => ids)
                     end
      all_requests = all_requests.pluck(:shop_id, :id).group_by { |rq| rq.first }
      request_wfs.group_by { |rwfs| rwfs.shop_id }.each do |wfs_shop_id, wfs_array|
        requests = all_requests.find { |k, v| k == wfs_shop_id }
        bad_wfs += wfs_array and next if requests.blank?
        request_ids = requests.second.map(&:second)
        wfs_array.each do |wfs|
          bad_wfs << wfs unless request_ids.include?(wfs.request_id)
        end
      end
      result << bad_wfs
    end
    result.each_with_index do |bad_els, idx|
      collection = if idx.zero?
                    p 'start fixing wfs shift'
                    suffix = 'shift request'
                    Shift.unscoped
                  elsif idx == 1
                    p 'start fixing wfs tc'
                    suffix = 'timecard request'
                    TimeCard.out_default_scope
                  elsif idx == 2
                    p 'start fixing wfs conversion'
                    suffix = 'conversion request'
                    ConversionDay.unscoped
                  elsif idx == 3
                    p 'start fixing wfs overtime'
                    suffix = 'overtime request'
                    OverTime.unscoped
                  else
                    p 'start fixing wfs request day off'
                    suffix = 'day off request'
                    RequestDayOff.unscoped
                  end
      bad_els.each do |wfs|
        request_id = wfs.request_id
        request = collection.find(request_id)
        next if request.blank?
        user = request.user
        next if user.blank?
        count += 1
        old_shop_id = wfs.shop_id
        wfs.set(shop_id: request.shop_id) if fix
        company_code = user.company.company_code
        logger.info "#{company_code},#{wfs.id},#{old_shop_id},#{wfs.shop_id},#{suffix}"
      end
    end
    p "DONE: #{Time.current - time} seconds - updated total #{count} rwfs"
  end
end
