# Streams one SpreadsheetImport's progress. Authorization mirrors
# Admin::SpreadsheetImportsController#show exactly: any admin, not only the import's owner.
class SpreadsheetImportChannel < ApplicationCable::Channel
  def subscribed
    import = SpreadsheetImport.find_by(id: params[:id])

    reject and return unless import && current_user&.admin?

    stream_for import
  end
end
