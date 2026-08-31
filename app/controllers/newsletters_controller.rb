class NewslettersController < ApplicationController
  before_action :set_newsletter, only: %i[ show edit update destroy deliver ]
  before_action :ensure_not_sent, only: %i[ edit update destroy deliver ]

  def index
    @newsletters = Newsletter.all
    if params[:target].present?
      @newsletters = @newsletters.where(target: params[:target])
    end
  end

  def report
    @sent_newsletters = Newsletter.where.not(sent_at: nil).order(sent_at: :desc)
    @total_sent = Ahoy::Message.where(newsletter_id: @sent_newsletters.select(:id)).count
    @total_opened = Ahoy::Message.where(newsletter_id: @sent_newsletters.select(:id)).where.not(opened_at: nil).count
    @total_clicked = Ahoy::Message.where(newsletter_id: @sent_newsletters.select(:id)).where.not(clicked_at: nil).count
  end

  def show
    @messages = @newsletter.messages.includes(:user).order(sent_at: :desc)
    @pagy, @messages = pagy(@messages) if defined?(Pagy)
  end

  def new
    @newsletter = Newsletter.new
  end

  def edit
  end

  def create
    @newsletter = Newsletter.new(newsletter_params)

    if @newsletter.save
      redirect_to @newsletter, notice: "Newsletter created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @newsletter.update(newsletter_params)
      redirect_to @newsletter, notice: "Newsletter updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @newsletter.destroy
    redirect_to newsletters_url, notice: "Newsletter deleted"
  end

  def deliver
    NewsletterDeliveryJob.perform_later(@newsletter)
    @newsletter.update(sent_at: Time.current)
    redirect_to @newsletter, notice: "Delivery started"
  end

  private

  def set_newsletter
    @newsletter = Newsletter.find(params[:id])
  end

  def ensure_not_sent
    if @newsletter.sent?
      redirect_to @newsletter, alert: "Already sent"
    end
  end

  def newsletter_params
    params.require(:newsletter).permit(:subject, :content, :target)
  end
end
