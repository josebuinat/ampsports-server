require 'rails_helper'

describe Settings::Interface do
  subject { described_class.new(owner, settings_scope, settings_config) }

  let(:owner) { create :user }
  let(:settings_scope) { 'mailing' }
  let(:settings_config) do
    {
      receipts: false,
      cancellation: 'always',
      updates: 11,
    }
  end

  context 'with invalid params' do
    context 'with invalid scope' do
      let(:settings_scope) { '' }
      it 'throws scope error' do
        expect{ subject }.to raise_error(Settings::Error).
                                with_message(I18n.t('errors.settings.invalid_scope'))
      end
    end

    context 'with invalid config' do
      let(:settings_config) { {} }
      it 'throws scope error' do
        expect{ subject }.to raise_error(Settings::Error).
                                with_message(I18n.t('errors.settings.invalid_scope'))
      end
    end

    context 'with invalid owner' do
      let(:owner) { nil }
      it 'throws owner error' do
        expect{ subject }.to raise_error(Settings::Error).
                                with_message(I18n.t('errors.settings.invalid_owner'))
      end
    end

    context 'with non persisting owner' do
      let(:owner) { build :user }
      it 'throws owner error' do
        expect{ subject }.to raise_error(Settings::Error).
                                with_message(I18n.t('errors.settings.invalid_owner'))
      end
    end
  end

  describe '#get' do
    it 'returnes a defaut boolean value' do
      expect(subject.get(:receipts)).to eq false
    end

    it 'returnes a defaut string value' do
      expect(subject.get(:cancellation)).to eq 'always'
    end

    it 'returnes a set value with correct bolean type' do
      expect{ Setting.create(owner: owner, name: 'mailing_receipts', value: true) }
        .to change{ Setting.count }.by(1)
        .and change{ subject.reload.get(:receipts) }.from(false).to(true)
    end

    it 'returnes a set value with correct integer type' do
      expect{ Setting.create(owner: owner, name: 'mailing_updates', value: 14) }
        .to change{ Setting.count }.by(1)
        .and change{ subject.reload.get(:updates) }.from(11).to(14)
    end

    it 'throws name error if setting name is unknown' do
      expect{ subject.get(:unknown_something) }
        .to raise_error(Settings::Error).
              with_message(I18n.t('errors.settings.invalid_name'))
    end
  end

  describe '#put' do
    it 'saves a value' do
      expect{ subject.put(:receipts, true) }
        .to change{ Setting.count }.by(1)
        .and change{ subject.get(:receipts) }.from(false).to(true)
    end

    it 'updates saved value' do
      subject.put(:receipts, true)
      expect{ subject.put(:receipts, false) }
        .to do_not_change{ Setting.count }
        .and change{ subject.get(:receipts) }.from(true).to(false)
    end

    it 'returns true if setting saved' do
      expect(subject.put(:receipts, false)).to be_truthy
    end

    it 'returns false if setting can not be saved' do
      expect(subject.put(:receipts, nil)).to be_falsey
    end

    it 'throws name error if setting name is unknown' do
      expect{ subject.put(:unknown_something, true) }
        .to raise_error(Settings::Error).
              with_message(I18n.t('errors.settings.invalid_name'))
    end
  end

  describe '#list' do
    it 'returns list of settings' do
      expect(subject.list).to eq settings_config.map { |k,v| { name: k.to_s, value: v } }
    end
  end

  describe Settings do
    let(:user) { create :user }

    subject { user.settings(:email_notifications) }

    describe '#settings' do
      it 'returns valid settings interface object' do
        expect{ subject }.not_to raise_error
        is_expected.to be_kind_of Settings::Interface
        expect(subject.get(:reservation_receipts)).to be_truthy
      end
    end

    describe '#has_settings?' do
      it 'returns true if model class has a settings scope' do
        expect(User).to have_settings :email_notifications
        expect(User).to have_settings 'email_notifications'
      end
      it 'returns false if model class does not have a settings scope' do
        expect(User).not_to have_settings :notifications
        expect(User).not_to have_settings 'notifications'
      end
    end

    describe 'dependent destroy' do
      it 'deletes settings with owner' do
        subject.put(:reservation_receipts, false)
        subject.put(:reservation_cancellations, false)
        expect{ user.destroy }.to change { Setting.count }.by(-2)
      end
    end
  end
end
