module Admin
  class LegalController < BaseController
    DETAILS = %i[company_name company_id vat_number address email phone].freeze

    def edit
      @legal = LegalInfo.instance
    end

    def update
      @legal = LegalInfo.instance
      attrs = DETAILS.index_with { |f| params[f].to_s.strip }
      LegalInfo::PAGES.each_value { |page| attrs[page[:column]] = params[page[:column]].to_s }
      @legal.update(attrs)
      redirect_to edit_admin_legal_path, notice: "Saved"
    end
  end
end
