class ChangeIsBilledFromBooleanToEnum < ActiveRecord::Migration
  def up
    add_column :game_passes, :billing_phase, :integer, default: GamePass.billing_phases[:not_billed]
    bool_to_int
    remove_column :game_passes, :is_billed, :boolean
  end

  def down
    add_column :game_passes, :is_billed, :boolean
    int_to_bool
    remove_column :game_passes, :billing_phase, :integer
  end

  private

  def bool_to_int
    not_billed = GamePass.where(is_billed: false).where('id NOT IN (SELECT DISTINCT(game_pass_id) FROM gamepass_invoice_components)')
    say "not billed count: #{not_billed.count}"
    drafted = GamePass.where(is_billed: false).where('id IN (SELECT DISTINCT(game_pass_id) FROM gamepass_invoice_components)')
    say "drafted count: #{drafted.count}"
    billed = GamePass.where(is_billed: true)
    say "billed count: #{billed.count}"
    not_billed.update_all(billing_phase: GamePass.billing_phases[:not_billed]) # :not_billed
    say "not billed phase set..."
    drafted.update_all(billing_phase: GamePass.billing_phases[:drafted]) # :drafted
    say "drafted phase set..."
    billed.update_all(billing_phase: GamePass.billing_phases[:billed]) # :billed
    say "billed phase set..."
  end

  def int_to_bool
    not_billed = GamePass.where(billing_phase: [GamePass.billing_phases[:not_billed],
                                                GamePass.billing_phases[:drafted]]) # not_billed, drafted
    say "not billed count: #{not_billed.count}"
    billed = GamePass.billed # billed
    say "billed count: #{billed.count}"
    not_billed.update_all(is_billed: false)
    say "not billed set..."
    billed.update_all(is_billed: true)
    say "billed set..."
  end
end
