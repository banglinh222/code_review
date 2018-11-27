namespace :db do
  desc 'Check step same number step'

  task :check_step_same_number_step, [:fix] => :environment do |t, args|
    logger = Logger.new("#{Rails.root}/log/check_step_same_number_step.log")
    wfs = WorkFollow.all.includes(:work_follow_steps, :shop)
    p "Total WF: #{wfs.size}"
    total = 0
    fixed = 0
    logger.info 'company_code,staff_code,wf_id,step_numbers_before,step_numbers_after'
    wfs.each do |wf|
      steps = wf.work_follow_steps
      next if steps.size < 2
      step_numbers = steps.map(&:step_number)
      next if step_numbers.uniq.size == step_numbers.size
      shop = wf.shop
      info = "#{shop.company.company_code},#{shop.name},#{wf.id},#{step_numbers},"
      total += 1
      if args.fix
        steps.to_a.sort_by { |obj| [obj.step_number, obj.created_at] }.each_with_index do |s, idx|
          s.set(step_number: idx + 1)
        end
        info << "#{steps.map(&:step_number)}"
        fixed += 1
      end
      logger.info info
    end
    p "TOTAL: #{total}"
    p "FIXED: #{fixed}"
  end
end
