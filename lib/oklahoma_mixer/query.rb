require "oklahoma_mixer/error"
require "oklahoma_mixer/query/c"

module OklahomaMixer
  class Query  # :nodoc:
    def initialize(table_pointer)
      @pointer = C.new(table_pointer)
    end
    
    attr_reader :pointer
    
    def condition(column, operator, expression, no_index = false)
      operator =  operator.to_s
      negate   =  operator.sub!(/\A(?:!_?|not_)/, "")
      operator =  case operator
                  when /\A(?:=?=|eq(?:ua)?ls?\??)\z/
                    if expression.is_a? Numeric               then :TDBQCNUMEQ
                    else                                           :TDBQCSTREQ
                    end
                  when /\Astr(?:ing)?_eq(?:ua)?ls?\??\z/      then :TDBQCSTREQ
                  when /\Ainclude?s?\??\z/                    then :TDBQCSTRINC
                  when /\Astarts?_with\??\z/                  then :TDBQCSTRBW
                  when /\Aends?_with\??\z/                    then :TDBQCSTREW
                  when /\Aincludes?_all(?:_tokens?)?\??\z/    then :TDBQCSTRAND
                  when /\Aincludes?_any(?:_tokens?)?\??\z/    then :TDBQCSTROR
                  when /\Aeq(?:ua)?ls?_any(?:_tokens?)?\??\z/ then :TDBQCSTROREQ
                  when /\A(?:~|=~|match(?:es)?\??)\z/         then :TDBQCSTRRX
                  when /\Anum(?:ber)?_eq(?:ua)?ls?\??\z/      then :TDBQCNUMEQ
                  when ">"                                    then :TDBQCNUMGT
                  when ">="                                   then :TDBQCNUMGE
                  when "<"                                    then :TDBQCNUMLT
                  when "<="                                   then :TDBQCNUMLE
                  when /\Abetween\??\z/                       then :TDBQCNUMBT
                  when /\Aany_num(?:ber)?\??\z/               then :TDBQCNUMOREQ
                  when /\Aphrase_search\??\z/                 then :TDBQCFTSPH
                  when /\Aall_tokens?_search\??\z/            then :TDBQCFTSAND
                  when /\Aany_tokens?_search\??\z/            then :TDBQCFTSOR
                  when /\Aexpression_search\??\z/             then :TDBQCFTSEX
                  else
                    fail Error::QueryError, "unknown condition operator"
                  end
      operator =  C::CONDITIONS[operator]
      operator |= C::CONDITIONS[:TDBQCNEGATE] if negate
      operator |= C::CONDITIONS[:TDBQCNOIDX]  if no_index
      C.addcond( @pointer,
                 yield(column),
                 operator,
                 yield( expression.respond_to?(:source) ?
                          expression.source             :
                          expression ) )
    end
    
    def order(column, str_num_asc_desc = nil)
      str_num_asc_desc = case str_num_asc_desc.to_s
                         when /\A(?:STR_)?ASC\z/i, "" then :TDBQOSTRASC
                         when /\A(?:STR_)?DESC\z/i    then :TDBQOSTRDESC
                         when /\ANUM_ASC\z/i          then :TDBQONUMASC
                         when /\ANUM_DESC\z/i         then :TDBQONUMDESC
                         else
                           fail Error::QueryError, "unknown order type"
                         end
      C.setorder(@pointer, yield(column), C::ORDERS[str_num_asc_desc])
    end
    
    def limit(max, offset = nil)
      C.setlimit(@pointer, max.to_i, offset.to_i)
    end
    
    def free
      C.del(@pointer)
    end
  end
end
