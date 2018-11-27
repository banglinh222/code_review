namespace :db do
  desc 'Fake email - set kintai.prod.email+{index}@gmail.com'
  task fake_email: :environment do
    company_ids = Company.where('$where' => 'this.company_code < 900000').pluck(:id)
    users = User.where(:company_id.in => company_ids).where('$where' => 'this.email')
    users.each_with_index do |user, idx|
      email = "kintai.prod.email+#{idx}@gmail.com"
      user.set(email: email)
      p idx
    end
  end
end
