task :check_step_same_number_step, [:fix] => :environment do |t, args|
  logger = Logger.new("#{Rails.root}/log/check_step_same_number_step.log")
  wfs = WorkFollow.all.includes(:work_follow_steps, :shop)
  p "Total WF: #{wfs.count}"
  count = 0
  logger.info 'company_code,staff_code,wf_id,step_numbers'
  wfs.each do |wf|
    print '.'
    steps = wf.work_follow_steps
    s_count = steps.count
    next if s_count < 2
    step_numbers = steps.pluck(:step_number)
    next if step_numbers.uniq.size == step_numbers.size
    shop = wf.shop
    info = "#{shop.company.company_code},#{shop.name},#{wf.id},#{step_numbers}"
    logger.info info
    puts info
    count += 1
    next unless args.fix == 'true'
    steps.to_a.sort_by { |obj| [obj.step_number, obj.created_at] }.each_with_index do |s, idx|
    s.set(step_number: idx + 1)
  end
end