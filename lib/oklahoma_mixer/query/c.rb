module OklahomaMixer
  class Query
    module C  # :nodoc:
      extend OklahomaMixer::Utilities::FFIDSL

      prefix :tctdbqry
      
      CONDITIONS = enum :TDBQCSTREQ,    0,
                        :TDBQCSTRINC,   1,
                        :TDBQCSTRBW,    2,
                        :TDBQCSTREW,    3,
                        :TDBQCSTRAND,   4,
                        :TDBQCSTROR,    5,
                        :TDBQCSTROREQ,  6,
                        :TDBQCSTRRX,    7,
                        :TDBQCNUMEQ,    8,
                        :TDBQCNUMGT,    9,
                        :TDBQCNUMGE,   10,
                        :TDBQCNUMLT,   11,
                        :TDBQCNUMLE,   12,
                        :TDBQCNUMBT,   13,
                        :TDBQCNUMOREQ, 14,
                        :TDBQCFTSPH,   15,
                        :TDBQCFTSAND,  16,
                        :TDBQCFTSOR,   17,
                        :TDBQCFTSEX,   18,
                        :TDBQCNEGATE,  1 << 24,
                        :TDBQCNOIDX,   1 << 25
      ORDERS     = enum :TDBQOSTRASC,  0,
                        :TDBQOSTRDESC, 1,
                        :TDBQONUMASC,  2,
                        :TDBQONUMDESC, 3
      
      
      func :name    => :new,
           :args    => :pointer,
           :returns => :pointer
      func :name    => :del,
           :args    => :pointer
      
      func :name    => :addcond,
           :args    => [:pointer, :string, CONDITIONS, :string]
      func :name    => :setorder,
           :args    => [:pointer, :string, ORDERS]
      func :name    => :setlimit,
           :args    => [:pointer, :int, :int]
    end
  end
end
