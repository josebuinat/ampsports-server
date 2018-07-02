module ControllerMacros
  def login_admin
    before(:each) do
      sign_in FactoryGirl.create(:admin)
    end
  end
end
