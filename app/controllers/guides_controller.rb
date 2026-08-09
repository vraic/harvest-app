class GuidesController < ApplicationController
  allow_unauthenticated_access

  before_action :load_guides_repository
  before_action :set_query

  def index
    @search_results = perform_search
  end

  def show
    @guide = @guides_repository.find(params[:slug])
    raise ActiveRecord::RecordNotFound if @guide.blank?

    @related_guides = @guides_repository.related_documents(@guide)
    @search_results = perform_search
  end

  private

    def load_guides_repository
      @guides_repository = Guides::Repository.new
      @guides = @guides_repository.all
      @guide_sections = @guides_repository.sections
    end

    def set_query
      @query = params[:q].to_s.strip
    end

    def perform_search
      return [] if @query.blank?

      @guides_repository.search(@query).first(20)
    end
end
