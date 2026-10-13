require "digest"

module Rag
  class Chunker
    MAX_LENGTH = 1_200

    def self.call(job)
      # Keep the title and company with the description so retrieved fragments retain context.
      text = [job.title, job.company_name, job.description].compact_blank.join("\n")
      paragraphs = text.split(/\n{2,}|(?<=[.!?])\s+(?=[A-ZА-ЯЁ])/)

      chunks = []
      current = +""
      paragraphs.each do |paragraph|
        parts = paragraph.scan(/.{1,#{MAX_LENGTH}}/m)
        parts.each do |part|
          if current.length + part.length + 1 > MAX_LENGTH && current.present?
            chunks << current
            current = +""
          end
          current << "\n" if current.present?
          current << part
        end
      end
      chunks << current if current.present?
      chunks
    end

    def self.digest(content)
      # Skip another embedding request when this exact fragment is already indexed.
      Digest::SHA256.hexdigest(content)
    end
  end
end
