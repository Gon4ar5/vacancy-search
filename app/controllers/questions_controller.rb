class QuestionsController < ApplicationController
  def new
    @question = params[:question]
  end

  def create
    @question = params.require(:question).strip
    if @question.blank?
      flash.now[:alert] = "Введите вопрос."
      render :new, status: :unprocessable_entity
      return
    end

    @result = Rag::AnswerQuestion.new(@question).call
    render :new
  rescue Ai::OpenaiClient::Error => error
    flash.now[:alert] = error.message
    render :new, status: :service_unavailable
  end
end
