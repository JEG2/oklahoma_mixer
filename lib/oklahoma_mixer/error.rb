module OklahomaMixer
  module Error
    class TransactionError < RuntimeError; end
    class CabinetError     < RuntimeError; end
    class QueryError       < RuntimeError; end
    class IndexError       < RuntimeError; end
  end
end
