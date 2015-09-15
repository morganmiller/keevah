class CategoriesController < ApplicationController
  def show
    @categories = Category.all
    @category = Category.find(params[:id])
    @loan_requests = @category.loan_requests.paginate(page: params[:page], per_page: 9)
  end
end
