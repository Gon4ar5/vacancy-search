require "uri"

class Job < ApplicationRecord
  has_many :job_chunks, dependent: :delete_all

  after_commit :enqueue_rag_indexing, on: [ :create, :update ], if: :rag_content_changed?

  validates :title, :source, :source_url, presence: true
  validates :source_url, uniqueness: { scope: :source }
  validate :source_url_must_be_http

  private

  def rag_content_changed?
    saved_change_to_title? || saved_change_to_company_name? || saved_change_to_description?
  end

  def enqueue_rag_indexing
    # джоба для разбиения на фрагменты и сохрария вектора в бд
    Rag::IndexVacancyJob.perform_later(id)
  end

  def source_url_must_be_http
    uri = URI.parse(source_url) if source_url.present?
    return if uri&.is_a?(URI::HTTP) && uri.host.present?

    errors.add(:source_url, :invalid)
  rescue URI::InvalidURIError
    errors.add(:source_url, :invalid)
  end
end
