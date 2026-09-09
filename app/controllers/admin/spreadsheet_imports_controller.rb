module Admin
  class SpreadsheetImportsController < Admin::BaseController
    def index
      query = ::Admin::SpreadsheetImportsQuery.new(before_id: params[:before_id])

      render inertia: "admin/spreadsheet_imports/index", props: {
        imports: InertiaRails.scroll(query.metadata) { imports_json(query.records) }
      }
    end

    def create
      file = params[:file]

      if file.blank?
        redirect_to admin_spreadsheet_imports_path, inertia: { errors: { file: [ "can't be blank" ] } } and return
      end

      # Checked up front, before any SpreadsheetImport row exists, so an unsupported file
      # never leaves behind a pending import that will never be processed.
      Imports::ParserFactory.for(content_type: file.content_type, filename: file.original_filename, path: file.path)

      import = SpreadsheetImport.create!(admin: Current.user)
      import.file.attach(file)
      SpreadsheetImportJob.perform_later(import.id)

      # No dedicated status page anymore - the admin stays on the imports page, whose newest-
      # first history ordering already surfaces this import at imports.data[0]; the frontend
      # opens its progress modal from there. See design.md.
      redirect_to admin_spreadsheet_imports_path, notice: "Import started."
    rescue Imports::UnsupportedFormatError
      redirect_to admin_spreadsheet_imports_path, inertia: { errors: { file: [ "must be a CSV or XLSX file" ] } }
    end

    private
      # Layers filename/created_at onto summary_json, same pattern
      # Admin::UsersController#users_json uses over profile_json - summary_json itself stays the
      # one shape shared with every SpreadsheetImportChannel broadcast.
      def imports_json(imports)
        imports.map { |import| import.summary_json.merge(filename: import.file.filename.to_s, created_at: import.created_at) }
      end
  end
end
