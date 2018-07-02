shared_examples "loggable activity" do |activity_type|
  it 'saves record in activiy log' do
    expect{ subject }.to change { ActivityLog.count }.by(1)
    expect(ActivityLog.last.activity_type.to_s).to eq(activity_type)
  end
end


def create_activity_logs(company)
  activity_log = FactoryGirl.build(:reservation_activity_log,
                                    :with_user,
                                    company: company
                                  )
  build_details_and_save(activity_log)

  activity_log_2 = FactoryGirl.build(:membership_activity_log,
                                      :with_admin,
                                      company: company
                                    )
  build_details_and_save(activity_log_2)

  activity_log_3 = FactoryGirl.build(:invoice_activity_log,
                                      :with_admin,
                                      company: company
                                    )
  build_details_and_save(activity_log_3)
end

def build_details_and_save(activity_log)
  activity_log.build_payload_details
  activity_log.save
end
