class AthleteQuery < ApplicationQuery
  def initialize(params = {}, relation = Athlete.all)
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
    q[:first_name_or_last_name_cont] = @params[:q] if @params[:q].present?
    q[:country_code_eq]              = @params[:country] if @params[:country].present?
    q
  end
end
