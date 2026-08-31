class SupportRequestCommentsController < ApplicationController
  before_action :set_support_request
  before_action :set_comment, only: %i[ update ]

  def create
    @comment = @support_request.comments.new(comment_params)
    @comment.user = Current.user
    @comment.account = @support_request.account

    authorize @comment

    if @comment.save
      redirect_to @support_request, notice: "Comment added"
    else
      redirect_to @support_request, alert: "Comment failed"
    end
  end

  def update
    authorize @comment
    if @comment.update(comment_params)
      redirect_to @support_request, notice: "Comment updated"
    else
      redirect_to @support_request, alert: "Update failed"
    end
  end

  private

  def set_support_request
    @support_request = SupportRequest.find(params[:support_request_id])
  end

  def set_comment
    @comment = @support_request.comments.find(params[:id])
  end

  def comment_params
    params.require(:support_request_comment).permit(:body)
  end
end
