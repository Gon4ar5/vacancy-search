class JobChunk < ApplicationRecord
  has_neighbors :embedding

  belongs_to :job

  validates :chunk_index, :content, :content_digest, presence: true
end
