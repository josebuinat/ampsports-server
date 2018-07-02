class AddBookingMailCopyToCompany < ActiveRecord::Migration
  def change
    add_column :companies, :copy_booking_mail_to, :string
  end
end
