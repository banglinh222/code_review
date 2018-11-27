namespace :db do
  desc 'Fake email - set to temp_address+index@gmail.com'
  task fake_email: :environment do
    users = User.all
    count = 0
    users.each do |user|
      next if user.email.blank?
      company = user.company
      next if company.blank? || company.company_code.to_i >= 900_000
      count += 1
      email = "temp_address+#{count}@gmail.com"
      user.set(email: email)
      puts count
      p idx
    end
  end
end
