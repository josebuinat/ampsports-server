class Admin::Companies::NotesController < Admin::BaseController
  def show
    note
  end

  def update
    if note.update_attributes update_params
      render 'show'
    else
      render json: { errors: note.errors }, status: :unprocessable_entity
    end
  end

  private

  def update_params
    params.require(:note).permit(:text).merge(last_edited_by: current_admin).permit!
  end

  def note
    @note ||= current_admin.company.note || current_admin.company.create_note!
  end
end