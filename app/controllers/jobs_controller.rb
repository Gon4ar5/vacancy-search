class JobsController < ApplicationController
  def index
    @jobs = Job.order(created_at: :desc)
  end

  def show
    @job = Job.find(params[:id])
  end

  def new
    @job = Job.new
  end

  def create
    @job = Job.new(job_params)

    if @job.save
      redirect_to @job
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def job_params
    params.require(:job).permit(
      :title, :company_name, :source, :source_url, :description, :published_at, :external_id
    )
  end
end
