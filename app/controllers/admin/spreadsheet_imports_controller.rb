module Admin
  class SpreadsheetImportsController < Admin::BaseController
    before_action :set_import, only: :show

    def new
      render inertia: "admin/spreadsheet_imports/new"
    end

    def create
      file = params[:file]

      if file.blank?
        redirect_to new_admin_spreadsheet_import_path, inertia: { errors: { file: [ "can't be blank" ] } } and return
      end

      # Checked up front, before any SpreadsheetImport row exists, so an unsupported file
      # never leaves behind a pending import that will never be processed.
      Imports::ParserFactory.for(content_type: file.content_type, filename: file.original_filename, path: file.path)

      import = SpreadsheetImport.create!(admin: Current.user)
      import.file.attach(file)
      SpreadsheetImportJob.perform_later(import.id)

      redirect_to admin_spreadsheet_import_path(import), notice: "Import started."
    rescue Imports::UnsupportedFormatError
      redirect_to new_admin_spreadsheet_import_path, inertia: { errors: { file: [ "must be a CSV or XLSX file" ] } }
    end

    def show
      render inertia: "admin/spreadsheet_imports/show", props: { import: @import.summary_json }
    end

    private
      def set_import
        @import = SpreadsheetImport.find(params[:id])
      end
  end
end
