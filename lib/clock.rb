# frozen_string_literal: true

class Clock
  class System
    def now
      Time.now
    end
  end

  class Fake
    def now
      Time.new(2024, 3, 24)
    end
  end
end
