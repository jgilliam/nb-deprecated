module Delayed
  class PerformableMethod

    def perform
      Government.current = Government.all.last
      load(object).send(method, *args.map{|a| load(a)})
    rescue ActiveRecord::RecordNotFound
      # We cannot do anything about objects which were deleted in the meantime
      true
    end
    
  end
end