module Hirify
  class ImportVacanciesJob < ApplicationJob
    def perform
      ImportVacancies.call
    end
  end
end
