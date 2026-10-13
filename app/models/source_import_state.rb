class SourceImportState < ApplicationRecord
  validates :source, presence: true, uniqueness: true
end
