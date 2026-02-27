class EventQuery < ApplicationQuery
  def initialize(params = {}, relation = Event.all)
    super()
    @params = params
    @relation = relation
  end

  def call
    @relation.ransack(ransack_params).result
  end

  private

  def ransack_params
    q = {}
    q[:season_id_eq]   = @params[:season_id] if @params[:season_id].present?
    q[:discipline_eq]  = Event.disciplines[@params[:discipline]]      if @params[:discipline].present?
    q[:status_eq]      = Event.statuses[@params[:status]]             if @params[:status].present?
    q[:season_year_eq] = @params[:year]                               if @params[:year].present?
    q
  end
end
