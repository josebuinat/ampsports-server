class CreateUserSocialAccounts < ActiveRecord::Migration
  def change
    create_table :user_social_accounts do |t|
      t.belongs_to :user, index: true
      t.string :provider
      t.string :uid
    end

    add_index :user_social_accounts, [:uid, :provider]

    User::SocialAccount.reset_column_information
    
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          if user.provider.present?
            user.social_accounts.create! provider: user.provider, uid: user.uid
          end
        end
      end

      dir.down do
        # will lose data if 1 user has 2 social accounts
        User::SocialAccount.find_each do |social_account|
          social_account.user.update_column :provider, social_account.provider
          social_account.user.update_column :uid, social_account.uid
        end
      end
    end

    remove_column :users, :provider, :string
    remove_column :users, :uid, :string
  end
end
